# joker-registry —— 个人 vcpkg registry

给 [vcpkg](https://github.com/microsoft/vcpkg) 用的 Git registry，收我个人项目的端口。

## 里面有什么

| 端口    | 说明                                               |
| ---     | ---                                                |
| `pylai` | HTTP 服务器框架（standalone asio + C++20 modules） |
| `jk`    | Joker's C++ Kit（`import jk;`），`pylai` 的依赖    |
| `asio`  | 最新版的 asio                                      |

## 消费方怎么用

在项目清单旁放一份 `vcpkg-configuration.json`：

```json
{
  "registries": [
    {
      "kind": "git",
      "repository": "https://github.com/Joker-Principal/joker-registry",
      "baseline": "<本仓库某个 commit>",
      "packages": [ "pylai", "jk", "asio" ]
    }
  ]
}
```

## 维护（加/更新端口）

```bash
# 1. 改端口（新版本要先把 vcpkg.json 的 version / port-version 提上去）
vcpkg format-manifest ports/<name>/vcpkg.json

# 2. 先提交 ports（版本文件里的 git-tree 必须对应仓库里真实存在的 tree）
git add ports && git commit -m "ports: <name> <version>"

# 3. 生成/更新版本库与 baseline
vcpkg x-add-version --x-builtin-ports-root=./ports --x-builtin-registry-versions-dir=./versions <name>

# 4. 提交版本库并推送
git add versions && git commit -m "versions: <name> <version>" && git push
```

⚠️ **已发布的版本不许改写** `git-tree`：内容改了就把 `port-version` 加一，重新走一遍。

## 源仓接自动发布

逻辑只在 `.github/workflows/update-port.yml`（`on: workflow_call`）里。新项目接入三步：

1. 端口里的 pin 写成两行变量（CI 只替换这两行，不做跨行正则）：

   ```cmake
   set(SOMEPORT_REF "<40 位 commit sha>")
   set(SOMEPORT_SHA512 "<archive 的 sha512>")
   ```

   `vcpkg_from_github` 里用 `REF "${SOMEPORT_REF}"` / `SHA512 "${SOMEPORT_SHA512}"`。
2. 在源仓 Settings → Secrets 配 `JOKER_REGISTRY_AUTO_UPDATE`（对 `joker-registry` 有 Contents: Read and write 的 fine-grained PAT）。
3. 复制 `templates/registry-update.yml` 到源仓 `.github/workflows/registry-update.yml`，把 `<port>` 替换成端口名。

之后推 `v*` tag 即自动发布。判 `v*` 的 workflow 文件必须在被 tag 的 commit 里；否则用 `workflow_dispatch` 补发一次。

CI 做的事：解析 tag 到 40 位 sha → 校验 tag 在源仓默认分支上、且该版本没以不同内容发布过 → 按 sha 下载 archive 算 SHA512 → 改 `ports/<port>` → 提交 ports → `x-add-version` → 提交 versions → rebase 后 push。

- CI 不构建端口，能否编过要本地先确认。
- 多个源仓同时发布会在 registry 上撞写，靠 `pull --rebase` + 5 次重试兜底，真冲突会失败。

