# WLXK：服务补齐与内网访问排查

核验时间：2026-11-20，Asia/Shanghai。工作树：`/Users/kq/Workspace/moontown-main-shore`，分支 `main`。本任务未提交、未推送；工作树还有大量其他任务的改动，不能整体打包部署。

**11 月 23 日更新：** 独立 LAN 访问机 `.191` 曾通过公网映射成功，后来又在 TCP 阶段超时；同期外网与 LAN 直连均正常。下文 11 月 20 日的管理节点结果不能泛化为所有 LAN 客户端一直失败。用户禁止修改访问机，hosts 方案已撤回且未执行。最新证据、Nginx/Traefik 核对和未完成边界见 [11 月 23 日诊断](management-public-self-access-2026-11-23.md)。

## 两个独立问题

### 新页面只有 HTML，没有配套服务

另一账户的发布目录是管理节点上的 `/home/HwHiAiUser/town-wlxk-original-20261120-r1/`。它实际发布了新的 399438 字节 HTML，而非 Downloads 的 11 月 18 日版本。

原始 HTML SHA-256：`2bfe3a311a6531ad5253c778b8d4876a8dec9122d092f186f7e78cae943e63a1`。

该页面调用 `/api/health`、注册/登录/存档 API 和 `/ws?token=...`。这次上传没有这些服务，也没有对应 Kubernetes 路由；`/api/health` 实测 404。前端捕获错误后静默退回单机，故 HTTP 200、WebGL 能显示，都不能作为多人和云存档验收。

另有相对图片引用 `高德卫星影像.jpg`，供稿和服务器均无此文件。修复保留作者已有的地面、道路、水系，删除失败的贴图加载请求，没有伪造卫星影像，也没有调整建筑模型或页面样式。

### 内网连接公网地址失败

从已有授权的管理节点实测：

| 路径 | 修复前结果 |
| --- | --- |
| 内网 DNS 查询 `suanli.kechuangfuwu.com` | `106.39.18.146` |
| 内网直接访问域名 `:8443/wlxk` | TCP 连接 4 秒超时，尚未进入 TLS |
| 保留相同域名、SNI、Host，将连接送到 `192.168.2.173:443` | HTTPS 200，21 ms |
| 域名通过 `--resolve` 指到 `192.168.2.173:8443` | Connection refused |

因此存在内网到公网地址的回流路径问题，表现与 NAT loopback 缺失或被阻断一致；未登录路由器，不能断言具体是哪一条 NAT/防火墙规则。还发现内网 Traefik LoadBalancer 仅公开 80/443，公网 8443 的使用不能推导出内网主机也监听 8443。

