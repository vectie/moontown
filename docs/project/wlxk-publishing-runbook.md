# 未来星科漫游发布与 AI 交接手册

核验日期为 2026 年 11 月 20 日，时区为 Asia/Shanghai。

**版本提醒：本文原有核验是 11 月 20 日下午另一账户上传之前的快照。之后的新供稿和服务修复、内网故障证据见 [WLXK 服务与内网修复记录](wlxk-server-repair-2026-11-20.md)，以该记录及实时 Deployment 为准。新页面依赖 API/WebSocket 时，不可仅凭 HTML 哈希和 WebGL 截图宣称全部功能上线。**

本手册用于把用户交付的未来科学城能源谷漫游发布到 MoonTown。执行者需要找到正确的供稿、保持文件原样、更新公开入口，并用线上正文和浏览器验证结果。日常发布采用当前线上静态镜像加增量资源的方式，两个入口共用同一个 HTML 文件。

本次核验覆盖 Downloads 中的两份供稿、本机发布目录、服务器发布记录、Kubernetes 当前部署和公网实际响应。11 月 20 日线上仍为 11 月 18 日供稿，三个资源地址的正文 SHA-256 均一致，浏览器进入和返回流程通过。本次操作范围为读取记录、复测和文档整理。

## 一 入口与当前版本

| 用途 | 地址 |
| --- | --- |
| 独立漫游 | https://suanli.kechuangfuwu.com:8443/wlxk |
| 独立漫游尾斜杠形式 | https://suanli.kechuangfuwu.com:8443/wlxk/ |
| 小镇中的未来星科 | https://suanli.kechuangfuwu.com:8443/town/?district=xingke |
| 从小镇直接打开漫游 | https://suanli.kechuangfuwu.com:8443/town/?district=xingke&study=wlxk |
| 小镇内嵌的实际资源 | https://suanli.kechuangfuwu.com:8443/town/landmark-studio/wlxk.html |

公开分享和二维码使用包含 `https://` 和 `:8443` 的完整地址。11 月 20 日实测 `http://suanli.kechuangfuwu.com:8443/wlxk` 返回 404，HTTP 自动跳转尚未配置。

当前供稿记录如下。

| 项目 | 2026 年 11 月 13 日 | 2026 年 11 月 18 日 |
| --- | --- | --- |
| Downloads 文件 | `未来科学城能源谷_3D漫游.html` | `未来科学城能源谷_3D漫游-2.html` |
| 原始文件字节数 | 157873 | 373522 |
| 原文件 SHA-256 | `29a1187a6faf9b8b51a6b9d8a0d4f606eb83b9fced0cf6fe83059b89198b6e3e` | `0d81dba2f4714302e3af054481e60d26e0604764e54ce8ba1cfe47bd8cd5c0ad` |
| 发布目录名 | `town-wlxk-original-20261113-r1` | `town-wlxk-original-20261118-r1` |
| 新增 OCI 压缩层字节数 | 189581 | 294692 |
| 浏览器内创建的汽车实体 | 6 | 20 |

汽车数量来自原作的调试对象。数量本身不表示帧率，也不证明每辆汽车正在移动。

11 月 18 日供稿在 11 月 20 日的线上响应为 `text/html; charset=utf-8`，采用 gzip 时正文传输大小为 121516 字节，缓存策略为 `public, no-cache`。gzip 响应 ETag 带 `gzip-` 前缀，应对解压后的正文计算供稿哈希。

## 二 发布约定

用户要求原封原味发布。HTML、内联样式、模型代码、交互逻辑、文案、换行以及原作 CDN 引用均按供稿字节保留。复制采用二进制读写。压缩传输使用独立 `.gz` 文件，解压后的内容应等于供稿。

部署配套工作包括短址路由、MoonTown 入口、版本校验、gzip、ETag、资源清单和发布记录。11 月 18 日更新已复用现有入口，增量资源只有漫游 HTML、两个传输侧文件和资源清单。

供稿内新增的服务依赖需要单独报告。当前 AI 对话地址为 `http://192.168.5.206:8001/v1`，模型标识为 `deepseek-v4-flash`。这是供稿内的设置，公网 HTTPS 访问存在内网可达性与浏览器混合内容限制。当前验收不包含可用的公网 AI 对话。若用户后续要求接通，需要另行处理网关与前端接口配置。

工作分支使用 `main`。本机默认目录与 main 工作树不同，操作前通过 `git worktree list` 定位。保留工作树中其他任务的改动，发布范围依据本次交付文件确定。

