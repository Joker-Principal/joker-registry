# joker-registry —— 个人 vcpkg registry

给 [vcpkg](https://github.com/microsoft/vcpkg) 用的 Git registry，收我个人项目的端口。

## 里面有什么

| 端口 | 说明 |
|---|---|
| `pylai` | HTTP 服务器框架（standalone asio + C++20 modules） |
| `jk` | Joker's C++ Kit（`import jk;`），`pylai` 的依赖 |
| `asio` | **第三方**，为 `pylai` 钉定到 1.38.2（内置端口停在 1.32.0） |

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

- `packages` **三个都要列**：漏 `jk` 找不到端口；漏 `asio` 会退回内置 1.32，`pylai` 编不过。
- 项目的 `vcpkg.json` 还需要 `builtin-baseline`（版本化模式的要求）。
- `pylai` 的 C++20 modules 由**消费方**自己生成 BMI ⇒ 消费方要 C++23 + Ninja / Ninja Multi-Config。
- Linux 上 clang 与 GCC 都可以 —— **前提是本端口的 `REF` 已包含 S1-R21 的修复**（`asio.cpp` 去掉 `module asio;`、
  三个 TU 补 `<tuple>` / `<typeinfo>`）。更早的 `REF` 在 GCC 上会因“模块附属实体强定义冲突 + 缺头”而编不过。

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
