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
