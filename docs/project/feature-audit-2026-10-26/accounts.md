# MoonTown 账户与算力功能清单

审计日期：2026-10-26。范围：当前 `main` 工作区（包含此前尚未提交的统一账户代码）及 8443 公共小镇。LunaNexa 的计费、机器租赁、组织管理等完整产品不在 MoonTown 功能数内。

本链按 11 个验收对象记录：可用 0、条件可用 8、演示 1、未完成 2。统一身份适配器已部署，不等于管理员与普通用户的真实跨账户验收已经完成；未使用用户凭据、切换账户、申请租约或启动模型。

## 功能与入口

| ID | 功能 | 当前入口 | 完成度与边界 | 建议呈现 | 证据 |
| --- | --- | --- | --- | --- | --- |
| A01 | 共用平台登录与账户身份读取 | 小镇右上角「登录/账户」→ `https://suanli.kechuangfuwu.com:8443/user/`；同源 `account/self.json` | 条件可用。复用 LunaNexa 的身份，不注册第二套账号；10/23 已部署。此次只确认登录入口可见，未重新完成真实用户登录验收 | 保留唯一账户入口；身份来自后端，不让用户填写 subject/token/provider | [账户入口](../../../src/ui/rabbita-town/main/account_entry.mbt) 第 4、15、35 行；[部署记录](../unified-account-compute.md) 第 156–187 行 |
| A02 | 在自己的组织范围内查看算力 | 算力页面收到多组织选择响应后显示组织名称；`?layer=compute&compute-organization=…` | 条件可用。只列当前用户有效成员关系，每次重新授权；真实多组织验收未完成 | 仅确需选择时显示；选择器属于主流程，不应要求用户去 Advanced 修正必需组织 | [组织过滤与读取](../../../src/account_compute/projection.mbt) 第 112、181、196 行；[组织入口](../../../src/ui/rabbita-town/main/secret_compute_room.mbt) 第 194 行 |
| A03 | 普通用户查看自己的独占机器及可达状态 | 登录后「算力」→地下逻辑端点列表；同源 `secret-compute-room.json` | 条件可用。读 `/v1/machine-access/self`，结束的租约不展示；空列表可以是真实无授权。用户 API 不提供真实显存利用率/任务数，不可把占位零值当实测。真实已授权普通用户验收仍待完成 | 默认显示机器、可达状态、数据时间/未提供、下一步；不向用户展示租约内部 ID | [个人资源投影](../../../src/account_compute/projection.mbt) 第 54、75、89、189 行；[界面状态](../../../src/ui/rabbita-town/main/secret_compute_room.mbt) 第 176 行 |
| A04 | 平台管理员查看批准的四台机器 | 同一「算力」入口，由当前真实 PlatformOperator 角色选择管理员视图 | 条件可用。限定批准的四个节点，不是整个 Kubernetes 集群；只有当前人的权限可读，组织管理员不自动等于平台管理员。真实管理员四台显示尚待验收 | 与 A03 同一界面，按权限换资源范围，不再造第二个管理账户；全局维护动作另设管理员区 | [平台四节点投影](../../../src/account_compute/platform.mbt) 第 4、91、176 行；[公共服务分流](../../../src/account_gateway/src/main/public_platform.mbt) 第 221 行 |
| A05 | 公共 Trial 算力目录 | 未登录进入小镇→「算力」；两条 Trial 逻辑端点 | 演示。本轮线上确认两条目录、完整地下模型和「未观测」状态。不是匿名推理服务、实时负载或两台正在执行任务的机器 | 保留演示标签；登录后看自己的资源。不能用动画或显示数量替代真实运行证明 | [目录生成](../../../src/account_compute/platform.mbt) 第 17、67 行；[线上记录](../unified-account-compute.md) 第 168–178 行 |
| A06 | 从共用门户连接自己的私有 MoonTown 工作区 | 门户产品入口→`/moontown/connect`→`/moontown/workspace/connect`；私有路径 `/moontown/workspace/` | 条件可用。已部署重定向与 workspace-owner 绑定；需要原有工作区授权。公开 shell 只读，不因登录就具备执行权限 | 在需要执行时给「进入我的工作区」；不让用户复制 handoff/token；不把只读公共页面包装成个人执行环境 | [公共重定向](../../../src/account_gateway/src/main/public_platform.mbt) 第 177 行；[工作区身份校验](../../../src/account_gateway/src/main/binding.mbt) 第 76、123 行；[上线结果](../unified-account-compute.md) 第 166 行 |
| A07 | 账户切换、退出后的数据隔离 | 现有账户门户退出/切换；MoonTown 检测身份变化，清除旧算力并重载 | 条件可用。有公共/账户/工作区存储隔离与回归测试，真实 A→B、过期、撤权、workspace A/portal B 验收未完成。MoonTown 内独立退出适配器尚未提供 | 身份、当前组织与退出入口可见；缓存命名空间、digest、重载检查后台自动完成 | [浏览器身份](../../../src/ui/rabbita-town/account_identity.js) 第 14 行；[算力刷新](../../../src/ui/rabbita-town/runtime_snapshot_fetch.js) 第 56、71 行；[存储范围](../../../src/account_gateway/src/main/public_platform.mbt) 第 148 行 |
| A08 | 遗留本地模式的账户、企业成员和租户管理 | 非统一身份的本地 miniapp Account/Enterprise/Admin；`/miniapp/account/*` 等管理路由 | 条件可用，仅本地模式。存在持久账户、会话、角色及成员操作；统一身份网关明确拒绝旧账户路由，不能当线上第二套账户使用 | 统一产品不展示旧管理面板；本地开发保留。要迁移的是后端权威与资料，不是给用户一个「本地/线上账户」开关 | [账户接口](../../../src/account_system/pkg.generated.mbti)；[管理实现](../../../src/account_system/management.mbt)；[旧路由阻断](../../../src/account_gateway/src/main/binding.mbt) 第 107–133 行 |
| A09 | 遗留本地订阅状态与付费权限开关 | 本地 `/miniapp/account/billing`，activate/cancel；账户管理组件 | 条件可用，仅本地状态管理。不等于收付款、发票、真实订阅结算；统一身份模式下被拒绝 | 不在公共/统一账户中呈现「已开通付费」或付费按钮；真实计费由平台负责，接入后只显示方案与权益 | [本地订阅处理](../../../src/cmd/miniapp_server/main.mbt) 第 1010–1067 行；[账户状态接口](../../../src/account_system/pkg.generated.mbti)；[联邦模式边界](../unified-account-compute.md) 第 354–368 行 |
| A10 | 共用身份到 MoonTown 付费、企业及产品执行权益的正式映射 | 尚无完整正式入口；当前统一身份只投影公共浏览和本人算力查看权限 | 未完成。登录、机器租约、MoonTown 工作区、Agent 执行与付费方案是不同授权，不能由用户名/邮件/管理员外观推导 | 真正接入后归「账户→方案与权限」；未接入时显示具体缺少的授权，不展示能绕过限制的 UI | [统一 member 校验](../../../src/ui/rabbita-town/main/account_experience.mbt) 第 101–109 行；[待实现权益迁移](../unified-account-compute.md) 第 354–368 行 |
| A11 | 当前账户的远程模型权限、MoonGate 路由与用量 | 地下预留的 MoonGate/远程端点投影；尚无正式账户级路由数据 | 未完成。当前投影将 `remote_routes` 留空、gateway 设为未观测。不能用主机全局 provider 配置或历史 staging 执行证明本用户有 Codex/DeepSeek/GLM/Kimi 权限 | 无数据时显示一条待接入状态；接入后作为算力的「模型服务」，不与物理机柜混排 | [空路由事实](../../../src/account_compute/projection.mbt) 第 36–46 行；[账户级待接入](../unified-account-compute.md) 第 301–307 行 |