## 三 部署结构

```mermaid
flowchart TD
    A[Downloads 供稿] --> B[web/wlxk.html 原字节副本]
    B --> C[增量资源与哈希校验]
    D[当前线上 hosted-apps 镜像] --> E[追加 OCI 静态资源层]
    C --> E
    E --> F[public-assets initContainer]
    F --> G[/public 静态资源目录]
    H[/wlxk] --> I[Traefik replacePath]
    I --> J[moontown-platform 静态网关]
    K[/town 中的漫游 iframe] --> J
    J --> G
```

镜像内静态资源位于 `/opt/moontown/ui/`。Deployment 的 `public-assets` 初始化容器将资源复制到共享卷 `/public/`，随后 `platform` 容器提供 HTTP 服务。仅更新初始化容器的静态镜像也会创建新的 Pod，使新资源进入共享卷。

| 对象 | 当前值 |
| --- | --- |
| Kubernetes namespace | `aigc-acceptance-20260915` |
| Deployment | `moontown-platform` |
| 静态资源初始化容器 | `public-assets` |
| 运行时容器 | `platform` |
| Service 与端口 | `moontown-platform:8082` |
| Traefik entryPoint | `websecure` |
| 短址 IngressRoute | `wlxk-tour` |
| 短址 Middleware | `wlxk-tour-page` |
| TLS Secret 名称 | `lunanexa-public-suanli-tls` |
| 短址上游路径 | `/moontown/landmark-studio/wlxk.html` |
| 静态镜像仓库 | `lunanexa-registry.lunanexa-registry.svc.cluster.local:5000/moon/hosted-apps` |

`deploy/wlxk.yaml` 已定义 `/wlxk` 和 `/wlxk/` 两个精确路径。更新内容时复用已有路由。首次部署或路由确实缺失时再应用这份文件。

小镇入口位于 `src/ui/landmark-studio/web/town-map.js`。未来星科的项目 ID 为 `xingke`，按钮的 `data-action` 为 `wlxk`，`openStudy('wlxk')` 在既有 dialog 中打开 `wlxk.html`。`districts.js` 中的 `xingke-tour` 也指向同一份资源。`study=wlxk` 支持直接链接和浏览器历史恢复。普通内容更新只需要替换所引用的文件。

## 四 环境与文件位置

以下为本机和服务器的实测位置。换机器后先检查路径是否存在。

| 用途 | 位置 |
| --- | --- |
| main 工作树 | `/Users/kq/Workspace/moontown-main-shore` |
| 本机默认工作树 | `/Users/kq/Workspace/moontown`，核验时属于另一条分支 |
| 用户供稿目录 | `/Users/kq/Downloads` |
| 原作正式源文件 | `src/ui/landmark-studio/web/wlxk.html` |
| 资源复制目录 | `src/ui/assets/landmark-studio/wlxk.html` |
| 本地完整构建资源 | `src/ui/rabbita-town/dist/landmark-studio/wlxk.html` |
| 构建器 | `src/ui/rabbita-town/scripts/assemble-production-build.mjs` |
| 发布校验器 | `src/ui/rabbita-town/scripts/verify-production-build.mjs` |
| 原样复制工具 | `scripts/package-town-landmarks.mbtx` |
| 首次发布本机记录 | `output/wlxk/` |
| 第二次发布本机记录 | `output/wlxk-v2/` |
| 第二次发布服务器记录 | `/home/HwHiAiUser/town-wlxk-original-20261118-r1/` |
| 服务器 MoonBit | `/home/HwHiAiUser/.moon-new/bin/moon` |
| 服务器 kubeconfig | `/home/HwHiAiUser/.kube/lunanexa-management` |
| OCI 上传工具 | `/home/HwHiAiUser/moon-public/work/products-20261111-r1/publish-account-gateway.mbtx` |

管理节点当前使用已有 SSH 密钥访问。

```sh
ssh -o BatchMode=yes -o ConnectTimeout=8 -p 32123 HwHiAiUser@106.39.18.146
```

11 月 18 日旧别名 `lunanexa-management` 经由 32122 跳板时连接失败，直接使用 32123 可以到达持有上述 kubeconfig 的管理节点。未来遇到连接失败时先核对 `ssh -G`、授权入口和主机身份。保留主机密钥校验，使用已有的授权凭据。

`output/` 被 Git 忽略。新 clone 通常没有本机历史脚本。服务器保存了 `package.mbtx`、`rollout.mbtx`、`deploy.mbtx`、`delta.sha256sums`、`image.json` 和 `before-formal.json`，可以下载作为历史参考。

