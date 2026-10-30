#!/usr/bin/env python3
"""把源仓的一个 release 发布到 registry 的 ports/<port>。

流程：解析 tag 到 40 位 sha → 校验 tag 已合入源仓分支 → 按 sha 算 archive 的 sha512 →
改端口的 portfile.cmake / vcpkg.json（dependencies 与 features 从源仓清单同步）→ 提交 → x-add-version →
提交版本库 → rebase 重试推送。

只依赖 python3 标准库和 git；vcpkg 优先用 $VCPKG_INSTALLATION_ROOT，否则临时克隆。
由 .github/workflows/update-port.yml 调用，registry 需事先检出到 --registry-dir。
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path

BOT_NAME = "github-actions[bot]"
BOT_EMAIL = "41898282+github-actions[bot]@users.noreply.github.com"
TIMEOUT_SECONDS = 120


def notice(message: str) -> None:
    print(f"::notice::{message}", flush=True)


def warning(message: str) -> None:
    print(f"::warning::{message}", flush=True)


def fail(message: str) -> None:
    sys.exit(f"::error::{message}")


def run(*args: str, cwd: Path | None = None, capture: bool = False, check: bool = True):
    completed = subprocess.run(
        args,
        cwd=cwd,
        check=False,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )
    if check and completed.returncode != 0:
        detail = (completed.stderr or "").strip()
        fail(f"命令失败（exit {completed.returncode}）: {' '.join(args)}"
             + (f"\n{detail}" if detail else ""))
    return completed


def http_get(url: str, token: str = "", accept: str = "application/vnd.github+json") -> bytes:
    headers = {"Accept": accept, "User-Agent": "joker-registry-update"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS) as response:
            return response.read()
    except urllib.error.HTTPError as exc:
        raise HttpStatusError(url, exc.code) from exc
    except urllib.error.URLError as exc:
        fail(f"GET {url} 失败（{exc.reason}）")
    raise AssertionError("unreachable")


class HttpStatusError(Exception):
    def __init__(self, url: str, code: int) -> None:
        super().__init__(f"GET {url} 失败（HTTP {code}）")
        self.code = code


def resolve_tag(tag: str, source_repo: str) -> tuple[str, str]:
    """返回 (version, sha)；annotated tag 要取 ^{} 解包后的 commit。"""
    if not tag.startswith("v"):
        fail(f"tag '{tag}' 必须以 v 开头")
    if not re.fullmatch(r"[0-9A-Za-z._-]+", tag):
        fail(f"tag '{tag}' 含非法字符")

    refs = run(
        "git", "ls-remote", "--tags", f"https://github.com/{source_repo}.git",
        f"refs/tags/{tag}", f"refs/tags/{tag}^{{}}",
        capture=True,
    ).stdout
    entries = {}
    for line in refs.splitlines():
        fields = line.split()
        if len(fields) == 2:
            entries[fields[1]] = fields[0]

    sha = entries.get(f"refs/tags/{tag}^{{}}") or entries.get(f"refs/tags/{tag}", "")
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        fail(f"tag '{tag}' 解析不出 40 位 commit sha")
    return tag[1:], sha


def guard_on_branch(source_repo: str, sha: str, branch: str, token: str) -> None:
    """tag 的 commit 必须是源仓分支的祖先，避免把没合入的提交发布出去。"""
    api = f"https://api.github.com/repos/{source_repo}"
    if not branch:
        branch = json.loads(http_get(api, token))["default_branch"]
    status = json.loads(http_get(f"{api}/compare/{sha}...{branch}", token))["status"]
    # ahead/identical：tag 的 commit 是 branch 的祖先（GitHub 的 status 描述的是 head 相对 base）
    if status not in ("ahead", "identical"):
        fail(f"{sha} 不在 {branch} 上（compare status={status}），拒绝发布未合入的 tag")


def rewrite_portfile(portfile: Path, sha: str, sha512: str) -> None:
    text = portfile.read_text(encoding="utf-8")
    for suffix, value in (("REF", sha), ("SHA512", sha512)):
        pattern = re.compile(rf'^set\(([A-Z0-9_]+_{suffix}) "[^"]*"\)$', re.M)
        names = pattern.findall(text)
        if len(names) != 1:
            fail(f"{portfile.as_posix()} 中 {suffix} 的 set() 行数为 {len(names)}，应为 1")
        text = pattern.sub(lambda m: f'set({m.group(1)} "{value}")', text)
    portfile.write_text(text, encoding="utf-8")


def ordered_manifest(obj: dict) -> dict:
    """把 version 摆到 name 之后：清单是新拼出来的，键序仍需贴合 vcpkg 的惯例。"""
    ordered = {}
    for key, value in obj.items():
        if key == "version":
            continue
        ordered[key] = value
        if key == "name":
            ordered["version"] = obj["version"]
    ordered.setdefault("version", obj["version"])
    return ordered


def dependency_names(dependencies: list) -> set[str]:
    return {dep if isinstance(dep, str) else dep.get("name", "") for dep in dependencies}


def sync_dependencies(obj: dict, source_manifest: dict | None) -> None:
    """源仓清单的 dependencies 是依赖的唯一事实来源；端口专有的 host 工具（vcpkg-cmake 等）保留。"""
    source_dependencies = (source_manifest or {}).get("dependencies")
    if not source_dependencies:
        return
    source_names = dependency_names(source_dependencies)
    port_dependencies = obj.get("dependencies") or []
    kept = [
        dep for dep in port_dependencies
        if isinstance(dep, dict) and dep.get("host") and dep.get("name") not in source_names
    ]
    kept_names = dependency_names(kept)
    port_names = dependency_names(port_dependencies)
    for name in sorted(port_names - source_names - kept_names):
        print(f"drop dependency: {name}")
    for name in sorted(source_names - port_names):
        print(f"add dependency: {name}")
    for name in sorted(kept_names):
        print(f"keep port-only host dependency: {name}")
    obj["dependencies"] = list(source_dependencies) + kept


def rewrite_manifest(manifest: Path, version: str, source_manifest: dict | None) -> None:
    obj = json.loads(manifest.read_text(encoding="utf-8"))

    # 版本号唯一来源是 tag：端口清单里可能压根没有 version 字段，直接补上；
    # 别的版本方案（version-semver 等）语义不同，脚本不替用户决定，直接拒绝
    for scheme in ("version-semver", "version-date", "version-string"):
        if scheme in obj:
            fail(f"{manifest.as_posix()} 用的是 {scheme}，本脚本只写 version")
    previous = obj.get("version")
    if previous != version:
        print(f"set version: {previous or '<missing>'} -> {version}")
    obj["version"] = version
    # 发布新版本时 port-version 归零，而 vcpkg 的惯例是省略 0
    obj.pop("port-version", None)

    sync_dependencies(obj, source_manifest)

    # 源仓 vcpkg.json 的 features 是「这个包支持哪些特性」的唯一事实来源：
    # 同名 feature 以源仓为准覆盖，端口专有 feature（如 cxx23）保留。
    source_features = (source_manifest or {}).get("features") or {}
    if source_features:
        features = obj.setdefault("features", {})
        for name, spec in source_features.items():
            if features.get(name) != spec:
                print(f"sync feature: {name}")
                features[name] = spec

    manifest.write_text(
        json.dumps(ordered_manifest(obj), indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def find_released(repo: Path, port: str, version: str) -> str:
    """返回同 version+port-version 已发布版本的 git-tree；没发布过返回空串。"""
    version_file = next(iter(sorted(repo.glob(f"versions/*/{port}.json"))), None)
    if version_file is None:
        return ""
    for entry in json.loads(version_file.read_text(encoding="utf-8"))["versions"]:
        if entry.get("version") == version and entry.get("port-version", 0) == 0:
            return entry.get("git-tree", "")
    return ""


def has_staged(repo: Path, pathspec: str) -> bool:
    return run("git", "diff", "--cached", "--quiet", "--", pathspec,
               cwd=repo, check=False).returncode != 0


def commit(repo: Path, message: str) -> None:
    run("git", "-c", f"user.name={BOT_NAME}", "-c", f"user.email={BOT_EMAIL}",
        "commit", "-m", message, cwd=repo)


def locate_vcpkg() -> Path:
    root = os.environ.get("VCPKG_INSTALLATION_ROOT", "")
    if root:
        for name in ("vcpkg", "vcpkg.exe"):
            candidate = Path(root) / name
            if candidate.is_file():
                return candidate
    found = shutil.which("vcpkg")
    if found:
        return Path(found)

    work = Path(os.environ.get("RUNNER_TEMP") or tempfile.mkdtemp())
    vcpkg = work / "vcpkg"
    notice("未找到 vcpkg，临时克隆一份")
    run("git", "clone", "--depth", "1", "https://github.com/microsoft/vcpkg.git", str(vcpkg))
    run(str(vcpkg / "bootstrap-vcpkg.sh"), "-disableMetrics")
    return vcpkg


def format_manifest(repo: Path, vcpkg: Path, port: str) -> None:
    # 端口清单是脚本拼出来的，先按 vcpkg 规范排版，否则 x-add-version 会拒绝
    run(str(vcpkg), "format-manifest", f"ports/{port}/vcpkg.json", cwd=repo)


def add_version(repo: Path, vcpkg: Path, port: str) -> None:
    run(str(vcpkg), "x-add-version",
        "--x-builtin-ports-root=./ports",
        "--x-builtin-registry-versions-dir=./versions",
        port, cwd=repo)


def push(repo: Path, branch: str, port: str, version: str) -> None:
    # 多个源仓的 concurrency 组不共享，可能同时写 registry：push 失败就 rebase 重试
    for attempt in range(1, 6):
        run("git", "pull", "--rebase", "origin", branch, cwd=repo)
        if run("git", "push", "origin", f"HEAD:{branch}", cwd=repo, check=False).returncode == 0:
            notice(f"已推送 {branch}（{port} {version}）")
            return
        warning(f"第 {attempt} 次 push 失败，重试")
    fail("连续 push 失败")


def main() -> int:
    parser = argparse.ArgumentParser(description="发布源仓 release 到 registry 端口")
    parser.add_argument("--port", required=True, help="端口名，对应 <registry-dir>/ports/<port>")
    parser.add_argument("--tag", default="", help="要发布的 tag；留空时用 --ref-name")
    parser.add_argument("--ref-name", default="", help="触发事件的 ref（push tag 场景）")
    parser.add_argument("--source-repo", required=True, help="源仓，owner/repo")
    parser.add_argument("--source-branch", default="", help="源仓分支；留空则查 default_branch")
    parser.add_argument("--registry-dir", default="registry", help="已检出的 registry 目录")
    parser.add_argument("--registry-branch", default="master", help="registry 目标分支")
    args = parser.parse_args()

    token = os.environ.get("SOURCE_TOKEN", "")
    repo = Path(args.registry_dir).resolve()

    tag = args.tag or args.ref_name
    version, sha = resolve_tag(tag, args.source_repo)
    notice(f"release: {tag} -> {sha}")
    guard_on_branch(args.source_repo, sha, args.source_branch, token)

    archive = http_get(f"https://github.com/{args.source_repo}/archive/{sha}.tar.gz", accept="*/*")
    sha512 = hashlib.sha512(archive).hexdigest()

    # 源仓没有 vcpkg.json 就只跳过 features 同步（raw 端点对 public 仓库不需要 token）
    source_manifest = None
    try:
        source_manifest = json.loads(
            http_get(f"https://raw.githubusercontent.com/{args.source_repo}/{sha}/vcpkg.json", token)
        )
    except HttpStatusError as exc:
        if exc.code != 404:
            fail(str(exc))
        notice(f"源仓在 {sha} 上没有 vcpkg.json，端口清单不同步 features")

    source_version = (source_manifest or {}).get("version")
    if source_version and source_version != version:
        warning(f"源仓 vcpkg.json 的 version 是 {source_version}，端口清单以 tag 的 {version} 为准")

    # 同 version+port-version 已发布过：内容一致就跳过；不一致说明 tag 被移动过
    tree = run("git", "rev-parse", f"HEAD:ports/{args.port}",
               cwd=repo, capture=True, check=False).stdout.strip()
    released = find_released(repo, args.port, version)
    if released:
        if released != tree:
            fail(f"{args.port} {version} 已发布（git-tree {released}），HEAD 端口内容是 {tree}；"
                 "tag 被移动过，拒绝覆盖")
        notice(f"{args.port} {version} 已发布且内容一致，跳过")
        return 0

    port_dir = repo / "ports" / args.port
    rewrite_portfile(port_dir / "portfile.cmake", sha, sha512)
    rewrite_manifest(port_dir / "vcpkg.json", version, source_manifest)

    vcpkg = locate_vcpkg()
    format_manifest(repo, vcpkg, args.port)

    run("git", "add", "-A", "--", f"ports/{args.port}", cwd=repo)
    if not has_staged(repo, f"ports/{args.port}"):
        notice(f"ports/{args.port} 无改动")
        return 0
    commit(repo, f"ports: {args.port} {version}")

    add_version(repo, vcpkg, args.port)
    run("git", "add", "-A", "--", "versions", cwd=repo)
    if has_staged(repo, "versions"):
        commit(repo, f"versions: {args.port} {version}")

    push(repo, args.registry_branch, args.port, version)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except HttpStatusError as exc:
        fail(str(exc))
