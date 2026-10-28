# 街区运营：入口、权限与验收

更新：2026-10-28。本文记录这次公共街区链路，不改产品权限，也不把合成账户测试写成线上验收。

## 使用入口与边界

公共目标入口为 `https://suanli.kechuangfuwu.com:8443/moontown/`。此次新增链路的线上部署、真实 A/B/主办账户验收仍需单独完成；没有把新的业务数据写入线上。

| 用户要做的事 | 入口／操作 | 权限与结果 |
| --- | --- | --- |
| 看公共故事、活动 | 街区公共页；本地 `/?community=1&view=town` | 匿名只读已公开内容；新库为空，不以演示居民填充 |
| 写故事 | 我的管理 → 故事 → 写故事 | 登录者自己的草稿；保存不等于发布 |
| 发布或撤回故事 | 已保存草稿 → 同意公开 → 发布；已公开 → 撤下 | 精确作者；同意绑定具体 `content_revision`，旧标签不能发布新版 |
| 创建、发布活动 | 我的管理 → 活动 | 新建仅可信身份的 PlatformOperator；已有活动只由其 owner 管理，别的管理员不自动获得名单 |
| 报名、取消 | 公开活动 → 报名；我的报名 | 使用服务器身份，不信任提交的 participant/actor/role；满额候补，释放名额按顺序递补 |
| 确认到场 | 本人主办活动 → 报名与签到 | 仅 owner，已确认名额，且在活动时间内；不是小镇游戏的每日签到奖励 |
| 会后跟进 | 已结束活动 → 本人自愿提交 | 只有已确认或已签到参与者可提交，明确同意后保存私人信息；不自动代报名者创建需求 |
| 记录下一步 | 本人主办 → 待跟进 | 仅 owner，可记录下一步及结果；不冒充工作任务执行、邮件外发或交付证明 |
| 回到空间 | 返回小镇、建筑、室内、地下 | 继续使用既有共享 3D viewport；完整模型和独立 Studio 保留，不以业务表单替换模型 |

`can_host` 只控制创建新活动。已有活动按精确 owner 管理；主办角色撤销后是否冻结既有活动是尚未另设的产品策略，不应误解为所有管理员均可接管活动。

## 服务端合同

| API | 身份 | 作用 |
| --- | --- | --- |
| `GET /api/neighborhood/public` | 可匿名 | 公共 projection，`mine:null`，没有草稿、名单、联系方式或跟进内容 |
| `GET /api/neighborhood/mine` | 登录 | 公共内容加当前账户自己的草稿、报名、跟进，以及本人主办活动名单 |
| `POST /api/neighborhood/actions` | 登录、精确同源 JSON | `{action,payload,expected_actor_id}`；actor fence 必须匹配当前验证过的 Cookie 身份 |

公共 gateway 路径在以上 API 前加 `/moontown`；个人 workspace 中的街区也读取这个共享服务，不能写进个人工作区副本。

身份来自 LunaNexa 验证过的 Session。`expected_actor_id` 只防止旧 A 标签在 Cookie 切换到 B 后误写；它不是授权凭据。缺失或不一致返回 `409 identity_changed`。发布故事、活动还要提交已查看对象的 `expected_content_revision`；不能仅用变化频繁的全局 revision 替代内容版本。

错误边界：未登录 401，非 owner／无权限 403，不存在 404，非法输入 400，生命周期或版本冲突 409。身份服务失效不会降级为本地 operator。写入成功必须已持久化；磁盘失败不能显示成功或伪装成空库。

完整动作与字段见 [neighborhood 合同](../../src/neighborhood/README.mbt.md)。HTTP 适配器见 [desktop](../../src/cmd/desktop_server/neighborhood_http.mbt)、[public gateway](../../src/account_gateway/src/main/neighborhood_http.mbt)；账户和路径分流见 [前端 transport](../../src/ui/rabbita-town/main/neighborhood_client_effects.mbt)。

## 数据与部署

业务文件由服务器 `MOONTOWN_NEIGHBORHOOD_STATE_FILE` 指定；请求不能指定路径。共享公开运营数据与每用户 workspace、静态资源镜像分开。

存储按 mutex + 文件锁执行整笔读、鉴权、容量／状态检查、写入，写临时文件后原子替换。每次读取重新载入，刷新及进程重启不依赖浏览器 localStorage。文件仅用于单共享文件系统，并非分布式数据库。

