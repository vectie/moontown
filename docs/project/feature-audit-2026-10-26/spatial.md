# 空间链路：功能、入口与完成度

审计日期：2026-10-26。范围为当前 `main` 工作区的地图 → 建筑 → 室内 → 地下 → 3D 模型 → 返回地图链路，包含未提交的既有改动。

本次只做盘点、测试与文档整理，**没有修改产品、模型、权限或部署**。账户、Trial 目录、机器权限归账户链路；任务派发与研究成果归工作链路，不在此重复计数。

## 统计口径与验证范围

- 13 项功能：**可用 4、条件可用 3、演示 6、未完成 0**。
- 另列 **4 项未完成延伸**，不把它们算作已拥有的能力。
- “可用”不自动意味着生产验收完成；下面逐项标明本地实现、本轮线上检查及既有验证的范围。
- “演示”表示内容是设计或原理表达，并非说查看器不能使用。完整模型、选择、环视等交互已实现，但不能据此宣称物理资产、实时信号或实际任务已绑定。
- 一个模型的零件、四座地标、五个数据中心层级不拆成独立功能；同一能力的多个快捷入口也不重复计数。
- 本轮实际执行 `moon -C src/ui/landmark-studio test`：**19/19 通过**，有既有 `to_json` 弃用警告。没有重新运行全部 Rabbita 测试；对相关测试文件做了只读检查。
- 主审计本轮在 8443 线上只读确认：`?layer=compute` 有统一 3D viewport、Trial 01/02 未观测状态、位置未绑定说明、报告和 Advanced。没有借此确认真实账户隔离、机器指标、物理位置、报告下载或实际执行。
- 其他历史浏览器验证引用自项目记录，不能冒充本轮重新验收。

## 功能—入口—完成度清单