## 与其他链路的边界

- 3D 机房、逐级模型和报告在 [空间链路](spatial.md) S06–S09，只计一次。设计可浏览并不等于设施资产已绑定。
- 真实机柜/U 位映射、Run→机器追踪、传感器历史是空间清单的 SU01–SU03 缺口，不再重复增加“已拥有功能”。
- 用户 Supervisor 创建和执行在 [研究与 Agent 链路](research.md) R17–R19，不能用 A01 登录成功作为其完成证据。
- 包分享在 [运维链路](operations.md) O21。当前统一身份模式明确阻断旧包传输鉴权，不能宣称公共账户可直接分享。

## 重复与收纳判断

1. **真正要收敛的是账户权威，不是让两个系统的按钮看起来一样。** 正式入口只使用 `/user/`；旧本地账户保持开发兼容，不显示给线上普通用户。账户 ID、邮件和显示名称不可作为迁移权限捷径。
2. **Trial、个人机器、平台四台是同一算力页面的三种资源范围，不是三套账户系统。** 必须在页面顶部明确当前范围，不能把视图切换当成权限授予。
3. **“算力”和“我的工作”有联系但还没有真实 Run→机器证据。** 统一导航可以做，连线不能凭 UI 邻近关系生成。
4. **Advanced 隐藏细节，不隐藏阻塞。** 登录失效、无租约、缺工作区授权、正在看演示都应直接显示；cookie 名称、内部组织 ID、digest、HTTP 重试和完整授权证明归诊断。
5. 管理员权限、租约过滤、同源检查、会话撤销、缓存隔离保留在后端自动执行。把它们移出主界面不等于删除检查。

## 本轮线上只读核对

2026-10-26 在 8443 公共入口观察到：

- 小镇首页明确标「公共展示 · Agent 为演示」，提供算力与登录入口。
- 地下采用统一 Three.js viewport；Trial 01/02 均「未观测」，真实逻辑对象提示「位置未绑定」。
- 空间报告显示无快照时间、无实测功耗/温度/吞吐；规划估算在 Advanced。没有下载或提交报告数据。
- 政策大厅可进入共用室内场景；政策手机明确说明已有专题主要是青年创业，未发送提问或验证模型执行。
- 公共「扩展工具」复现 `Pack Bridge unavailable (404)`，但仍渲染词汇/变化/跨 Pack 等长表单。此问题详见总览与 [材料链路](materials.md)，不能归因为账号未登录后让用户自行试错。

线上观测只证明上述展示与错误路径。账户 A/B/admin 的资源隔离、正式私有工作区执行、本地命令和后台长期运行本轮均未重新验收。