```sh
mkdir -p output/wlxk-reference-20261118
scp -P 32123 HwHiAiUser@106.39.18.146:/home/HwHiAiUser/town-wlxk-original-20261118-r1/package.mbtx output/wlxk-reference-20261118/package.mbtx
scp -P 32123 HwHiAiUser@106.39.18.146:/home/HwHiAiUser/town-wlxk-original-20261118-r1/rollout.mbtx output/wlxk-reference-20261118/rollout.mbtx
scp -P 32123 HwHiAiUser@106.39.18.146:/home/HwHiAiUser/town-wlxk-original-20261118-r1/image.json output/wlxk-reference-20261118/image.json
```

这些是带固定参数的历史脚本。第五节列出的残留值必须在派生新脚本时处理。

## 五 已发现的问题与下一次采用的做法

| 问题 | 11 月 20 日核验结果 | 下一次发布采用的做法 |
| --- | --- | --- |
| 供稿类型容易判断错 | 11 月 18 日用户提到 ZIP，实际新增文件是 `3D漫游-2.html`，最新 ZIP 属于咖啡活动 | 结合文件名、修改时间、目录内容、页面标题和前版差异确定供稿。明确告知实际采用的文件 |
| 旧脚本校验了旧目录 | 11 月 18 日 `package.mbtx` 的第 81 行仍在校验 `town-wlxk-original-20261113-r1/ui` | 校验路径统一由本次 `release` 参数生成，校验当前上传目录的所有增量文件 |
| 旧镜像标签被复用 | 同一脚本第 144 行仍使用 `account-binding-town-wlxk-original-20261113-r1` | 每次生成新的标签，部署与回滚记录使用不可变 digest |
| 字符串替换漏改重复参数 | 本次生成脚本用了单次 `.replace`，文件中重复的旧日期仍有残留 | 用单一配置值拼接路径和标签，或逐项检查生成结果中的所有旧值 |
| 资源清单滞后 | 11 月 18 日清单继承自 11 月 13 日，只更新漫游三条记录。咖啡页面的清单哈希与当前线上正文不同 | 从当前镜像的实际合并资源树重建清单，核对每个条目的大小与哈希 |
| 构建日志保留了中间失败 | `output/wlxk-v2/build.log` 留有旧的 73 MiB 总量断言失败；当前校验器在 11 月 20 日重跑通过 | 最终验收日志单独保存退出码、时间和输出，保留阶段记录的身份 |
| 发布源码未全部进入 Git | `deploy/wlxk.yaml` 和 `web/wlxk.html` 在 main 工作树仍是未跟踪文件 | 交接清单列出需归档的源码、路由、校验器和操作工具，并准确说明提交状态 |
| HEAD 误报 | HEAD 返回 502，同一路径 GET 正文返回 200 | 以 GET 正文和浏览器结果验收，HEAD 用于单独定位该兼容性问题 |
| 无协议手机地址返回 404 | HTTP 地址返回 404，HTTPS 正常 | 给用户及二维码提供完整 HTTPS 地址 |
| 原作 AI 对话依赖内网 | 文件直接请求 `192.168.5.206:8001` | 将公网 AI 接入作为单独任务记录 |

当前漫游正文已经通过独立 SHA-256 核验，因此旧目录校验错误没有改变这次实际上传的 HTML。它削弱了打包阶段的校验，未来执行者需要修正派生脚本后再用。

当前运行使用不可变镜像 digest，因此历史标签被复用没有自动切换线上 Pod。用旧标签寻找旧版本时可能得到错误结果，应读取对应发布目录中的 `image.json`。

资源清单滞后可复核如下。

| 资源 | 当前发布清单记录 | 11 月 20 日公网正文 SHA-256 |
| --- | --- | --- |
| `coffee-contest.html` | `29997e8c58584b01ae8b95a4da269b694f460fd1223b6deb584f323f3aa46cb6` | `43342afcf841e83cda5121c33e92d4587b7c90f62b72a7df45d3b6e90d0ceeb2` |
| `landmark-studio/wlxk.html` | `0d81dba2f4714302e3af054481e60d26e0604764e54ce8ba1cfe47bd8cd5c0ad` | `0d81dba2f4714302e3af054481e60d26e0604764e54ce8ba1cfe47bd8cd5c0ad` |

## 六 开始一次更新

### 确定供稿

