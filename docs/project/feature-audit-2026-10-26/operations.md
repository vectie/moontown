# 建设、调度与运维链路功能审计

审计日期：2026-10-26。范围：当前 `main` 工作区（包含已有未提交变更）的 PlanBook、建设执行、后台监督、离线长期目标工具、系统设置、跨产品交接、Miniapp 开发服务和精确包传输。

本次以用户任务合并重复命令，得到 **22 项能力：可用 9、条件可用 6、演示/fixture 6、未完成 1**。这些是本链路的统计，不应直接和其他链路重复相加。

- **可用**：有实际局部实现和明确使用方式，主要为本地/CLI；不等于当前生产环境可用。
- **条件可用**：需已配置的运行时、账户授权或外部服务；不能从接线推导端到端成功。
- **演示/fixture**：开发服务内的操作可以真实保存局部记录，但不属于正式账户/原生业务闭环。
- **未完成**：存在组件、配置或历史局部证据，完整用户目标尚无验收。

本轮只读代码和文档；未运行测试、启动 daemon、派发修复、登录账户或部署。没有把测试文件存在当成本轮通过。表中的历史运行证据保留其日期和限定范围。唯一新增内容是这份审计文档。

入口约定：`CLI …` 指 `moon run src/cmd/main -- …`；`goal_*`、`portable_transfer` 指对应 `src/cmd/…` 原生可执行文件。网页入口为产品挂载点下的相对路径；表中 API 是源码定义的产品内路径，并非声称每条路径都已在公开 8443 服务开放。

## 功能—入口—完成度