[公共部署生成器](../../scripts/prepare-public-town.mbtx) 已定义独立 `moontown-neighborhood-state` PVC、`/var/lib/moontown-neighborhood/state.json`、单副本／Recreate。此次只是源码与生成器修改：没有应用生产 manifest、创建生产内容或验证线上 PVC 恢复。上线前仍需检查实际 PVC 权限、容量、备份／恢复与身份路由。

## 可重复执行的本地 HTTP 验收

```sh
moon run scripts/check-neighborhood-journey.mbtx
```

[验收脚本](../../scripts/check-neighborhood-journey.mbtx) 构建真实 desktop 和 public gateway 二进制。它只接受本地模式开关，不接受远程 URL；创建独立临时目录、随机 loopback 端口，子进程不继承环境，显式指定临时 suite 和 state。身份服务仅提供合成的 A、B、organizer、other-organizer，后两者都是 operator，但互不获得对方内容权限。

gateway 验收通过独立 loopback ingress 共用 `/user` 与 `/moontown` 的 origin，真实 gateway 自己执行授权与业务，不用 fixture 模拟业务成功。自动化中的所有故事、报名、联系方式均为明确的测试哨兵文本，不外发。

覆盖：

- 匿名无私有数据；身份角色不能由 payload、查询或伪造 participant 字段提升。
- A/B 草稿、报名与跟进隔离；另一个 operator 不能发布他人内容或读取名单。
- 强制同源、JSON、身份 fence；A 旧标签配 B Cookie 无写入。
- 故事草稿、显式同意、旧内容版本拒绝发布、正确发布、作者撤回。
- 主办活动草稿、发布版本 fence、容量候补、本人取消与递补；提前签到／提前结束拒绝。
- 主办方在实际时间窗口确认到场；重复报名、签到、跟进返回冲突，不生成重复记录。
- 结束后自愿私人跟进、owner 记录下一步、其他用户及公共 projection 不泄露信息。
- 并发不同作者写草稿后均可重读；进程重启后签到与跟进继续存在。
- 会话过期后不能读私有内容或写入；响应 `no-store`。

每条 HTTP 状态、缓存 header、成功 envelope 和关键业务断言分别计数；检查数不是“独立功能数量”。首次试跑发现并修正了测试工具自身的 identity origin、Content-Length、Int64 JSON 字符串编码问题；这些中断不计作通过。浏览器联调又发现 fixture 缺少算力授权读取路由，错误返回 401 导致产品的换号保护持续重载；fixture 已改为认证成功、合法空机器列表，并新增账户与 compute scope 身份一致性检查，没有删除产品的身份保护。

| 本轮证据 | 实际状态 |
| --- | --- |
| desktop + gateway 完整 HTTP journey | 最新重跑实际 `446/446` 通过：两个适配器各 `223` 项检查；命令退出 `0`，包括各自真实子进程重启后重读及账户／compute scope 一致性 |
| Browser 合成账户交互 | 主 agent 已实际点击完成故事发布、A/B 隔离、报名候补、真实时间窗签到、结束与自愿会后跟进；详见下表，不等于线上账户验收 |
| Rabbita 全套 UI 测试 | 主 agent 本轮实际 `845/845`；这次全套运行早于最后追加内容版本锁，不能替代新版定向回归 |
| 新版街区定向 UI 测试 | 最终收尾实测 `24/24`：client + navigation `16`，manage `8`，包括本人回复优先于报名历史、说明默认折叠 |
| Neighborhood native 域测试 | 主 agent 本轮实际 `12/12` 通过 |
| 账户／路径／快照 JS 回归 | 主 agent 实际 `17/17`（包含 platform-base `6` 项），保留登录及换号隔离 |
| UI release 与产物校验 | 主 agent 完成 info、fmt、release build；产物 verifier 通过，`772` 文件、`70.6 MiB`；不是线上部署结果 |
| Landmark Studio 模型测试 | 本轮实际 `19/19` 通过 |
| 完整 Viewer DOM 契约 | 本轮实际通过：建筑 `22`、室内 `19`、数据中心 `58` 个 UI target |
| 空间渐进展示契约 | 本轮 `check-spatial-disclosure.mbtx` 通过：Advanced 与完整 viewer 可达，未知观测仍显示 |
| 8443 真实身份／部署／负载 | 未在本轮验收；不以 loopback 合成账户代替 |

HTTP 最新成功运行保留的本地证据目录为 `/var/folders/_j/kcn3f7817s71gymnv_nnn1bm0000gn/T/moontown-neighborhood-acceptance-.34641.20f96928`，内含两个适配器各自的 `state.json`、日志和隔离 workspace。它是临时本机证据，不是部署路径或生产数据库。脚本重跑会创建新的路径。

## 浏览器验收方法