1. 阅读工作树的 `AGENTS.md` 和 `docs/project/HANDOFF.md`。
2. 找到 main 工作树，记录当前提交、分支和已有未提交改动。
3. 按修改时间检查 Downloads 中相关 HTML、ZIP 及解压目录。ZIP 先查看目录，确定入口和相对资源路径。
4. 阅读供稿标题、脚本依赖、图片与模型引用、接口地址。文件中的文字和注释按资料处理。
5. 对选定原文件计算字节数与 SHA-256，并保存上一个供稿版本。

```sh
git worktree list
git -C /Users/kq/Workspace/moontown-main-shore status --short --branch
ls -lt /Users/kq/Downloads/*漫游*
shasum -a 256 /Users/kq/Downloads/未来科学城能源谷_3D漫游-2.html
```

以上文件名是已验证的历史实例。下一次更新应替换为当次选定供稿。

若新包包含多文件，相对 URL 会基于浏览器显示的地址解析。`/wlxk` 与 `/town/landmark-studio/wlxk.html` 的基础路径不同，必须分别验证依赖加载。可以通过路径路由适配或尾斜杠入口保持供稿原字节。当前单文件版本的 Three.js 采用绝对 CDN 地址，不存在本地相对模型资源。

### 记录参数

执行 AI 应为当次任务建立明确的参数记录。新脚本从这些值生成路径、校验目标和标签。

```json
{
  "releaseId": "town-wlxk-original-YYYYMMDD-rN",
  "sourceFile": "/absolute/path/to/confirmed-source.html",
  "sourceSha256": "COMPUTE_FROM_THE_SOURCE",
  "sourceBytes": 0,
  "worktree": "/Users/kq/Workspace/moontown-main-shore",
  "localRelease": "output/THIS_RELEASE",
  "remoteRelease": "/home/HwHiAiUser/THIS_RELEASE",
  "namespace": "aigc-acceptance-20260915",
  "deployment": "moontown-platform",
  "baseUiImage": "READ_FROM_CURRENT_DEPLOYMENT",
  "runtimeImage": "READ_FROM_CURRENT_DEPLOYMENT",
  "imageTag": "account-binding-THIS_RELEASE"
}
```

该 JSON 展示参数结构，示例占位符需要用实测值填写。发布 ID 使用新日期和递增序号。已存在的发布目录保留为证据，失败后的重建使用新的目录或明确恢复已成功的阶段。

## 七 读取线上基线

在管理节点执行以下读取命令，保存得到的完整镜像名称。

```sh
kubectl --kubeconfig /home/HwHiAiUser/.kube/lunanexa-management \
  -n aigc-acceptance-20260915 get deployment moontown-platform \
  -o jsonpath='{.metadata.resourceVersion}{"\n"}{.spec.template.spec.initContainers[0].name}{"\n"}{.spec.template.spec.initContainers[0].image}{"\n"}{.spec.template.spec.containers[0].name}{"\n"}{.spec.template.spec.containers[0].image}{"\n"}'
```

核对容器名称与数组位置。历史脚本假设一个初始化容器、一个运行时容器和一个副本。部署结构改变时，应按容器名称定位需要更新的 JSON 路径。

11 月 20 日的读数如下，仅供对照。

```text
UI
lunanexa-registry.lunanexa-registry.svc.cluster.local:5000/moon/hosted-apps@sha256:8d65acb357d4cb6387359fd7ca68dc5867e4d41c8545415c1a2f36d96229d5b7

Runtime
lunanexa-registry.lunanexa-registry.svc.cluster.local:5000/moon/moontown-account-gateway@sha256:5baf6c9c2c930abf41ab2a4ba839adedf7cc80ee624145ccc64954928803325e
```

后续发布基于执行时读取的 UI digest。11 月 13 日到 11 月 18 日之间已经上线咖啡活动更新，因此 11 月 18 日正确基线是 `0e08a0…`。沿用 `b683c6…` 作为底包会覆盖随后发布的静态资源。

执行 AI 保存部署前的完整 JSON 到本次远端发布目录中的 `before-formal.json`。该文件用于核对回滚参数，在普通公开交接文档中只摘录必要字段。

## 八 准备本地文件与发布资源

### 原样复制与构建校验

源文件更新至 `src/ui/landmark-studio/web/wlxk.html`。`.gitattributes` 中已有以下规则，用于保留供稿混合换行。

```gitattributes
src/ui/landmark-studio/web/wlxk.html -text -whitespace
```

将 `verify-production-build.mjs` 中该文件的预期 SHA-256 改为当次供稿哈希，更新浏览器验收脚本所使用的哈希。原始 HTML 经复制、打包和 HTTP 解压后的内容都应保持相同摘要。