进一步读取主机路由：`106.39.18.146 via 192.168.2.1 dev br-ngfw-in src 192.168.2.173`，该连接确实选用内网网关。初次普通账户抓包及 `sudo -n` 被拒绝；随后复用已有授权的主机身份完成交互式 sudo 认证，只读采集了定向 TCP 头，结果见下一节。内网 DNS 覆盖是避免走该回流路径的方案，不代表 NAT 故障根因已经定位。NAT 回流中缺少源地址转换可能造成回复绕过网关、地址不匹配，机制参见 [MikroTik 官方 Hairpin NAT 说明](https://help.mikrotik.com/docs/spaces/ROS/pages/3211299/NAT#NAT-HairpinNAT)；此处只解释可能机制，不据此判断现场路由器型号或具体配置。

### 18:20–18:27：扩大对照并抓包

所有 curl 检查都绕过显式代理，获取实际正文；公网对照另外绑定桌面真实网卡 `en1` 并将域名固定到真实公网 IP，避免 `198.18.*` 的 TUN DNS 干扰。

| 发起端 → 目标 | 结果 |
| --- | --- |
| 管理节点 → 百度 HTTPS | 200；TCP 6 ms，TLS 30 ms，总计 34 ms |
| 管理节点 → 阿里云 HTTPS | 403；TCP 7 ms，TLS 21 ms，说明网络及 HTTPS 已到达对端，403 是该站应用响应 |
| 管理节点 → 自身公网 443、8443 | 均在 TCP 建连阶段超时 |
| 管理节点以 `.175` 为源 → 自身公网 8443 | 同样超时；这是同一主机的另一网卡，不冒充独立客户端测试 |
| 管理节点 → 自身公网 SSH 32123 | TCP 超时；范围不局限于 WLXK 或 HTTP |
| 管理节点 → LAN 443，保留域名/SNI | 200，25 ms |
| 另一网络桌面 `en1` → `106.39.18.146:8443` | 200；TCP 24 ms，TLS 59 ms，总计 567 ms；复测同样成功 |

定向抓包先在 `br-ngfw-in`、后在 `any` 接口进行。使用固定客户端端口 48361/48362，以涵盖回复源地址可能被转换的情况。在 8443 测试窗口内看到 0、1、3 秒的 SYN 重传，未见该连接的 SYN-ACK、RST 或私网地址回包。`any` 的桥和物理接口会重复显示同一包，不能把重复观测算成额外重传。抓包仅限测试连接和包头，不采集登录或业务正文。

主机 filter INPUT/OUTPUT 默认均为 ACCEPT，仍保留 Kubernetes 跳转链；不能仅凭默认策略宣称所有子链均放行，但出站 SYN 已在接口上观测到。`rp_filter` 的 all 与 `br-ngfw-in` 均为 2。没有改动这些规则或主机路由。UDP traceroute 的第一跳即收到 `106.39.18.146` 的响应（0.439 ms），支持目标公网入口就在近端网关的判断，但 UDP 探测不能替代 TCP NAT 规则命中证据。

当前可排除“管理节点整体无法上公网”和“单个网页坏了”这两种解释。重点检查 `192.168.2.1` 或其上游对 LAN→自身公网 IP 的回流处理；尚不能指认具体 DROP、DNAT 或 SNAT 规则。尚未直接测试用户手机，不能把本机结果宣称为每个 LAN 终端的抓包结论。

历史证据：LunaNexa 的 `docs/EVENT_TRIAL_REHEARSAL_20261022.md` 已记录 LAN DNS 未配置、内网用显式 LAN 地址验证 TLS，外网另测 8443；`docs/EVENT_TRIAL.md` 同样要求 LAN 解析到内网入口。这表明回流未完成验收早于本次 WLXK 上传，但不能据此断言用户以前从来没有访问成功。

路由器普通管理入口 `http://192.168.2.1/` 返回正常，页面指向 `/html/index.html#/login`，公开状态显示非中继模式。仅凭前端特征不能确认品牌或型号。临时 SSH 本地转发被该页面以 307 转向自己的管理地址，浏览器未完成加载；该临时转发已关闭。没有登录、修改路由器，也没有用主机密码尝试路由器登录。

已请求用户提供路由器型号、WAN IPv4、8443/32123 的映射目标。取得这些信息或受控管理登录后，核对：公网地址是否就在此设备；转发规则是否仅匹配 WAN 入站；是否存在 NAT 回流/反射；LAN 回流是否需要与 DNAT 匹配的 SNAT；相关防火墙规则命中计数。不要为尝试而关闭防火墙、开启全机 DMZ 或随意切换全局 NAT 类型。

已增加 `deploy/wlxk-lan-https.yaml`，在 `kube-system` 创建 `platform-lan-https-8443` LoadBalancer，将 8443 转给同一个 Traefik `websecure`。随后保留正常域名和证书的内网 8443 实测 HTTPS 200，26 ms。

静态修复版上线后再次复测：普通 LAN 域名连接仍在 4 秒超时；同一请求覆盖解析至 `192.168.2.173:8443` 返回 200，用时 19 ms，`/wlxk/api/health` 也返回正常。此差异明确发生在网络连接路径，不是页面缓存、HTML、证书或登录失败。

**LAN 全网修复尚需 DNS/路由器管理入口。** 内网 DNS 应将此域名解析至 `192.168.2.173`；外网 DNS 保持公网 IP。另一可选方案是在路由器正确配置 NAT loopback。仅修改 Kubernetes CoreDNS 不会修复手机、电脑等普通 LAN 客户端。

不要让用户直接输入 HTTPS IP 地址代替域名：这会产生证书主机名不匹配。临时单机验证可以做受控 hosts 覆盖，长期应配置内网 DNS。

待取得内网 DNS 管理入口后，仅添加这一条内部域名覆盖：

```text
suanli.kechuangfuwu.com  A  192.168.2.173
```

先记录原配置；不要改公网 DNS，也不要仅修改 Pod 的 CoreDNS。应用后分别在实际 LAN 手机/电脑和外网核验。LAN 设备须实际使用该 DNS；浏览器安全 DNS、VPN、代理或缓存可能绕过它。最终验收必须使用正常域名访问，不能把 `--resolve` 成功当作全网修复成功。

管理节点的对照命令（`--resolve` 仅用于诊断，不是最终修复）：

```sh
getent ahostsv4 suanli.kechuangfuwu.com
curl --noproxy '*' --connect-timeout 4 --max-time 10 -sS -o /dev/null -w '%{http_code} %{remote_ip} %{time_total}\n' https://suanli.kechuangfuwu.com:8443/wlxk
curl --noproxy '*' --resolve suanli.kechuangfuwu.com:8443:192.168.2.173 --connect-timeout 4 --max-time 10 -sS -o /dev/null -w '%{http_code} %{remote_ip} %{time_total}\n' https://suanli.kechuangfuwu.com:8443/wlxk
```

使用 GET，勿将 HEAD 的代理异常当作正文不可用；该环境此前已有 HEAD 失败而 GET 成功的记录。

### 原来能访问、这次到底改了什么

已直接检查另一账户发布目录中的 `rollout.mbtx`：该脚本只替换 `moontown-platform` 的 `public-assets` 镜像，并校验原账户 runtime 不变，未包含路由器、DNS、NAT 或 Traefik Service 修改。这只证明已审阅脚本的范围，不能据此证明其账户没有进行其他操作。新 HTML 增加的在线服务依赖缺失，与 TCP 连接超时是两个独立故障。

本次修复新增 WLXK 后端与路由，调整前端对接；另新增 LAN 8443 Service。未修改路由器、公网 DNS 或既有 Traefik 80/443 Service。当前没有原先可用时同一 LAN 客户端的 DNS/连接记录，也没有路由器配置历史，因此不能确定原先通过的是 NAT 回流、内部 DNS、代理还是另一网络，更不能把失败归因于未经证实的某次路由规则变更。

路由器后台应找“静态 DNS／本地域名／Host Override”一类功能（具体菜单随型号而异），添加完整域名 `suanli.kechuangfuwu.com`、类型 A、地址 `192.168.2.173`。这里不填写协议、`:8443` 或 `/wlxk`。这是本地域名映射，不是把 `192.168.2.173` 填成全网 DNS 服务器。客户端须使用提供这条映射的内网 DNS；若路由器 `192.168.2.1` 提供该服务，检查 DHCP 下发及客户端实际 DNS 是否指向它。原公网端口转发和公网 DNS 保留。

保存后重新连接 Wi-Fi、刷新 DNS 缓存，验证客户端查询得到 `192.168.2.173`，再打开原 HTTPS URL。若使用 dnsmasq，其本地 hosts/host-record 解析机制见[官方说明](https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html)；未确认路由器型号前不提供品牌专属命令。

## 服务实现

源码为独立 MoonBit 模块 `src/wlxk_server`，没有另建用户名/密码账户体系。

| 路径 | 行为 |
| --- | --- |
| `GET /wlxk/api/health` | 服务存活和协议版本 |
| `GET /wlxk/api/session` | 当前浏览器身份对应的角色；未创建时返回空角色 |
| `POST /wlxk/api/visit` | 以昵称、外观进入，已有身份恢复自己的角色 |
| `POST /wlxk/api/save` | 保存当前会话的外观、位置、打卡与向导进度 |
| `POST /wlxk/api/leave` | 清除本浏览器的访客 Cookie；平台退出仍走平台门户 |
| `GET /wlxk/ws?session=<角色ID>` | WebSocket 的 init/join/leave/pos/look/save/kick 协议 |

平台身份只由现有 `moontown-platform:8082/moontown/account/self.json` 验证。只转发平台身份 Cookie，不信任客户端上传的账户 ID。服务不可验证身份时拒绝账户写入，不退回另一个账户或旧存档。匿名访客使用 Secure、HttpOnly、SameSite Cookie，其存档与平台账户分开；清除浏览器数据会失去访客存档入口。

HTTP 保存携带“期望角色 ID”，后端与当前已验证身份比较。这样 A 的旧页面不能在浏览器切换到 B 后把 A 的位置写入 B。WebSocket 消息中的伪造 ID 被忽略，身份来自握手；每 10 秒复查身份，失效会断开。公共同屏只传昵称、外观和位置，不传平台用户 ID 或凭据。

存档位于 PVC `wlxk-saves`，文件键由已验证账户 ID/随机访客凭据摘要产生。写入在互斥锁下原子替换。单副本 `Recreate`，不把多副本进程内 presence 当成共享状态。PVC 可以跨 Pod 重建保留数据；这不是跨节点备份或高可用方案。

新增网络策略仅允许 Traefik→WLXK 8084、WLXK→现有账户网关 8082 及 DNS。保留 namespace default-deny，未修改原账户、算力授权或资源隔离逻辑。

## 发布材料

管理节点：`ssh -p 32123 HwHiAiUser@106.39.18.146`，复用已有授权。kubeconfig：`/home/HwHiAiUser/.kube/lunanexa-management`。不要把凭据写进手册。

修复目录：`/home/HwHiAiUser/town-wlxk-repair-20261120-r1/`。

| 内容 | Digest |
| --- | --- |
| 原线上静态镜像 | `sha256:2bbbb394f88a7726b283b3f836fe8fdb71c2378dac83ad08ae96e454a419d544` |
| 原平台 runtime（保持不变） | `sha256:5baf6c9c2c930abf41ab2a4ba839adedf7cc80ee624145ccc64954928803325e` |
| 独立 WLXK 服务镜像 | `sha256:9b9c7e171c02d9091ec3e0c8c8f8c967c10d2a0839fb3cd44cd6bbd84e0b4e57` |
| 已上线修复静态镜像 | `sha256:66132aedc3010528940db8dcfa481cece8a92d10082c518e026dd1c1a57fabe5` |

已核验线上 Deployment：仅 `public-assets` 更新为上述静态镜像，原平台 runtime 仍为 `5baf6c9c…`，可用副本为 1。公网 `/wlxk` 下载得到的 HTML SHA-256 与本地修复文件一致：`0af7631133bf393539be890e6be01d19965326c58af52cccfcb45f776e1d096c`。

服务镜像存放于已有 `moon/moontown-account-gateway` OCI 仓库，但运行在独立 `wlxk-realtime` Deployment，启动的是新 `/opt/wlxk/server`；不能把它当成原账户网关镜像替换 `platform` 容器。

可复用工具：

- `scripts/repair-wlxk-client.mbtx`：只接受上述原始供稿哈希，精确修改账户与网络接线、失效贴图引用。新供稿哈希不同必须重新审核，不能盲套替换。
- `scripts/package-wlxk-release.mbtx`：从指定当前 OCI digest 增量打包，目录和标签由同一 release 参数生成。
- `scripts/rollout-wlxk-repair.mbtx`：先部署服务；UI 阶段仅替换 `public-assets` 的镜像，以 resourceVersion 和旧镜像测试防止覆盖并发发布。
- `deploy/wlxk.yaml`：原有 `/wlxk`、`/wlxk/` 短址；不需要重新改变页面路径。
- `deploy/wlxk-realtime.yaml`：服务、PVC、API/WebSocket 路由、最小网络连接。
- `deploy/wlxk-lan-https.yaml`：LAN 8443 入口，需要配合 LAN DNS。

服务器运行方式：

```sh
/home/HwHiAiUser/.moon-new/bin/moon run RELEASE/package-wlxk-release.mbtx -- RELEASE server CURRENT_RUNTIME_DIGEST CURRENT_MERGED_UI
/home/HwHiAiUser/.moon-new/bin/moon run RELEASE/rollout-wlxk-repair.mbtx -- RELEASE server
/home/HwHiAiUser/.moon-new/bin/moon run RELEASE/package-wlxk-release.mbtx -- RELEASE ui CURRENT_UI_DIGEST CURRENT_MERGED_UI
/home/HwHiAiUser/.moon-new/bin/moon run RELEASE/rollout-wlxk-repair.mbtx -- RELEASE ui
```

`CURRENT_MERGED_UI` 必须是该 UI digest 的完整合并文件树，不是仅有四个文件的 overlay。发布清单重新计算所有实际资源的哈希，排除 `asset-manifest.json` 自身和 AppleDouble 元数据。

从 macOS 打包源码时使用 `tar --no-mac-metadata --no-xattrs`。默认 tar 会生成 `._*.mbt`，Linux MoonBit 编译器会把它们当源码并报 UTF-8 错误。管理节点的 Linux 链接还需要 `-pthread -ldl`，已写入该模块的 `moon.pkg`。

## 验收与边界

已通过的服务测试：

- `moon test`：身份 Cookie 筛选、非法位置与存档身份字段过滤。
- `scripts/test-wlxk-server.mbtx`：两个访客的保存隔离、越权角色 ID 的 409、无会话写入 401、非同源写入 403、WebSocket 加入/位置/存档、同一角色重复窗口处理。
- 本机身份替身的 A/B 账户测试：同账户恢复、跨账户隔离、身份上游失败拒绝写入、进程重启保留保存、撤销身份后断开。**这是身份契约替身测试，不冒充两个真实平台账户的登录验收。**
- 公网部署实测相同访客协议；实际重建 `wlxk-realtime` Pod 后，原访客 Cookie 仍恢复相同角色和已保存的位置。
- 初步服务资源观测为约 1m CPU、3 MiB 内存，只代表本次少量访客测试，不代表容量压测。当前最多 64 个同屏连接。

浏览器验收脚本 `scripts/test-wlxk-browser.mbtx` 检查独立入口、进入/移动、刷新恢复、小镇内嵌共享存档、返回小镇、按需加载及手机尺寸。不要同时跑会重启服务的测试和浏览器场景测试；readiness 通过后还要等待外部路由收敛。

已对正式发布文件完成浏览器验收：独立入口可进入、移动并保存；刷新后恢复保存；小镇按需打开同一漫游，恢复同一访客并返回小镇。场景观测为 1425 个顶层对象、20 辆车。该链路没有 JavaScript 异常或 WLXK 请求错误。结果与截图位于 `output/wlxk-repair-20261120/`。

验收不应掩盖以下边界：

- 小镇宿主页仍有历史可选运行态 JSON 的 404，以及 `/town/api/neighborhood/public` 的 503；本轮记录到 31 条这些响应，单独存入 `browser-results.json` 的 `townWarnings`。不将它们伪装成成功，也不把它们算作 WLXK API 错误；本次没有修改这些模块。
- 首轮 390×844 手机尺寸检查已观测到场景对象，但截图仍处于加载层淡出阶段，原供稿的固定宽度登记面板也向右超出屏幕。`body` 隐藏溢出，使 `scrollWidth` 检查不足以发现裁切。随后加强验收，等待加载层完全退出并记录实际面板边界；这次桌面与小镇流程再次完成，但手机场景初始化在 90 秒内未完成，整次脚本因此以失败退出。`browser-results.json` 是首轮记录，不能当成完整手机验收通过；失败记录见同目录 `browser-followup.json`。未改原 CSS，手机加载稳定性与完整交互仍待单独排查。
- 同一浏览器使用访客 Cookie 的恢复与隔离已通过；真实平台账户的双账户登录验收仍需用户完成登录。身份替身契约测试不能代替这一步。

供稿的另一项独立限制仍在：AI 对话指向 `http://192.168.5.206:8001/v1`，本次从管理节点连接也超时。该模型服务未包含在上传包，当前修复不能宣称已恢复 AI 对话。3D 模型、内置园区资料和导览仍保留。不得把真实模型请求失败伪装成成功。

## 下一位 AI 的检查顺序

1. 读取本文件和发布手册的历史记录，核对当前部署镜像，不能把上午的“当前版本”当成下午之后的线上事实。
2. 分别测试外网、LAN 域名、LAN 直连保留 SNI 的结果。记录 DNS、TCP、TLS、HTTP、页面运行五层，不用 HTTP 200 代替功能验收。
3. 收集供稿引用的每个模块、图片、API、WebSocket 和模型服务。HTML 原样上传只解决静态文件发布。
4. 保留统一身份边界，API 和 WebSocket 放在 `/wlxk` 下；不要抢占全站 `/api`、不要开放新的密码库。
5. 服务可用后发布客户端；两个入口使用同一份文件和同一套会话。验证失败状态、刷新、账户切换和后台恢复。
6. 回滚 UI 只回滚本次静态增量；保留 PVC。不要删除用户存档，也不要把服务镜像填进原账户网关。
