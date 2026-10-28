# Civic、赛事与 Marketplace 功能审计

审计日期：2026-10-26。范围：当前 `main` 工作区的业务建筑、赛事、通用沟通协议、委托/涌现评估器、Marketplace。包含尚未提交的工作区代码，不代表生产构建与此版本完全一致。

本链路只读检查实现、入口和已有验收材料；未发起业务请求、未修改产品、未运行新测试。根审计员另在 8443 公共小镇只读进入政策馆和提问面板，未发送问题、未调用模型。

## 口径与计数

四类主状态：

- **可用**：限定范围内有完整实现和本地/历史验证证据；不等于本轮生产验收通过。
- **条件可用**：已有实现，但依赖模型、受信宿主身份、执行器、外部服务或待完成的联调。
- **演示**：界面/样例或可视化可看，但不能当作真实业务执行结果。
- **未完成**：已有合同/模板/部分结构，不足以提供所描述的业务闭环。

本表 C01–C27 共 **27 项**：**可用 8、条件可用 12、演示 5、未完成 2**。下方 11 个注册模块只是分组，不能再加到 27 项上。Town Shell/Vitality 的空间、运行观测功能由其他链路计数；研究、账户、消息、课程等横向能力还需在总表去重。

## 关键结论

1. 11 个 Civic 注册模块不是 11 个完整业务闭环。部分只有协议、模板、样例卡和投影。
2. Contest Express 已超过旧状态文档：2026-10-13 的本地 UI 验收包含发布赛事、组队邀请、提交、可信进程评测、审批、榜单、申诉。身份、runner 和指标是合成验收，不是生产硬件验证。
3. 政策置信度、人才“Verified evidence”、社交匹配百分比、机器人/遥测计数存在硬编码或 tick 演示来源。必须移除伪测量或明确 Demo，不能仅放进 Advanced。
4. 通用 Civic reconcile 产物明确 `accepted_facts_count: 0`，仅证明信息经过协议各阶段，不证明业务结论被接受。[协议证据](../../../src/civic/service_reconcile_policy.mbt#L81)
5. Town Marketplace 是持久化后端能力，但不是 Valley Market“积分兑换”的实现。名称接近不能互相充当完成证据。

## 11 个注册模块覆盖（分组，不计数）

[完整注册表](../../../src/civic/services_registry.mbt#L2)；[Town Areas 入口](../../../src/ui/rabbita-town/main/dashboard_sections.mbt#L2)。Districts 实际只渲染 [9 张模块卡](../../../src/ui/rabbita-town/main/civic_module_cards.mbt#L48)，没有 Valley Market / Story Radar。

| 注册模块 | 实际入口 | 当前可证明范围 | 未证实/未完成边界与来源 |
| --- | --- | --- | --- |
| Town Shell | 小镇首页、Town Areas → Districts；CLI `civic status` | 小镇投影、模块状态、操作入口已有实现，具体功能由空间/运维链路计数 | 注册目的中的“24x7”不等于生产全天候验收完成。[定义](../../../src/civic/services_registry_foundation.mbt#L2) |
| Resident Twin Homes | 地图居民建筑；Town Areas → Residents | 三个示例居民卡、私密/公开投影协议 | 真实居民授权资料→记忆写入→日常自主行动完整业务未证实。[定义](../../../src/civic/services_registry_foundation.mbt#L40) |
| Policy Hall | 地图“昌平政策大厅”→“问政策”；Districts 卡 | 昌平上下文入口、MoonClaw 问答入口、source-backed service 协议 | 资料主要青年创业；跨政策领域权威资料与真实申报/办结未完成。[定义](../../../src/civic/services_registry_learning.mbt#L2) |
| Contest Express | Quests → Open hackathon workbench；`hackathon.html` | 本地赛事闭环，见 C04–C10 | 真实硬件 runner/生产身份验收、二进制材料托管、奖金支付不在已验证范围。[定义](../../../src/civic/services_registry_learning.mbt#L42) |
| Social Square | 地图社交广场；Town Areas → Social | exchange/reduce/distribute 协议、研究沙龙 proof slice；社交卡样例 | 居民真实同意→介绍→RSVP→反馈完整社交闭环未证实。[定义](../../../src/civic/services_registry_exchange.mbt#L2) |
| Talent Avenue | 地图人才大道；Social → Talent Star Avenue / Reception Route | 人才卡、接待路线样例；人才证据/技能图协议 | 真正人才认证、实时技能图、项目/导师匹配服务未证实。[定义](../../../src/civic/services_registry_exchange.mbt#L40) |
| Vitality Tower | Districts → Vitality；健康/运营投影 | 部分真实运行状态能力已有，与运维链路去重 | 留存、兑换、线下活动、机器人等多项业务指标仍是演示计算。[定义](../../../src/civic/services_registry_foundation.mbt#L80) |
| AI Science Garden | AI Garden；Quests → Resident AI adoption sprint | 教育模板、worker lane、场景/试用卡 | 个性化课程执行、学习前后测、实际工具试用闭环未证实。[定义](../../../src/civic/services_registry_learning.mbt#L85) |
| Physical Bridge | 虚实桥；Districts 卡；Quests → Physical bridge sync | 审批 gated handoff 合同、房间/机器人/遥测展示 | 真实场地预订、机器人调用、遥测接入与完成回执未证实。[定义](../../../src/civic/services_registry_foundation.mbt#L119) |
| Valley Market | 地图 valley-market、通用建筑面板 | 积分/奖励/兑换建议协议与台账模板 | 真实积分账户、交易/兑换、预算防滥用业务未完成；不能用 Marketplace 后端代替。[定义](../../../src/civic/services_registry_exchange.mbt#L78) |
| Story Radar (`broadcast-tower`) | 地图语义 `story-radar`、通用建筑面板 | 故事草稿/脱敏/审核协议 | 真实成果→独立审阅→公共广播专用闭环未证实；赛事 Stories 是单独已有子能力。[定义](../../../src/civic/services_registry_exchange.mbt#L116) |

## C01–C27 功能—入口—完成度

Marketplace 的 Bunnia 手机入口来自产品文档，本次没有验证 Bunnia UI。`可用` 行中的评估器、赛事工具均有明确范围，不代表整个关联业务已完成。

| ID | 功能 | 具体入口 | 主状态 | 实现/证据 | 缺口及整理建议 |
| --- | --- | --- | --- | --- | --- |
| C01 | 居民分身卡、需求/情绪/计划摘要 | Town Areas → Residents | 演示 | [固定居民资料](../../../src/ui/rabbita-town/main/civic_resident_data.mbt#L2)；[渲染入口](../../../src/ui/rabbita-town/main/civic_resident_agents.mbt#L51) | 三个固定人物，不是真实用户画像。并入“我的 Agent/个人资料”，缺真实数据时显示空态。 |
| C02 | 昌平政策提问与议题梳理 | 政策大厅 → 问政策 → MoonClaw | 条件可用 | [提示及范围](../../../src/ui/rabbita-town/main/policy_hall_question_flow.mbt#L14)；[按钮](../../../src/ui/rabbita-town/main/policy_hall_question_flow.mbt#L52)；今日 8443 只读可见 | 入口已可见，模型可达性未验。青年创业之外资料不足。保留问题、来源、下一步。 |
| C03 | 政策材料/资格/截止日期/清单研究 | 政策 workspace；CLI `civic bootstrap/status/reconcile`；问题引导 lane | 条件可用 | [服务合同](../../../src/civic/services_registry_learning.mbt#L2)；[结果 reconcile](../../../src/civic_runtime/civic_service_reconcile.mbt#L2) | 通用执行/合同不证明每个政策已实证。与 C02 合并“政策助手”，不宣称资格判断/申报完成。 |
| C04 | 赛事创建、规则/赛道、日历、公开发布 | `hackathon.html#mayor`、`#challenge`、`#tracks` | 可用 | [readiness](../../../src/hackathon/program.mbt#L240)；[操作](../../../src/hackathon/program.mbt#L442)；[历史 UI 验收](../CONTEST_EXPRESS_IMPLEMENTATION_VERIFICATION.md#L23) | 本地可用。Mayor desk 仅管理员显示；runner 配置、私密评审说明进管理 Advanced。 |
| C05 | 报名、组队、邀请/接受、队员管理 | `hackathon.html#teams` | 可用 | [报名](../../../src/hackathon/participation.mbt#L39)；[邀请](../../../src/hackathon/participation.mbt#L68)；[同意](../../../src/hackathon/participation.mbt#L110)；[验收](../CONTEST_EXPRESS_IMPLEMENTATION_VERIFICATION.md#L25) | 本地身份 fixture 验证，不是生产账号验收。保留“我的队伍”单入口。 |
| C06 | 版本化在线提交、材料声明和回执 | `hackathon.html#teams` → submission | 可用 | [提交](../../../src/hackathon/participation.mbt#L223)；[回执 UI](../../../src/ui/rabbita-town/competition-ui.js#L339)；[验收](../CONTEST_EXPRESS_IMPLEMENTATION_VERIFICATION.md#L26) | 当前是 URL+SHA256 声明，不是文件托管。主显截止时间/提交状态；hash/revision 放详情。 |
| C07 | 人工评分、审核、申诉与处理 | `hackathon.html#reviews`；本人提交回执 | 可用 | [评分](../../../src/hackathon/competition.mbt#L230)；[评审操作](../../../src/hackathon/evaluation_operations.mbt#L142)；[申诉验收](../CONTEST_EXPRESS_IMPLEMENTATION_VERIFICATION.md#L29) | 本地可用。评审者专用 desk，普通用户只看到反馈和申诉。 |
| C08 | 可信 benchmark 队列、执行、结果审批、恢复重试 | `hackathon.html#reviews` → benchmark；后台 worker | 条件可用 | [worker](../../../src/hackathon/evaluation_worker.mbt#L4)；[runner](../../../src/hackathon/evaluation_runner.mbt#L107)；[禁用客户端伪造结果](../../../src/cmd/desktop_server/main.mbt#L596) | synthetic runner 已验证，真实数据集/受权硬件/runner 待部署。配置与 evidence 细节放 Advanced。 |
| C09 | 按赛道排行榜、资格闸门、临时/最终结果 | `hackathon.html#leaderboard`（Champion Wall） | 可用 | [排行榜](../../../src/hackathon/evaluation_leaderboard.mbt#L78)；[最终确认](../../../src/hackathon/evaluation_leaderboard.mbt#L204)；[验收](../CONTEST_EXPRESS_IMPLEMENTATION_VERIFICATION.md#L28) | 本地可用；须保留 synthetic/real、provisional/final 区别，不能将测试分数当机器实测。 |
| C10 | 赛事 FAQ、故事公告、赛事/团队私有 MoonBook 同步 | `hackathon.html#faq`、`#stories`；Mayor desk 同步重试 | 可用 | [公开内容](../../../src/ui/rabbita-town/competition-ui.js#L231)；[FAQ](../../../src/ui/rabbita-town/competition-ui.js#L259)；[Book 同步](../../../src/hackathon/book_projection.mbt#L313)；[验收](../CONTEST_EXPRESS_IMPLEMENTATION_VERIFICATION.md#L30) | 本地内容与同步实现可用，外部 Book 呈现未验。FAQ/公告留赛事内，sync 细节进 Advanced。 |
| C11 | 居民/Agent 社交匹配、介绍建议 | Town Areas → Social → Agent Matches；Social Square 卡 | 演示 | [两组静态匹配](../../../src/ui/rabbita-town/main/civic_social_talent_data.mbt#L2)；[UI](../../../src/ui/rabbita-town/main/civic_social_talent.mbt#L56) | 87/79% 固定；同意/约见/跟进真实闭环未证。与 C12 统一发现入口，移除伪置信度。 |
| C12 | 人才卡、项目技能展示、VIP 接待路线 | Social → Talent Star Avenue / Reception Route | 演示 | [固定人才/成就](../../../src/ui/rabbita-town/main/civic_social_talent_data.mbt#L22)；[卡](../../../src/ui/rabbita-town/main/civic_social_talent.mbt#L12)；[路线](../../../src/ui/rabbita-town/main/civic_social_talent.mbt#L37) | “Verified evidence”无真实对应证据。真实验证前逐卡标示例，不展示认证语义。 |
| C13 | AI 科普学习任务、工具试用、前后对照 | AI Garden；Quests → Resident AI adoption sprint | 演示 | [教育合同](../../../src/civic/services_registry_learning.mbt#L85)；[任务卡](../../../src/ui/rabbita-town/main/civic_quests.mbt#L44) | 通用任务可承载内容生成，不等于真实学习系统。与课程/工具链路去重，未接工具不显示试用成功。 |
| C14 | 线下场地/机器人/屏幕请求与确认 | Physical Bridge；Quests → Physical bridge sync | 演示 | [交接合同](../../../src/civic/services_registry_foundation.mbt#L119)；[任务卡](../../../src/ui/rabbita-town/main/civic_quests.mbt#L56)；[待接入提示](../../../src/ui/rabbita-town/main/civic_physical_bridge_labels.mbt#L59) | 真实执行未完成。保留草稿/审批合同，隐藏机器人/房间实时承诺；接通授权与回执再开放。 |
| C15 | 河谷积分、奖励、兑换建议 | Valley Market 建筑/协议 workspace | 未完成 | [合同](../../../src/civic/services_registry_exchange.mbt#L78)；[演示指标](../../../src/ui/rabbita-town/main/civic_town_aggregate_metrics.mbt#L35) | 模板/演示，不是真实积分账本。与 Marketplace 区分；不呈现余额/兑换可用。 |
| C16 | 全镇成果故事发现、脱敏、审阅、广播 | Story Radar / `broadcast-tower` workspace | 未完成 | [服务合同](../../../src/civic/services_registry_exchange.mbt#L116) | 合同已有，专用真实闭环未证。与 Town Chronicle、已审赛事公告统一动态入口，运行日志不等于公开成就。 |
| C17 | 建筑协议、8 种沟通模式、周期轮次、结果回流 | CLI `civic protocols patterns/pattern-install/pattern-manifest/pattern-template/schedules tick/status` | 条件可用 | [命令](../../../src/cmd/main/domain_commands.mbt#L23)；[8 模式](../../../src/civic/communication_pattern_registry.mbt#L2)；[reducer 选择](../../../src/civic_runtime/civic_communication_reducer.mbt#L2)；[MoonClaw 调用](../../../src/civic_runtime/civic_communication_reducer_moonclaw.mbt#L23) | 本地协议/fixture 可用，真实 reducer 依赖 MoonClaw。8 模式不另计8个完成产品。用户选协作模板；模式/reducer/ledger 进 Advanced。 |
| C18 | 多候选委托评比、证据评分与提名 | CLI `commission evaluate INPUT OUTPUT` | 可用 | [CLI](../../../src/cmd/main/main.mbt#L51)；[评估器](../../../src/commission/commission.mbt#L144)；[文件接口](../../../src/commission_runtime/runtime.mbt#L2) | 本地评估器，只消费既有候选/评分证据，不代表自主完成委托。归协作评审高级工具。 |
| C19 | 自主 Civic 轮次评估、异议/少数意见、联盟、分发/归位验证 | CLI `emergence evaluate INPUT OUTPUT` | 可用 | [评估器](../../../src/emergence/emergence.mbt#L209)；[文件接口](../../../src/emergence_runtime/runtime.mbt#L2) | 本地评估器可用；输入需已有贡献/审核/回执，自治运行闭环未证。与 C18 统一高级评审。 |
| C20 | Agent/建筑安全发布、独立审核、版本/归档 | Miniapp owner publish；API `/miniapp/marketplace/listings/{agent,building,transition}` | 条件可用 | [Agent 草稿](../../../src/town_marketplace/publication.mbt#L63)；[建筑草稿](../../../src/town_marketplace/publication.mbt#L181)；[生命周期](../../../src/town_marketplace/publication.mbt#L317)；[独立审核测试](../../../src/town_marketplace/marketplace_wbtest.mbt#L132) | 本地后端已有，依赖宿主身份/审核运营，线上未验。Agent/建筑共用发布流程。 |
| C21 | 已发布资源搜索、可解释推荐、公开索引 | Bunnia Discover（文档）；API `/miniapp/marketplace/discovery/{search,recommendations,feed}`、`/public-index` | 条件可用 | [搜索](../../../src/town_marketplace/discovery.mbt#L74)；[推荐](../../../src/town_marketplace/discovery.mbt#L148)；[feed](../../../src/town_marketplace/discovery.mbt#L207)；[广告隔离测试](../../../src/town_marketplace/marketplace_wbtest.mbt#L407) | 本地后端可用，UI/线上未验。合为发现入口，不将确定性 rank 宣传为生产推荐效果。 |
| C22 | 私信/团队/建筑/Agent 工作频道和消息 | Bunnia Messages（文档）；API `/miniapp/marketplace/{channels,messages}` | 条件可用 | [频道](../../../src/town_marketplace/communication.mbt#L109)；[消息](../../../src/town_marketplace/communication.mbt#L260)；[ACL 测试](../../../src/town_marketplace/marketplace_wbtest.mbt#L574) | 本地后端可用，依赖宿主身份。与聊天统一收件箱；保留 ACL，安全提示在分享/加入边界出现。 |
| C23 | 关注订阅、通知、已读 | Listing Follow；Notifications；API `/subscriptions`、`/notifications`、`/notifications/read` | 条件可用 | [订阅](../../../src/town_marketplace/engagement.mbt#L2)；[通知](../../../src/town_marketplace/engagement.mbt#L84)；[已读](../../../src/town_marketplace/engagement.mbt#L118)；[幂等测试](../../../src/town_marketplace/marketplace_wbtest.mbt#L707) | 本地后端可用，依赖宿主。统一任务/消息收件箱，主显行动项；过滤/订阅管理 Advanced。 |
| C24 | 私密分享预览、指定接收人授权、撤销 | Share preview；API `/shares/preview`、`/share-grants`、`/share-grants/revoke`、`/shared-listings` | 条件可用 | [授权](../../../src/town_marketplace/communication.mbt#L697)；[撤销](../../../src/town_marketplace/communication.mbt#L906)；[预览](../../../src/town_marketplace/communication.mbt#L942)；[测试](../../../src/town_marketplace/marketplace_wbtest.mbt#L791) | 本地后端可用，依赖宿主。主显谁能看/分享什么，不能隐藏授权决定；排除字段/hash/引用放详情。 |
| C25 | 发布 Agent 的 Try/Install/Invite/Request access → 审批 → MoonClaw 回执 | Listing action → Messages → Agent work → Requests；API `/action-requests`、`/decision`、`/retry-handoff` | 条件可用 | [决定](../../../src/town_marketplace/action_execution.mbt#L191)；[绑定](../../../src/town_marketplace/action_execution.mbt#L290)；[回执](../../../src/town_marketplace/action_execution.mbt#L357)；[桥接](../../../src/cmd/miniapp_server/marketplace_execution_bridge.mbt)；[测试](../../../src/town_marketplace/marketplace_wbtest.mbt#L1155) | 依赖有效 supervisor、MoonDesk handoff、MoonClaw；不是点击即安装/执行成功。统一申请使用入口，再选目的。 |
| C26 | Orderlist 需求发布、跨账户交付、接受/拒绝/取消 | API `/miniapp/marketplace/orders`、`/fulfillment`、`/decision`、`/cancel`；UI 本次未证 | 条件可用 | [需求实现](../../../src/town_marketplace/orders.mbt#L63)；[接收测试](../../../src/town_marketplace/orders_wbtest.mbt#L14)；[拒绝回流](../../../src/town_marketplace/orders_wbtest.mbt#L54)；[跨账户持久化](../../../src/town_marketplace/orders_wbtest.mbt#L235) | 本地后端可用，宿主依赖；不自动启动 Agent、不支付。归需求与交付，与 C25 共收件箱但保留状态语义。 |
| C27 | 赞助位和自然结果隔离 | API `/miniapp/marketplace/sponsored`；Discovery sponsored lane | 条件可用 | [赞助位](../../../src/town_marketplace/engagement.mbt#L146)；[展示](../../../src/town_marketplace/discovery.mbt#L168)；[发布者约束测试](../../../src/town_marketplace/marketplace_wbtest.mbt#L434) | 仅本地记录/展示，商业计费未完成；发布者/管理员 Advanced，不宣传完整付费投放。 |

### 证据边界补充

- [Contest Express 历史验收](../CONTEST_EXPRESS_IMPLEMENTATION_VERIFICATION.md#L17)：2026-10-13 使用本地合成 Mayor/Alice/Bob/reviewer；[真实部署边界](../CONTEST_EXPRESS_IMPLEMENTATION_VERIFICATION.md#L52)明确未验证生产 LunaNexa、Ascend 实测、外部 MoonBook 渲染，不含二进制托管或奖金支付。旧 `WENYU_TOWN_STATUS.md` 的整体进度不能覆盖这些较新的具体实现。
- [Marketplace release 边界](../../MARKETPLACE_DISCOVERY.md#L273)：仍依赖可信宿主 session、限流/abuse、审核运营、支付/广告账单、provider health。当前代码已[同步账户上下文到短时 Marketplace session](../../../src/cmd/miniapp_server/main.mbt#L670)，因此不能写“完全没账户接入”；也不能据此宣称生产跨用户隔离验收完成。
- 今日 8443 只读 UI：政策馆室内可进入，点击询问打开谷光手机；明确说明“目前专题主要青年创业，其他领域待权威来源，不能断言覆盖”。界面显示“小爪 Moonclaw Guide·本地 Agent 可提问”，还有四个角色预设欢迎文。本次没有发送问题，**入口可见不等于模型可达、预设欢迎文不等于真实 Agent 已运行**。
- Social Square 的[proof-slice 测试](../../../src/civic_runtime/civic_protocol_proof_slice_wbtest.mbt#L2)验证 inbox/contribution/reduction/outbox/review，结果处于 review。通用[reconcile 合同](../../../src/civic/service_reconcile_policy.mbt#L101)明确这不宣称 review-gated 输出已成为 accepted facts。

## P0：真实性问题——移除伪测量或明确局部 Demo

| 发现 | 精确证据 | 应怎样表达 |
| --- | --- | --- |
| 政策 `Confidence 94%` 来自任务 `Completed` 状态，不是答案正确率 | [计算](../../../src/ui/rabbita-town/main/civic_policy_hall_metrics.mbt#L81)；[69/74/82/56/94/28 常量](../../../src/ui/rabbita-town/main/civic_policy_hall_metrics.mbt#L93)；[卡片呈现](../../../src/ui/rabbita-town/main/civic_module_service_cards.mbt#L22) | 改为有来源/来源不足/待核实/待审核；不显示虚构正确概率。 |
| 人才卡硬编码 `Verified evidence` 和近期成就 | [静态成就及标签](../../../src/ui/rabbita-town/main/civic_social_talent_data.mbt#L29) | 示例逐卡标明；真实认证须能打开对应证据。 |
| 社交匹配 87%/79% 是固定值 | [样例匹配](../../../src/ui/rabbita-town/main/civic_social_talent_data.mbt#L2)；[显示百分比](../../../src/ui/rabbita-town/main/civic_social_talent.mbt#L7) | 保留匹配理由，去掉无定义百分比；模型评分另行解释。 |
| 机器人/遥测信号随 tick 变化 | [遥测 `3 + model.tick % 4`](../../../src/ui/rabbita-town/main/civic_physical_bridge_telemetry_metrics.mbt#L20)；[机器人计数](../../../src/ui/rabbita-town/main/civic_town_aggregate_metrics.mbt#L72) | 未连接设备/演示信号；接入后显示来源和时间。 |
| Quests 固定 `Bridge live`、`Matching`；赛事 coaching 轮换 mock judge/deck gap | [coaching](../../../src/ui/rabbita-town/main/civic_quests.mbt#L20)；[社交](../../../src/ui/rabbita-town/main/civic_quests.mbt#L34)；[线下桥](../../../src/ui/rabbita-town/main/civic_quests.mbt#L56) | 将演示和真实业务状态分开，不能由任务 running/complete 推断现实服务成功。 |
| Residents 始终渲染三名样例，不依据真实居民资料 | [渲染](../../../src/ui/rabbita-town/main/civic_resident_agents.mbt#L85)；[数据](../../../src/ui/rabbita-town/main/civic_resident_data.mbt#L2)；[operational ready 总闸门](../../../src/ui/rabbita-town/main/dashboard_sections.mbt#L74) | 真实/样例数据边界明确；空工作区给引导，不编造真人活动。 |

顶层已有公共 Agent 演示提示，可降低风险，但不能保证所有深层卡和未来真实工作区中的百分比、`Verified`、`live` 都不误导。以上是源代码路径证据，未声称本轮线上每个面板均可达。**不能仅把这些信息藏入 Advanced 而继续保留假真实性。**

## P1：重复入口与合并建议

1. **赛事三处收敛到同一赛事状态。** 地图 Contest Express、Quests 的 mock-readiness 卡、完整 `hackathon.html` 应共享赛事 ID 和状态。前两者只做摘要/深链，不能独立展示与真实赛事无关的冠军和完成度。[已有 workbench link](../../../src/ui/rabbita-town/main/civic_quests.mbt#L82)
2. **Social Square + Talent Avenue + Marketplace Discover → 发现与协作。** 人/项目/Agent/建筑按类型筛选；建筑保留空间入口，不另造不一致的匹配来源。
3. **Town Shell + Vitality + Districts → 单一权威运行摘要。** 场景、建筑和运营看板只是不同视图，不应拥有三套状态来源。
4. **Story Radar + Town Chronicle + Contest Stories → 动态入口。** 按来源分类，内部运行记录和可公开成果分清；审核/脱敏边界仍保留。
5. **Marketplace 请求 + Orderlist + 协作审核 + 任务通知 → 我的待办/收件箱。** 统一呈现，不强行合并权限、执行状态和验收合同。
6. **Registry、卡片与别名统一。** 11 注册/9 卡片，`broadcast-tower` vs `story-radar`，`resident-twins` vs `wenyu-resident-twins` 等兼容别名只留内部；用户标签由单一 registry 提供。[Social 双 ID](../../../src/ui/rabbita-town/main/civic_social_square_lookup.mbt#L2)；[AI 双 ID](../../../src/ui/rabbita-town/main/civic_ai_garden_lookup.mbt#L2)

## P2：Advanced 与主界面边界

适合 Advanced：

- 八种 communication pattern 英文 ID、reducer 模式、ledger 路径、round ID、协议 readiness。
- worker/queue/health 底层指标、诊断细节；主界面保留简明异常和下一步。
- SHA256、benchmark revision、runner key、重试/恢复细节、私有 MoonBook 同步状态。
- commission/emergence 输入输出文件、评估细节。
- sponsored placement 配置、发布版本/hash、索引导出。

不应隐藏：是否 Demo、数据是否实时、分享给谁、是否消耗算力/预算、请求尚未执行、最终审批/拒绝及原因、政策来源不足、赛事 provisional/final。

## 审计方法说明

使用 MoonBit agent guide 核查实现边界，使用 UI/UX skill 检查信息层级。针对 progressive disclosure/Advanced 的两次技能检索没有适用命中；本文收敛建议依据仓库实际入口和数据来源，不将通用建议伪装成验证结果。本文件仅为审计清单，没有实施以上产品改动。