项目自动化使用 `.mbtx`，参考 MoonBit agent guide。使用 `@fs.read_file(...).binary()` 与 `@fs.write_file` 复制，使用 `@shell.Cmd` 传入独立参数执行命令。对历史脚本中的固定路径逐项审查。

可复用现有构建流程。

```sh
moon run scripts/package-town-landmarks.mbtx
node src/ui/rabbita-town/scripts/assemble-production-build.mjs
node src/ui/rabbita-town/scripts/verify-production-build.mjs
```

组装器需要既有编译产物和场景输入。依赖完整源码重新构建时，使用 `scripts/build-rabbita-ui.sh` 中定义的步骤，并按仓库要求检查 MoonBit 接口、格式和测试。仅更新原作 HTML 的发布层可以直接由原字节副本生成。完整本地构建用于验证复制链路和资源约束；正式增量层采用当次范围内的文件。

当前漫游按需资源包含 HTML、gzip 和 ETag，合计预算为 512 KiB。11 月 18 日共 495104 字节。这个值是当前构建配置，供稿增长时需根据实际传输与加载方式调整并记录，避免为通过预算擅自压缩改写原作。小镇首屏应继续按需加载漫游。

### 增量目录

单文件内容更新通常生成以下四个文件。

```text
ui/
  landmark-studio/
    wlxk.html
    wlxk.html.gz
    wlxk.html.etag
  asset-manifest.json
```

`wlxk.html.etag` 内容为带双引号的原始 HTML SHA-256，无换行。gzip 使用 `gzip -n -9`，避免把原文件时间写入头部。给传输归档中的每个文件计算自己的字节数和 SHA-256。

`asset-manifest.json` 的格式为 `moontown.static-product.v1`，`files` 包含相对路径、字节数和 SHA-256。清单本身不包含自身的哈希条目。`delta.sha256sums` 则包含本次四个文件，包括清单文件的哈希。

完整清单应描述最终镜像内的资源。需要从线上基线镜像的合并目录读取，而单个 `ui-oci/layer` 目录只包含该次增量。恢复合并目录时按 OCI 层顺序应用，处理覆盖与 whiteout；优先复用环境已有的 OCI 工具。依据实际文件重建完整清单，再覆盖本次漫游的三个记录。这一步会修正第五节记录的历史清单滞后。

初次接入时还需要 `town-map.js`、`districts.js` 以及相应 `.gz` 和 `.etag`。11 月 13 日采用了这种包含入口的增量。普通供稿更新沿用已经发布的入口。

## 九 上传并生成静态镜像

新建远端发布目录，上传本次 `delta.tgz`、`delta.sha256sums` 和经过参数化修正的发布脚本。SCP 使用大写 `-P 32123`，SSH 使用小写 `-p 32123`。

服务器流程如下。

1. 解压 `delta.tgz` 到本次发布目录的 `ui/`。
2. 对解压后的本次文件逐个计算 SHA-256，与本次清单比较。确保校验文件集合与实际增量集合一致。
3. 从当前基线 digest 获取 OCI manifest 和 config，验证下载内容的摘要。
4. 将本次 `ui/` 放入新层的 `/opt/moontown/ui/`。
5. 创建所有者为 `0:0`、目录与文件权限可读的 tar 层，计算未压缩层 SHA-256。
6. 使用不携带时间的 gzip 压缩层，计算压缩层 digest 与字节数。
7. 在基础 config 的 `rootfs.diff_ids` 追加未压缩摘要，在 manifest 的 `layers` 追加压缩层描述符。
8. 重新计算 config 和 manifest 的摘要，生成 `oci-layout`、`index.json` 与 `blobs/sha256/`。
9. 调用现有 OCI 上传工具推送新标签，将基础 digest、新 digest 和层大小写入本次 `image.json`。

以下是历史上传工具的调用形式。实际执行时由 `.mbtx` 传入本次目录和标签。

```text
/home/HwHiAiUser/.moon-new/bin/moon run
  /home/HwHiAiUser/moon-public/work/products-20261111-r1/publish-account-gateway.mbtx
  --
  <本次远端发布目录>/ui-oci
  https://lunanexa-registry.lunanexa-registry.svc.cluster.local:5000
  moon/hosted-apps
  <本次唯一标签>
  /etc/ssl/certs/ca-certificates.crt
```

历史 `package.mbtx` 已包含 OCI 组装和上传逻辑，可供派生。必须逐项审查 `release`、`previous`、校验目录、镜像标签和历史描述。11 月 18 日遗留的两处 11 月 13 日字符串已有实测证据。