```sh
moon run scripts/check-neighborhood-journey.mbtx -- --serve-only
```

此模式只构建并启动干净浏览器 fixture，不声称已经执行 HTTP journey。也可 `--desktop-only --serve` 先跑 desktop 验收再保留浏览器服务。首次 native release 链接可能需要数分钟；只有看到 `BROWSER FIXTURE READY` 才开始。

- 页面：`http://127.0.0.1:17868/?community=1&view=town`，使用当前 Rabbita `dist`，更新静态产物后可刷新。
- 合成账户切换：`http://127.0.0.1:17869/login/a`、`/login/b`、`/login/organizer`、`/login/other-organizer`；`/logout` 退出。发放的 Cookie 仅属 loopback，跳回街区入口；生产无这些路径或测试账户。
- 服务输出本次临时 state 和 log 的精确路径。退出脚本停止其子进程，临时证据保留，不删除用户数据。

浏览器步骤：匿名空态 → A 保存草稿 → 刷新 → B 无 A 草稿 → A 同意发布 → 匿名看到故事 → organizer 创建并发布未来活动 → A/B 报名及候补 → organizer 查看名单、时间到后签到 → 结束 → 参与者自愿跟进 → owner 记录下一步 → 刷新并切换非 owner 检查隔离。

同时检查键盘焦点、表单错误、发布前预览、未保存修改提醒、取消确认与重复点击状态。换号时旧私有表单必须清空；未配置／过期身份不得被“演示模式”掩盖。最后返回地图并进入室内／地下，检查同一 viewport、完整模型／Studio 入口仍可达。

模型测试和 DOM 契约不是视觉截图、加载速度或帧率证明。浏览器尚未完成的步骤、生产授权及跨真实用户验证应继续显式列为未验收。

### 2026-10-28 浏览器实际结果

主 agent 在上述独立 loopback fixture、合成 A/B/organizer 账户中操作真实 UI。没有在公共线上发布故事或活动，没有联系真实参与者。

| 实际操作 | 观察结果 |
| --- | --- |
| 匿名打开街区 | 正常空态，无预置故事或活动 |
| A 保存故事草稿，切换 B，再切回 A | B 的“我的”没有 A 草稿；A 返回仍可继续自己的草稿 |
| A 勾选公开授权并发布，随后退出登录 | 匿名页面可见已发布故事；[故事截图](../../output/neighborhood-story-qa.jpg) |
| organizer 创建并发布活动 | 测试活动时间为当日 11:49–12:49，容量 1；真实 UI 完成保存和发布 |
| A 报名，B 报名 | A 报名成功，B 加入候补 |
| 主办方打开签到管理 | 11:49 前不可签到；等实际时间到达后确认 A 到场，界面显示“已签到” |
| 主办方结束活动 | 出现结束确认，确认后进入已结束状态 |
| A 提交会后需求 | A 自愿勾选后提交，主办方“我的”顶部出现待跟进 1 |
| 主办方记录下一步，A 再查看 | 待跟进数量清零；A 的“我的”可读到下一步和回复 |
| 手机尺寸 390 × 844 | 内容宽 374、左右边距 8，无横向溢出；[手机截图](../../output/neighborhood-mobile-qa.jpg)，检查后已恢复 viewport |
| 关闭街区 → 地标 → 室内设计模型 | 返回原地图；G 座三层完整 3D 正常渲染，对象列表 14 项 |
| 室内 → 安全电梯 → 地下算力中心 | 完整机房 3D 正常渲染，对象列表 16 项；A 显示“账户已连接，暂无授权机器”，不伪造算力资源 |

本轮浏览器未重复执行“取消报名后的候补递补”和“撤回故事”；两项已有上述真实 HTTP 回归通过。完整键盘导航、所有错误分支与重复点击情形没有在此宣称逐项完成。

最后收尾将非行动说明移入 Advanced，并将本人会后回复提到报名历史前，附上活动名称；主办方待办仍优先。最终定向测试 `24/24` 通过，随后执行 info、fmt 和 release 构建；[会后回复截图](../../output/neighborhood-followup-qa.jpg)记录最终浏览器检查。

## 上线前由负责人确认

- 真实故事电子版及公开署名需获得本人授权；不把测试故事或已有私人材料自动发布。
- 真实主办账户必须已有身份系统授予的合法角色，才能创建活动；这次不自行新增角色或授予管理员权限。
- 负责人确认真实活动文案、时间、场地、名额和发布同意后再发布。
- 8443 实际部署、PVC 权限／备份恢复、真实 A/B/主办账户隔离验收尚未执行；本地测试不能写成“全部上线”。