| ID | 功能 | 入口 | 状态与验证范围 | 真实边界／缺口 | 建议归属 |
| --- | --- | --- | --- | --- | --- |
| S01 | 小镇地图浏览、视察、缩放与空间入口 | `/moontown/` 地图；视察工具；点击建筑／地标 | **可用 · 本地实现及既有浏览器验证**；本链本轮做源码核对 | 地图是设计与地理校准表现，不是测绘精度地图；桥梁有展示比例调整 | 主界面保留地图和对象选择；校准参数放开发者工具 |
| S02 | 室外 → 室内 → 地下 → 原空间往返 | 建筑进入；室内“地下”；地下“返回”；`?layer=indoor&building=policy-hall`、`?layer=compute` | **可用 · 本地实现及既有链路验证**；本轮线上只读确认地下统一入口 | 同一 shell 维护选择与工作上下文；地下可返回原楼。相机与深度是同页面会话记忆，不承诺刷新后恢复 | 保留主路径；多个快捷入口不算多个功能 |
| S03 | 语义室内：家具／工作位选择、居民位置、楼内工作查看 | 各语义建筑室内，点家具或对象列表；右侧楼内工作 | **条件可用 · 本地实现**；本轮模型测试通过，真实工作需有效运行投影 | 家具 ID 对应 `InteractionSlot`，人物来自 slot presence；布局仍是示意，不能宣称真实建筑测绘。楼内工作不是另一套任务系统 | 保留选中对象和当前工作；居民总表、来源放高级 |
| S04 | G 座三层参考室内方案浏览 | 地标 → 未来中心 → 室内；`?layer=indoor&building=future-center-g3` | **演示 · 设计工具本地可用**；本轮模型测试、既有浏览器验证 | 完整参考图纸模型、14 个可选区；未绑定实际居民或任务，不是政策馆的第二套实现 | 命名为“未来中心 G3 · 设计方案”，保留完整模型 |
| S05 | 四座地标全角度 3D 建筑审阅 | 地图“地标” → 3D；`landmark-studio/index.html#center`、`#vision`、`#east-bridge`、`#arch-bridge` | **演示 · 设计工具本地可用**；本轮模型测试、既有浏览器验证 | 原始几何、环境、光照、环视、预设视角、图库保留；不是竣工 CAD。地图投影与查看器消费同源模型 | 地标卡保留“3D”；光照、白模、参考图库等进入审阅高级选项 |
| S06 | 算力中心五级 3D 浏览与部件查看 | 镇务 → 算力／室内电梯；园区 → 机房 → 机柜 → 服务器 → 主板 | **演示 · 本轮线上只读确认地下 viewport 可打开**；五级与部件能力由本地实现、模型测试和既有浏览器记录支持 | 柜号与 U 位保留导航上下文；CPU、存储、NIC、风扇等可选。真实机器作为独立逻辑端点，不对应设计柜 | 保留逐级进入与面包屑；不可为了视觉融合伪造真实节点位置 |
| S07 | 信号／供电／冷却原理动画与散热器拆解 | 地下 3D → Advanced → 信号／供电／冷却／播放；服务器或主板层拆解滑块 | **演示 · 本地实现及既有交互验证**；本轮未播放全部路径 | 路径由模型作者定义，不是实时数据包、电流或传感器；默认不播放，尊重 reduced-motion | 继续放高级，命名“原理演示” |
| S08 | 空间／接入快照报告与 JSON 导出 | 室内／地下工具栏“报告”图标 | **条件可用 · 本地实现**；本轮线上确认报告入口，未验证下载完成 | 报告保留对象、work/request、源快照时间；机器字段取决于接入快照，未上报留空。JSON 下载代码存在，不等于本轮下载验收 | 一个报告入口；默认摘要，ID、请求和原始字段放高级 |
| S09 | 机房容量与功率情景估算 | 空间报告 → Advanced · 规划估算；独立数据中心报告 | **演示 · 本地确定性计算可用**；本轮模型测试通过 | 计算机柜、服务器、U 位与假设功率，不含设施总能耗；不能称实时利用率或 PUE | 高级 → 规划估算；与观测快照分栏、分名 |
| S10 | 地标之间步行／过桥预览 | 地标 → 高级 → 起终点 → 演示步行／过桥；暂停／继续／结束 | **演示 · 本地实现及既有浏览器验证**；本轮未重新走完整路线 | 使用 OSM 节点拓扑并判断断路，不画跨水直线；停靠附近路节点，不声称已验证实际门连接。与权威工作 Agent 图分离 | 留高级或演示模式，持续显示“导航预览” |
| S11 | 运行 Agent 跨楼移动、到门与入室的可视化 | 地图 live Agent；楼内居民／工作；点击角色 | **条件可用 · 本地实现与既有回归测试**；本轮未产生真实工作 | 仅接受 live snapshot；使用 Place → portal → pedestrian graph，缺路为 unreachable。移动是运行证据的空间呈现，不是实际服务器或真人定位 | 归入同一“工作追踪”的地图表现；与演示 walker 保持标签区别 |
| S12 | 本地小镇建设：道路、绿化、建筑、拆除和保存 | 地图底栏“铺路”“造林”“创新工坊”“扩建” | **可用 · 本地沙盒实现及既有测试**；本轮未修改地图 | typed WorldDelta 有版本、操作和 digest，使用本地保存；不是现实城市施工或平台资源开通 | 面向治理用户时收进统一“布局编辑”模式，编辑时才显示工具、花费与拆除 |
| S13 | Map Lab 语义地图诊断 | 镇务 → 高级 → 地图诊断；Shift+M | **可用 · 本地只读诊断实现及既有测试**；本轮核对入口与样式 | 查看 StableId、来源、地块、道路、入口、活动、校验和拒绝；不是编辑器。旧独立 ML 启动器已经隐藏 | 保持高级，可进一步标为“开发者诊断” |

### 逐项实现证据