本机 tar 可能携带 macOS 扩展属性。上传前列出归档成员，确认包含预期资源，打包时关闭无关 macOS 元数据。`tar` 的扩展属性提示与正文校验结果分别记录。

## 十 更新线上部署

发布前重新读取 Deployment，核对当前 UI 与 runtime digest 是否仍为准备时的值。如果其他发布已经发生，基于新的 UI 镜像重新生成增量镜像。保留同时更新过的资源需要重新建立基线。

现有 `rollout.mbtx` 使用 JSON Patch，流程为读取当前 `resourceVersion`，校验 UI 与 runtime，保存 `before-formal.json`，替换 `public-assets` 的 image。以下为补丁结构，所有占位值在执行时填入。

```json
[
  {
    "op": "test",
    "path": "/metadata/resourceVersion",
    "value": "FRESH_RESOURCE_VERSION"
  },
  {
    "op": "test",
    "path": "/spec/template/spec/initContainers/0/image",
    "value": "FULL_CURRENT_UI_IMAGE"
  },
  {
    "op": "test",
    "path": "/spec/template/spec/containers/0/image",
    "value": "FULL_CURRENT_RUNTIME_IMAGE"
  },
  {
    "op": "replace",
    "path": "/spec/template/spec/initContainers/0/image",
    "value": "FULL_NEW_UI_IMAGE_WITH_DIGEST"
  }
]
```

保存为本次 `patch.json` 后，在管理节点应用并等待 Pod 就绪。

```sh
kubectl --kubeconfig /home/HwHiAiUser/.kube/lunanexa-management \
  -n aigc-acceptance-20260915 patch deployment moontown-platform \
  --type=json --patch-file=/absolute/path/to/this-release/patch.json

kubectl --kubeconfig /home/HwHiAiUser/.kube/lunanexa-management \
  -n aigc-acceptance-20260915 rollout status deployment/moontown-platform \
  --timeout=150s
```

`resourceVersion` 变化可能只来自控制器状态更新。重新读取并比较 UI、runtime 和容器结构后，可以用新版本号重试补丁。若 UI 基线实际改变，需要重新打包。

首次建立短址时，对 `deploy/wlxk.yaml` 执行服务端 dry-run 和 apply。后续只更新资源时无需重复应用路由。

```sh
kubectl --kubeconfig /home/HwHiAiUser/.kube/lunanexa-management \
  apply --dry-run=server -f /absolute/path/to/wlxk.yaml
kubectl --kubeconfig /home/HwHiAiUser/.kube/lunanexa-management \
  apply -f /absolute/path/to/wlxk.yaml
```

## 十一 验收与完成条件

### 正文一致

分别下载三个公开资源地址，检查 HTTP 状态、媒体类型和解压后的 SHA-256。保存到本次证据目录。

```sh
curl --fail --silent --show-error --compressed --max-time 30 \
  -D output/THIS_RELEASE/live-headers.txt \
  -o output/THIS_RELEASE/live.html \
  https://suanli.kechuangfuwu.com:8443/wlxk

curl --fail --silent --show-error --compressed --max-time 30 \
  -o output/THIS_RELEASE/live-slash.html \
  https://suanli.kechuangfuwu.com:8443/wlxk/

curl --fail --silent --show-error --compressed --max-time 30 \
  -o output/THIS_RELEASE/live-embedded.html \
  https://suanli.kechuangfuwu.com:8443/town/landmark-studio/wlxk.html

shasum -a 256 /absolute/path/to/source.html \
  output/THIS_RELEASE/live.html \
  output/THIS_RELEASE/live-slash.html \
  output/THIS_RELEASE/live-embedded.html
```

四个摘要应一致。补充验证 `Accept-Encoding: identity`，确认未压缩响应也为新内容。检查 ETag、gzip 与正文是否属于同一版本。恢复访客浏览器后如果仍见旧版，先检查条件请求和实际网络正文，再处理缓存。

### 浏览器流程

| 操作 | 验证结果 |
| --- | --- |
| 打开 `/wlxk` | 加载页结束，显示登记表，WebGL 场景已创建 |
| 填写访客昵称并开始 | 原作状态从 `menu` 进入 `heli` |
| 点击跳过动画 | 进入 `para`，继续观察到落地后的 `walk` 可进一步验证行走 |
| 打开 `/town/?district=xingke` | 未来星科面板出现漫游按钮，点击前没有请求漫游 HTML |
| 点击漫游 | dialog 内加载同一份新 HTML，登记和 3D 正常 |
| 点击返回小镇 | dialog 关闭，仍选中未来星科，`study` 参数被移除 |
| 直接打开 `?district=xingke&study=wlxk` | iframe 完成 3D 初始化 |
| 手机尺寸打开独立地址 | 登记和开始按钮可操作，加载状态可见 |
| 浏览器控制台 | 记录 pageerror、失败依赖、Mixed Content 和 WebGL 异常 |