| ID | 用户任务 / 功能 | 入口 | 完成度与实际边界 | 入口处置建议 | 证据 |
|---|---|---|---|---|---|
| O01 | 记录建设计划、实施 backlog、进展与验证证据 | CLI `planbook bootstrap/status`；PlanBook 的 `plan.md`、backlog 页面 | **可用（本地）**。可生成/读取持久工作区，不是一键建设产品 | 开发者 → 建设计划；与 O02–04 共用工作台 | [命令](../../../src/cmd/main/planning_commands.mbt#L12)、[生命周期](../../PLANBOOK.md#L768)、[backlog](../../PLANBOOK.md#L879) |
| O02 | 检查实现缺口、生成受限修复计划 | CLI `planbook doctor/autonomy/validation`；`live-autonomy.json`；Operations 状态 | **可用（本地）**。判据检查、差距和证据输出存在；生成 repair 不等于已修好 | 管理员“待处理问题”；判据、路径、receipt 藏 Advanced | [命令](../../../src/cmd/main/planning_commands.mbt#L16)、[自检边界](../../PLANBOOK.md#L937) |
| O03 | 执行受限源码修复并查看/取消工作 | CLI `planbook repair [--dispatch] [--execution=acp]`、`planbook repair status`；`native-work list/show/refresh/sync/cancel/supersede`；`GET /api/native-work[/ID]`、`POST /api/native-work/ID/refresh\|cancel\|sync` | **条件可用**。依赖 Native Code/ACP 服务、源树、Book、授权和结果证据。保存状态、代码变动、owner 接受是不同阶段，不能宣称自主自修复已完成 | 合并 O01 的执行详情；默认状态、停止、查看改动；强制同步/supersede 仅开发者 Advanced | [当前默认 Native](../../../src/planbook_runtime/planbook_repair.mbt#L19)、[CLI](../../../src/cmd/main/main.mbt#L23)、[API](../../../src/cmd/desktop_server/native_work_api.mbt#L9)、[应用结果](../../../src/build_pipeline_runtime/wenyu_native_execution.mbt#L199) |
| O04 | 从课程/方案选择功能并跟踪实现输出 | CLI `editor-pipeline status/refresh/feature-select [--dispatch]`；`operations.html?panel=migration`；`editor-pipeline.json` | **条件可用**。有选择、stage projection 和 Native owner 接收实现，完整运行仍依赖执行器/工作区；不是另一套 IDE | 合并 O01–03 为“计划→执行→验证→结果” | [CLI](../../../src/cmd/main/planning_commands.mbt#L35)、[界面](../../../src/ui/rabbita-town/main/viewport_editor_pipeline.mbt#L76)、[owner 应用](../../../src/native_work/editor_owner_apply.mbt#L4) |
| O05 | 生成/查看系统稳定配置与操作手册 | CLI `cookbook bootstrap/status/doctor`；生成 Cookbook wiki/site、stable-state manifest | **可用（本地）**。`doctor` 是 `bootstrap` 别名；MoonDesk 原生管理、完整 drift review UI 未完成 | 管理员 → 系统说明；三个命令不算三个功能 | [别名实现](../../../src/cmd/main/planning_commands.mbt#L2)、[命令与未来边界](../../COOKBOOK.md#L92) |
| O06 | 持续运行 Mayor/周期任务，启停与重载 | CLI `daemon tick/run/start/stop/restart`，含 `--once`；launchd 脚本 | **可用（本地）**。监督循环和进程控制存在；不等于生产多日 soak、备份恢复和 OS 服务资格完成 | 管理员“自动运行”状态/开关；tick/worker/PID 仅开发者 Advanced | [命令](../../../src/cmd/main/runtime_commands.mbt#L25)、[控制](../../../src/daemon_runtime/daemon_runtime_control.mbt#L2)、[本地监督限定](../../../README.mbt.md#L129) |
| O07 | 查看系统健康、异常和执行进度 | CLI `status`、`runtime status`、`daemon doctor`、`live status`；`operations.html`；`GET /health` 和运行快照 | **可用（本地）**。多个视图消费相近 Town/daemon/execution 状态；快照不是实时硬件遥测 | 合并“运行概况 / 待处理”；默认显示可行动异常，心跳/原始 JSON 放 Advanced | [Operations](../../../src/ui/rabbita-town/main/dashboard_page.mbt#L15)、[异常来源](../../../src/ui/rabbita-town/main/operations_context.mbt#L11)、[快照](../../../src/cmd/desktop_server/main.mbt#L408) |
| O08 | 批量编辑长期目标 | `goal_table export FILE csv\|tsv`；`goal_table import FILE` | **可用（离线 CLI）**。保留十字段及运行历史，产生候选 JSON；不安装、不修改实时 registry | 合并“长期任务 → 批量编辑”；原始格式 Advanced | [用途/命令](../../GOAL_TABLE.md#L3)、[安装边界](../../GOAL_TABLE.md#L31) |
| O09 | 预览调度重叠、比较方案、错开初始执行 tick | `goal_outlook preview/compare/stagger` | **可用（离线 CLI）**。tick 投影不是日历预测；不模拟容量/失败/重试，不执行；stagger 不保证后续不重叠 | 合并 O08 的“预览影响”；复杂 tick/间距参数 Advanced | [投影边界](../../GOAL_OUTLOOK.md#L3)、[命令](../../GOAL_OUTLOOK.md#L18)、[错峰](../../GOAL_OUTLOOK.md#L173) |
| O10 | 将离线目标修改与较新状态三方合并 | `goal_merge inspect BASE EDITED CURRENT` / `merge …` | **可用（离线 CLI）**。精确字段合并，冲突不产出部分候选；不选胜者、不安装实时状态 | O08 保存时的冲突流程，不单列一级入口 | [流程与限制](../../GOAL_MERGE.md#L3) |
| O11 | 比较采用 Town 前后的人工投入 | `goal_effort GOALS DIARY json\|csv` | **可用（离线 CLI）**。基于人工填写 review/supervision/followup 日志；不是自动生产率测量，不证明因果节省 | 报告 → 人工投入；高级分析，不与实时算力统计混淆 | [命令](../../GOAL_EFFORT_REPORT.md#L55)、[统计语义](../../GOAL_EFFORT_REPORT.md#L73) |
| O12 | 创建/暂停/恢复/删除 Code 定时任务 | `GET/POST /api/code-schedules`；action `create/delete/pause/resume`；daemon 调用代码调度 | **条件可用**。持久 schedule/reservation、Book 校验和 Native runtime claim 已实现；依赖绑定 Code 会话/服务。未发现独立 Rabbita 编辑入口 | 与长期目标共用“自动任务”，保留“研究/代码”类型及权限边界；代码配置 Advanced | [路由](../../../src/cmd/desktop_server/main.mbt#L855)、[动作](../../../src/cmd/desktop_server/code_schedule_api.mbt#L35)、[派发](../../../src/code_schedules/dispatch.mbt#L104) |
| O13 | 调整系统运行参数 | Admin → Settings；`operations.html?admin=settings`；`GET/POST /miniapp/system/settings`；只读 `/system-settings.json` | **条件可用**。UI、typed registry、revision、原子保存与审计存在；要求 `ManageSystemHealth`，不能凭页面认定统一账户已有管理权限 | 仅管理员；常用频率/容量置首，连接/retention/timeout 放 Advanced | [文档](../../SYSTEM_SETTINGS.md#L3)、[权限门](../../../src/cmd/miniapp_server/main.mbt#L930)、[UI](../../../src/ui/rabbita-town/account_management.js#L444)、[保存](../../../src/system_settings_runtime/store.mbt#L124) |
| O14 | 查看/排查 Desk→Claw→Gate→Book 交接 | `operations.html?panel=migration`；`moondesk-bridge.json`；runtime/bookkeeper outbox claim/release/reconcile API | **条件可用**。有持久交接和 **2026-08-01 staging** 的真实 provider/重启记录；manifest/checkout found 不等于全链路可用。账号级 MoonGate 路由仍待适配 | 合并任务详情“执行记录”；migration console 仅开发者；普通用户不需要四个产品名 | [入口](../../../src/ui/rabbita-town/main/dashboard_page.mbt#L32)、[bridge](../../../src/ui/rabbita-town/main/viewport_moondesk_bridge_panel.mbt#L25)、[历史证据](../../DEPLOYMENT_HANDOFF.md#L231)、[账号路由缺口](../unified-account-compute.md#L305) |
| O15 | Miniapp 建筑创建、摆放、共享、发布、归档、发现 | Node fixture `POST /miniapp/buildings`、`/place`、`/share`、`/publish`、`/archive`；`GET /miniapp/buildings/search`；CLI `miniapp …` | **演示/fixture**。局部状态可以保存，但 CLI 每次建立 fixture；不能把同名操作视为正式 native 建筑生命周期。与地图本地编辑、正式 marketplace 分开 | 开发者样例；产品化应迁入统一实体/权限后作为“我的建筑” | [fixture routes](../../../src/miniapp_local_backend/routes.mbt#L12)、[CLI fixture 身份](../../../src/cmd/main/miniapp_commands.mbt#L314)、[Node 实现](../../../scripts/miniapp-local-backend.mjs#L282) |
| O16 | 恢复归档建筑并保留原记录 | fixture `GET /miniapp/buildings/archived`；`POST /miniapp/buildings/restore` | **演示/fixture（局部工具可用）**。版本绑定恢复为 private_draft/shared_private；未接 native/Rabbita，不是整机备份恢复 | 合并 O15 的“已归档”；正式接通前标开发预览 | [范围](../../MINIAPP_ARCHIVE_RECOVERY.md#L3)、[API](../../MINIAPP_ARCHIVE_RECOVERY.md#L69)、[实现](../../../scripts/miniapp-local-backend.mjs#L375) |
| O17 | 预览并修改建筑名称/简介/标签 | fixture `POST /miniapp/buildings/profile/preview`、`/profile/apply` | **演示/fixture（局部工具可用）**。版本/digest 约束，保留历史；无原生 UI、自动撤销或历史 profile 浏览 | 建筑详情“编辑资料”，不独立暴露“预检”工具 | [范围](../../MINIAPP_BUILDING_PROFILE.md#L3)、[路由](../../../scripts/miniapp-local-backend.mjs#L167) |
| O18 | 下载建筑审阅记录包 | fixture `GET /miniapp/buildings/review-packet?buildingId=…`；同路由加 format/digest 下载 JSON/Markdown | **演示/fixture（局部工具可用）**。导出当前 retained records，不是 owning Book 成果、备份/导入格式；与 canonical collaboration outcome 不同 | 建筑/任务详情 → 导出 → 审阅记录；技术 digest 自动处理，冲突时再解释 | [非 native 边界](../../MINIAPP_REVIEW_PACKETS.md#L11)、[路由](../../MINIAPP_REVIEW_PACKETS.md#L90) |
| O19 | 在保留的会话中找关键词 | fixture `GET /miniapp/conversations/search`；snapshot 的 conversationSearch action | **演示/fixture（局部工具可用）**。literal search，限当前可见建筑；不是语义研究搜索，未接原生客户端 | 合并统一搜索的“会话”过滤，不另设查询工具 | [范围](../../MINIAPP_CONVERSATION_SEARCH.md#L3)、[入口](../../MINIAPP_CONVERSATION_SEARCH.md#L18) |
| O20 | 集中查看等待审阅和失败运行 | fixture `GET /miniapp/runs/inbox`；结果提供 bound inspectPath | **演示/fixture（局部工具可用）**。只读保留记录；done 不是 provider 成功证据；native adapter/Rabbita 未接 | 合并“待处理”；不要新增平行 review inbox；正式接通前开发预览 | [未接线声明](../../MINIAPP_RUN_INBOX.md#L9)、[路由](../../MINIAPP_RUN_INBOX.md#L64)、[发现入口](../../../scripts/miniapp-local-backend.mjs#L254) |
| O21 | 跨账号传递精确 MoonBook 包，授权/撤销下载 | `portable_transfer --base-url ORIGIN --session-stdin upload/list/preview-share/share/revoke/download/withdraw`；`/miniapp/marketplace/portable-packages` | **条件可用（仅独立本地账户模式）；统一身份线上明确禁用**。存在真实私有字节 store/client 与 AccountApplication；federated native handler 返回 403，网关也拒绝 legacy route，需新的 entitlement adapter。不是“只差验收”。不安装/执行包或 hosted Try | 产品化后合并 Marketplace 的下载/分享；完整包披露与收件人不能隐藏；hash/binding/receipt 放 Advanced | [实际实现范围](../../PORTABLE_PACKAGE_TRANSFER.md#L3)、[CLI](../../../src/cmd/portable_transfer/README.md#L1)、[禁用说明](../unified-account-compute.md#L361)、[native 403](../../../src/cmd/miniapp_server/portable_transfer_http.mbt#L12)、[网关 legacy 分类/拒绝](../../../src/account_gateway/src/main/binding.mbt#L107) |
| O22 | 发布资格检查、部署与回滚验收 | `miniapp_deployment` readiness API/配置；Deployment Handoff；`deploy/…` 与验收脚本 | **未完成（有组件和历史局部证据）**。readiness 检查不是自动部署；**2026-08-01** staging 有 provider/重启证据，WeChat UI-to-UI 未通过；**2026-10-23** 8443 公共部署已补齐另一部分，但不补齐全链路资格 | 开发者/运维发布台，不在普通用户主页 | [readiness](../../../src/miniapp_deployment/readiness.mbt#L2)、[历史资格](../../DEPLOYMENT_HANDOFF.md#L231)、[8443 新记录](../unified-account-compute.md#L156) |

## 应合并的 5 组

1. **PlanBook / autonomy / repair / editor pipeline / Native Work → 建设计划工作台。** 是同一任务的计划、差距、执行和证据层。保留后端所有者边界，不让用户在五个术语间来回导航。
2. **goal_table / outlook / stagger / merge → 自动任务编辑流程。** 输入、影响预览、冲突处理共用一个入口；Code schedule 可共享列表，但保留“长期研究目标 / Code 会话”不同权限和执行语义。
3. **daemon / runtime / live-autonomy / Native Work / run inbox → 运行与待处理中心。** 共用状态入口，点击再看执行器/receipt；不能把 Node fixture inbox 数据先混入真实 native 待处理。
4. **create / share / publish / archive / restore / profile → 一套建筑生命周期。** 当前 Node fixture、地图 local state、正式 marketplace 的 authority 不同，先统一实体/权限再迁移，不能只把按钮搬到一起。
5. **审阅包 / 原始 JSON / receipt / bridge 记录 → 任务详情的导出与技术详情。** 与“用户成果下载”清楚区分，不都称“结果/报告”。

## Advanced 与权限边界

| 放置 | 内容 |
|---|---|
| 普通任务默认信息 | 当前状态、结果、最后更新时间、需要用户做什么、失败后的可行动恢复、公开/私有状态 |
| 任务 Advanced | 原始 JSON、schema/contract、source digest、binding/receipt、执行器和 source root、历史技术记录 |
| 管理员 | daemon 启停、系统设置、平台级健康、授权相关操作；管理员范围不是一个可被任何人展开的折叠面板 |
| 开发者/运维 | outbox claim/reconcile、强制 sync/supersede、代码执行目标、repair dispatch、发布部署、PID/heartbeat/tick、内部容量策略 |
| 必须保持可见的决策 | 完整包包含什么、谁能获取包、执行或分享的必要确认、明确的权限错误和冲突处理 |

不能把“去 hardening”理解为删除后端授权、tenant 隔离、版本校验或精确包授权。应把自动检查留在系统内部，通常只呈现可行动的结论；用户需要做决定时，再显示足够的信息。Advanced 不是权限控制，也不能隐藏会改变共享/执行范围的关键披露。

## 文档与实现的状态冲突

- [PLANBOOK 的旧 ACP 叙述](../../PLANBOOK.md#L1011) 仍称 source repair 走 ACP；[当前默认值](../../../src/planbook_runtime/planbook_repair.mbt#L25) 已是 `execution="native"`，显式 `--execution=acp` 才使用兼容路径。清单应视为同一功能的执行选项，不计两项。
- [2026-08-01 交付文档](../../DEPLOYMENT_HANDOFF.md#L263) 的 HTTPS 尚未部署结论不能覆盖 [2026-10-23 8443 公共上线](../unified-account-compute.md#L156)；反过来，公共 shell 上线也不能补齐 WeChat 双用户 UI、生产真实隔离、后台运行等独立验收。
- [旧 Town Status 的完成比例](../../WENYU_TOWN_STATUS.md#L99) 和单次 healthy snapshot 不应作为当前完成度。此清单只按实际入口、实现范围、证据与剩余条件分类。
- [2026-08-01 的真实 provider staging](../../DEPLOYMENT_HANDOFF.md#L231) 不证明当前每个用户有模型权限。[账号级 MoonGate adapter 未完成](../unified-account-compute.md#L305)，不能依据主机级 provider 名称显示用户拥有 Codex/DeepSeek/GLM/Kimi 权限。
- [Miniapp CLI 的 fixture 初始化](../../../src/cmd/main/miniapp_commands.mbt#L314) 容易被误认正式产品；它与真实 native supervisor/marketplace 不能互相替代。`done`、`accepted` 等 fixture 标签不证明 provider 执行或 MoonBook 接受知识。
- **精确包传输并非仅待线上验收**：[统一身份规则](../unified-account-compute.md#L361)、[native handler](../../../src/cmd/miniapp_server/portable_transfer_http.mbt#L12) 和 [gateway binding](../../../src/account_gateway/src/main/binding.mbt#L107) 都明确阻止沿用独立账户令牌。适配完成前不能开放为线上用户功能。

## 跨链路去重约定

- O08–O12 只计长期目标/代码任务的管理工具，不重复计研究链路的“创建监测 / 实际研究执行”。
- O14 是交接观测，不重复计主管 Agent onboarding、delegate/steer、Book 审核或各模型产品。
- O15 是 Miniapp fixture lifecycle，不重复计地图编辑器的建筑摆放或真实 marketplace listing。
- O21 只计包字节传输，不重复计 listing 元数据、Book 打包/导入、运行/试用。
- 本文只覆盖系统设置 O13；本地账户/企业管理/订阅状态及统一账户迁移由账户链路单列。

## 审计方法与限制

使用 MoonBit agent guide 核对命令、源包、API 和实现边界；使用 UI/UX skill 的基础渐进披露、可行动错误和导航一致性原则形成合并建议。专项 disclosure 检索第一次结果跑偏，缩窄后仍未命中，因此没有把这些建议声称为专项数据库结论。建议是代码关系与用户任务的审计判断，不是本轮浏览器可用性测试结果。

本轮没有资格宣称任何历史测试重新通过，也没有将条件能力改成生产可用。源码当前存在的接口和文档示例提供可追踪证据，不替代环境级验收。