| ID | 源码、测试或记录 |
| --- | --- |
| S01 | [地图投影归属](../town-landmark-integration.md#L49)、[展示比例校准](../town-landmark-integration.md#L173)、[视察工具](../../../src/ui/rabbita-town/main/viewport_energy_valley_golden.mbt#L448) |
| S02 | [室内电梯](../../../src/ui/rabbita-town/main/building_interior_layer.mbt#L142)、[室内渲染入口](../../../src/ui/rabbita-town/main/building_interior_layer.mbt#L178)、[地下与返回](../../../src/ui/rabbita-town/main/secret_compute_room.mbt#L608)、[三层回程测试](../../../src/ui/rabbita-town/main/spatial_layer_journey_wbtest.mbt#L2) |
| S03 | [语义 slot 与人物 payload](../../../src/ui/rabbita-town/main/spatial_scene.mbt#L210)、[楼内工作](../../../src/ui/rabbita-town/main/building_interior_layer.mbt#L40)、[在场来源](../../../src/ui/rabbita-town/main/building_interior_layer.mbt#L99)、[家具身份测试](../../../src/ui/landmark-studio/src/models/town_interior_test.mbt#L2) |
| S04 | [独立参考室内路由](../../../src/ui/rabbita-town/main/spatial_scene.mbt#L251)、[14 区与未绑定说明](../town-landmark-integration.md#L130) |
| S05 | [查看器功能与边界](../../../src/ui/landmark-studio/README.md#L38)、[外观审阅弹层](../../../src/ui/landmark-studio/web/town-map.js#L80)、[完整模型保留](../town-landmark-integration.md#L5) |
| S06 | [模型数据选择](../../../src/ui/landmark-studio/web/town-space.js#L145)、[五级面包屑](../../../src/ui/landmark-studio/web/town-space.js#L182)、[逻辑端点列表](../../../src/ui/landmark-studio/web/town-space.js#L204)、[设计柜与机器边界](../town-landmark-integration.md#L133) |
| S07 | [高级流与拆解控制](../../../src/ui/landmark-studio/web/town-space.js#L67)、[原理路径范围](../datacenter-threejs-study.md#L24) |
| S08 | [空间报告与导出](../../../src/ui/landmark-studio/web/town-space-report.js#L3)、[报告上下文](../../../src/ui/landmark-studio/web/town-space.js#L434) |
| S09 | [高级规划估算](../../../src/ui/landmark-studio/web/town-space-report.js#L26)、[计算公式与不包含项](../datacenter-threejs-study.md#L75) |
| S10 | [步行结果与状态](../../../src/ui/landmark-studio/web/town-map.js#L91)、[高级步行控件](../../../src/ui/landmark-studio/web/town-map.js#L103)、[路线证据与边界](../town-landmark-integration.md#L70) |
| S11 | [语义道路查询](../../../src/ui/rabbita-town/main/runtime_agent_map_interaction.mbt#L69)、[到达／入室生命周期](../../../src/ui/rabbita-town/main/runtime_agent_map_interaction.mbt#L198)、[live 门槛](../../../src/ui/rabbita-town/main/runtime_agent_map_interaction.mbt#L266)、[对应路径测试](../../../src/ui/rabbita-town/main/runtime_agent_map_interaction_wbtest.mbt#L285) |
| S12 | [建设工具栏](../../../src/ui/rabbita-town/main/viewport_energy_valley_golden.mbt#L407)、[typed WorldDelta 操作](../../../src/ui/rabbita-town/main/energy_valley_world_delta_save.mbt#L57)、[本地存储](../../../src/ui/rabbita-town/main/browser_energy_valley_preferences.mbt#L23) |
| S13 | [Map Lab 只读面板](../../../src/ui/rabbita-town/main/map_lab.mbt#L1677)、[高级入口](../../../src/ui/rabbita-town/main/energy_valley_page.mbt#L576)、[隐藏旧启动器](../../../src/ui/rabbita-town/styles/energy-valley-life-hud.css#L993) |

## 未完成延伸：不计为已拥有功能

| ID | 状态 | 缺口 | 用户影响与证据 |
| --- | --- | --- | --- |
| SU01 | **未完成** | 设施 → 房间 → 机柜 → U 位 → 实际机器／主板资产映射 | 目前报告固定 `physical_mapping:'unassigned'`，真实节点只是逻辑端点；不能点真机高亮真实机柜，也不能宣称完整数字孪生。[报告契约](../../../src/ui/landmark-studio/web/town-space.js#L438) |
| SU02 | **未完成** | 单项任务／Run → MoonGate 路由 → 实际机器的可验证追踪 | “查看算力”只能显示可用资源，不能确定所选工作在哪台机器执行。当前代码明确披露此缺口。[工作与执行记录](../../../src/ui/rabbita-town/main/spatial_work_journey.mbt#L123) |
| SU03 | **未完成** | 真实功耗、温度、吞吐、风扇、水冷、BMC、网络计数器与历史曲线 | 当前报告显示暂无实测；信号动画和功率估算不能代替传感器。[报告缺失字段](../../../src/ui/landmark-studio/web/town-space-report.js#L20)、[现有观测边界](../datacenter-threejs-study.md#L53) |
| SU04 | **未完成** | 地标／桥梁预览图与业务 Agent 权威路径统一，实际门连接验证 | 地标路线不替代 `CompiledTownWorld`；预览过桥成功不等于真实工作 Agent 跨地标闭环验收。[地标寻路未接入范围](../town-landmark-integration.md#L87) |

## 重复、合并与高级收纳建议

### P1：室内／地下生产双方案已经合并，不应再重复重建

室内和地下分别调用同一个空间 stage：[室内](../../../src/ui/rabbita-town/main/building_interior_layer.mbt#L206)、[地下](../../../src/ui/rabbita-town/main/secret_compute_room.mbt#L653)。[回归测试](../../../src/ui/rabbita-town/main/spatial_layer_journey_wbtest.mbt#L38)明确要求 `town-space-host`，并禁止旧 `indoor-world-canvas` 和 iframe。

外观建筑审阅仍使用 modal iframe，这是外观设计工具，不是旧室内生产应用。G3 和数据中心独立审阅链接已经在[空间高级区](../../../src/ui/landmark-studio/web/town-space.js#L96)，语义室内不显示该独立链接。应保留源模型与审阅工具，不再把它们统计为另一套生产空间。

### P1：合并信息归属，但不能把设计模型强行绑定真实事实

地下设计对象与真实端点已能切换同一右侧 inspector。下一步需要 SU01、SU02 的证据契约，而不是把真实机器标签贴进任意设计柜。“设计模型”“位置未绑定”“未观测”属于必要状态，应保留简短标识；说明正文可进高级。

### P2：报告数据模型可合并，用户入口保持一个

生产空间使用 [town-space-report.js](../../../src/ui/landmark-studio/web/town-space-report.js#L3)，独立设计工具使用 [datacenter-reports.js](../../../src/ui/landmark-studio/web/datacenter-reports.js)。前者侧重当前对象／工作上下文与 JSON；后者有更多规划、CSV、打印能力。

建议共用报告 schema、格式器和导出器，保留生产摘要与专业审阅两种密度。不再新增平级报告入口；独立 Studio 继续放高级。

### P2：两套导航用途不同，应统一基础接口而非混淆状态

S10 是地标试玩导航，S11 是运行证据的空间投影。它们是实际存在的底层双轨，可以逐步共用路径查询和绘制组件，但“导航演示”和“运行记录”必须分开标注。不能把演示角色过桥当成真实任务执行成功。

### P2：建设工具收进单一布局编辑模式

[当前工具栏](../../../src/ui/rabbita-town/main/viewport_energy_valley_golden.mbt#L407)将视察、铺路、造林和工坊视为四个日常操作。对治理用户，建设编辑不是日常处理事项的主路径。建议保留能力，但切入“布局编辑”后才显示建造、花费和拆除；普通模式只保留浏览与业务入口。

### P2：高级名称和内容类型统一

地标使用“高级”，共用空间使用 `Advanced`，报告使用 `Advanced · 规划估算`。建议统一本地化为“高级”；内容分别命名“设计方案”“原理演示”“接入快照”“规划估算”，避免都叫“统计”或依靠长段边界说明区分。

### P2：历史文档需注明已被新集成状态取代

[数据中心旧说明](../datacenter-threejs-study.md#L6)和 [G3 旧说明](../wenyu-g3-interior-study.md#L5)仍写尚未整合；[Studio README](../../../src/ui/landmark-studio/README.md#L67)写 vendor 仅被独立 viewer 使用，也已落后于共享空间 renderer。

最新空间事实以 [2026-10-23 统一集成说明](../town-landmark-integration.md#L117)和当前源码为准。后续维护应给旧文档加“历史阶段”标识与最新入口链接，而非据旧文字重复开发。

## 不重复计数的开发能力

本链没有找到名为 `world-assets` 的独立用户页面。资产源代码、几何构建、打包、地图校准属于开发流程。[editor-pipeline 命令](../../../src/cmd/main/planning_commands.mbt#L35)是 PlanBook → MoonClaw 的实现闭环；[对应面板](../../../src/ui/rabbita-town/main/viewport_editor_pipeline.mbt#L76)展示开发状态，不是可视地图编辑器。此能力由开发／运维链路归档，本链不重复计入。

## 后续维护规则

- 状态升级须补充明确验收环境与证据日期；本地测试、线上只读可见、真实业务闭环分别记录。
- 补 SU01 或 SU02 时保留稳定对象 ID、观测时间、来源和缺失状态，不由空间邻近关系推导真实绑定。
- 保留现有完整模型与画风；优先统一入口、选择状态、报告与术语，而非删除专业能力。
- 把新增快捷入口关联到既有 S 编号，不因按钮数量增加而扩大功能总数。