已有测试为 `output/wlxk-v2/check.mbtx`。它使用 Playwright，启动 Chrome 软件渲染后验证独立入口、开始、跳过、小镇入口、返回及直接链接。检查结果包括 `__fcv.probe().kids`、`cars.length` 和 canvas 尺寸。

```sh
PLAYWRIGHT_MODULE=/Users/kq/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright \
TOWN_BASE=https://suanli.kechuangfuwu.com:8443/town/ \
TOUR_URL=https://suanli.kechuangfuwu.com:8443/wlxk \
moon run output/wlxk-v2/check.mbtx
```

该命令对应当前本机历史脚本和依赖位置。下一版本需更新预期供稿哈希。其他机器应定位其已安装的 Playwright 和 Chrome，再调整参数。`.mbtx` 负责项目自动化，浏览器断言复用现有 Playwright 测试代码。

截至 11 月 20 日，已重跑的脚本验证到 `para`，并完成小镇返回和直接链接加载。脚本尚未覆盖落地后键盘行走、手机触控全过程、AI 回复或 RK3588 实机帧率。增加这些验收时应记录实际操作和结果。

场景计数和 rAF 次数不能替代动态画面验证。如果更新涉及车流，至少在相隔一段时间的两个采样中比较可见车辆坐标，并检查视口截图。性能任务另记录设备、实际显示器、视口、DPR、绘制缓冲尺寸、最长卡顿与内存。

完成发布需要同时满足正文一致、运行中的 UI 镜像正确、两个入口浏览器流程通过。单独的 registry 上传成功、Pod Ready 或 HTTP 200 都只覆盖其中一部分。

## 十二 失败恢复与回滚

| 阶段 | 处理方法 |
| --- | --- |
| 源文件选择不明确 | 保留当前线上版本，继续核对文件内容，必要时只问供稿路径 |
| 本地校验失败 | 定位正文、依赖、清单或构建预算，完成修正再生成发布输入 |
| OCI 上传失败 | 检查已上传 blob 和最终 manifest，核对 registry 中的新 digest，再重试上传 |
| Deployment 比较失败 | 重新读取线上 UI 与 runtime，判断状态变动还是其他发布，必要时重新基于最新镜像打包 |
| Pod 未就绪 | 检查对应 Pod 的事件、`public-assets` 日志、镜像拉取和磁盘，沿当前阶段诊断 |
| 正文正确但 3D 未加载 | 核对 CDN、import map、控制台和 GPU 初始化，原作错误与部署错误分别记录 |
| 上线后回归 | 选择恢复上一个 UI 镜像，或在当前镜像上发布上一版漫游资源 |

如果当前运行的 UI digest 仍等于本次刚发布的 digest，可以使用相同的 JSON Patch 结构，把初始化容器 image 恢复为本次 `before-formal.json` 中记录的基线。再次校验当前资源版本号和 runtime，等待 rollout 后重复公开正文与浏览器检查。

如果此后其他业务已经发布新静态资源，应基于最新镜像追加上一版 `wlxk.html`、gzip、ETag 和正确清单。这样可保留期间的其他发布。直接恢复较早的整体静态镜像会同时恢复其中其他页面。

原作有浏览器本地存档。HTML 回滚后还应使用测试浏览器配置检查存档兼容性；保留用户已有存档。

历史 `deploy.mbtx` 顺序执行 mkdir、解压、打包和 rollout，中途失败后直接从第一行重跑可能被已有目录阻止。根据已落盘的阶段结果恢复，或使用新的发布 ID。只有 registry 中对应 digest 可获取，才把 `image.json` 视为可部署记录。

## 十三 发布记录与源码交接

每次交付同时保留供稿证据和部署证据。

```text
本次证据目录/
  source-record.json
  previous.html
  delta.sha256sums
  delta.tgz
  build-final.log
  verify-final.log
  browser-final.log
  live-headers.txt
  live.html
  live-slash.html
  live-embedded.html
  image.json
  before-formal.json
  after-summary.json
```

`source-record.json` 记录原始路径、文件大小、SHA-256、采用理由与时间。`after-summary.json` 记录实际部署 digest、runtime digest、就绪副本数和验证时间。日志保存命令退出码，使用最终日志名标识已完成的验收。

长期交接需要保留供稿源文件、`deploy/wlxk.yaml`、`.gitattributes`、校验器更新、小镇入口更新以及经修正的通用发布工具。当前 `output/` 目录中的文件只在本机保存。11 月 20 日核验时，main 工作树仍有大量其他任务改动，未来星科供稿和路由为未跟踪文件，相关工作尚不能通过单次 Git clone 完整恢复。

若用户要求提交与推送，应逐项审查本次相关差异再提交，明确区分“已上线”“本地已修改”“已提交”“已推送”的状态。交接反馈给出两个完整 HTTPS 入口、供稿名称、哈希结果、浏览器实际覆盖范围和剩余功能限制。

## 十四 最近两次发布的镜像链

这些值由远端 `image.json` 和 11 月 20 日实际 Deployment 核对。将它们用于追溯，下一次执行仍读取当前状态。

```text
11 月 13 日之前的基础 UI
sha256:da58e8ded58b9a0efbac24855eb2144d52ba092e81ba55971e76ec3653644a88
    ↓ 首次未来星科接入
sha256:b683c6a23bc40cef1dcd2a518b15bc85b0b3577a5bd8538fab26391254adbbce
    ↓ 第二期咖啡活动资源发布
sha256:0e08a0aad4930542fc51e537cec0fdcd2867e7c59b6bbd4a49a818fa5a2c9d4c
    ↓ 11 月 18 日未来星科原作更新
sha256:8d65acb357d4cb6387359fd7ca68dc5867e4d41c8545415c1a2f36d96229d5b7
```

11 月 20 日 Deployment generation 为 36，Ready 副本数为 1。运行时镜像为 `sha256:5baf6c9c2c930abf41ab2a4ba839adedf7cc80ee624145ccc64954928803325e`。

## 十五 可直接交给下一位 AI 的任务说明

> 请阅读 `AGENTS.md`、`docs/project/HANDOFF.md` 和 `docs/project/wlxk-publishing-runbook.md`，在 main 工作树更新未来星科漫游。先从 Downloads 确定用户最新交付的实际 HTML 或 ZIP 入口，并记录路径、大小和 SHA-256。按用户原样发布的要求保留供稿字节。
>
> 核对 8443 当前 Deployment、UI 镜像与 runtime 镜像。基于执行时的线上 UI digest 增量打包，两个入口继续共用 `landmark-studio/wlxk.html`。沿用已有账户和小镇集成流程。
>
> 历史发布脚本有旧校验目录和旧标签残留，历史资源清单也存在滞后。请按本手册修正派生脚本的参数来源、校验本次上传文件，并从当前镜像实际资源生成正确清单。每次使用新的发布目录与标签，部署使用 digest，并保存部署前快照。
>
> 更新完成后验证 `/wlxk`、`/wlxk/` 和小镇实际资源的正文哈希；使用浏览器验证登记、进入漫游、小镇入口、返回和直接链接。实际记录手机与动画测试覆盖。使用 GET 正文核验线上，分享完整 `https://suanli.kechuangfuwu.com:8443/wlxk`。
>
> 持续处理本次范围内的可恢复发布失败，完成用户已授权的更新。遇到供稿或外部依赖的实质问题，准确说明缺口。最终给出版本、入口、验证结果、Git 状态和待处理项。

## 资料位置

- 项目约定与近期记录见 [HANDOFF](HANDOFF.md)。
- 入口定义见 [wlxk.yaml](../../deploy/wlxk.yaml)。
- 构建正文与体积校验见 [verify-production-build.mjs](../../src/ui/rabbita-town/scripts/verify-production-build.mjs)。
- 本机第二次供稿准备见 [prepare.mbtx](../../output/wlxk-v2/prepare.mbtx)，输入打包见 [package-input.mbtx](../../output/wlxk-v2/package-input.mbtx)。
- 历史 OCI 组装见 [package.mbtx](../../output/wlxk-v2/release/package.mbtx)，部署比较见 [rollout.mbtx](../../output/wlxk-v2/release/rollout.mbtx)。
- 当前可复用的浏览器断言见 [check.mbtx](../../output/wlxk-v2/check.mbtx)。

上述 `output/` 链接适用于当前本机。其他 AI 从新环境接手时，应使用第四节列出的服务器记录恢复历史材料，并按第五节修正后派生新版本。
