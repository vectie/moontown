# 材料、分析与知识候选链路审计

审计日期：2026-10-26。范围：材料导入后的浏览与分析、材料笔记与监测、Pack 观察到候选、知识目录、模板、PDF 研究、课程和质量检查。

本轮先完成只读源码与文档审计，再按要求保存本清单；没有执行业务写入命令、修改产品代码、重新运行测试或自行操作线上账户。引用的测试结果是仓库已有验证记录，不等于本轮验收。

## 统计口径与交叉引用

- 本页包含 **23 个盘点项**，不代表 23 个独立、已上线产品功能。筛选、分页和多个导出格式不分别计数。
- **K11 与研究链路 R01 的关注能力是同一功能**，本页补充本地材料模式，汇总时不双计。
- **K19 包含研究链路 R02 的同一资料研究创建入口**，汇总时不双计。
- K19“创建/安装”与 K20“执行 PDF 证据流程”保留为不同验收阶段：建册成功不等于 PDF 提取、研究和验收成功。汇总总数应称“盘点项”，不能直接称全部独立可用功能数。
- 状态分为：**可用（本地）11 项、条件可用 11 项、演示/脚手架 1 项、未完成 0 项**。另外列出 **8 个明确缺口**，不额外冒充已有能力。
- “可用（本地）”表示已有实际实现、入口及局部验证记录，不表示本轮重新验收。“条件可用”需要已导入 Book、配置好的宿主/Pack/守护进程/执行后端。
- 本链路不能仅凭源码标为“8443 全流程已验收”。主审计在公共 `/moontown/` 实际复现 **Pack Bridge unavailable (404)**，所以 K12–K17 在公共入口当前不可用。

## 功能—入口—完成度—处置清单

| ID | 功能与实际范围 | 当前入口 | 状态与缺口 | 建议 | 证据 |
| --- | --- | --- | --- | --- | --- |
| K01 | 已导入成果浏览、原文及精确文件下载 | 镇务 → 成果 → Book → output → included file；API `api/imported-outputs` | **条件可用**：先经 MoonBook portable workflow 导入；这个抽屉不是上传/导入器。有来源校验，公网全流程未验收 | 保留“成果”；哈希、manifest、pins 放来源详情 | [入口](../../../src/ui/rabbita-town/main/energy_valley_page.mbt#L480)、[抽屉](../../../src/ui/rabbita-town/main/imported_outputs_view.mbt#L11)、[宿主适配](../../../src/cmd/desktop_server/imported_output_api.mbt#L4)、[输入前提](../../IMPORTED_DATA_TABLES.md#L3) |
| K02 | CSV/TSV 搜索、列筛选、排序、列选择、分页、筛选结果导出 | 成果 → CSV/TSV → Table view；CLI `src/cmd/table_view` | **可用（本地）**：内容是文本，ASCII 大小写折叠、UTF-16 排序；不是类型化电子表格、公式编辑器或持久查询；有大小/行数限制，宿主需有资料 | 一个“表格”功能；默认表与搜索，精确匹配和导出列配置放 Advanced | [状态与算法调用](../../../src/ui/rabbita-town/main/imported_outputs_table_view.mbt#L40)、[控件](../../../src/ui/rabbita-town/main/imported_outputs_table_view.mbt#L117)、[边界](../../IMPORTED_TABLE_VIEWS.md#L17) |
| K03 | CSV/TSV 坐标列映射为地点，保留原始行列 | 成果 → 表格 → Explore table as places；CLI `places_export` | **可用（本地）**：显式选择经纬度、名称、分类列；不地理编码、不猜坐标系、不保证人为映射正确 | 合并为资料的“地图视图”，按格式出现，不设顶层入口 | [UI](../../../src/ui/rabbita-town/main/imported_outputs_places.mbt#L84)、[流程与 CLI](../../IMPORTED_TABLE_PLACES.md#L3) |
| K04 | GeoJSON 点、路线、多边形浏览、搜索、选择、坐标示意及导出 | 成果 → GeoJSON → GeoJSON places and routes；CLI `geo_export` | **可用（本地）**：平面经纬度示意、北朝上，无底图/真实导航/日期变更线处理；不是小镇地图编辑 | 与 K03 共用“地图”工具，保留数据语义 | [投影示意](../../../src/ui/rabbita-town/main/imported_outputs_geo.mbt#L185)、[UI](../../../src/ui/rabbita-town/main/imported_outputs_geo.mbt#L299)、[边界](../../IMPORTED_GEOJSON_EXPLORER.md#L49) |
| K05 | 同一 GeoJSON 内按 Polygon 查区内地点 | K04 → Find places in a zone；CLI `geo_export … --within N` | **可用（本地）**：简单 Polygon/洞与 Point membership；不支持 MultiPolygon，不是法定边界/测绘结论 | K04 的 Advanced“区域筛选”，不独立成产品 | [控件](../../../src/ui/rabbita-town/main/imported_outputs_geo_zones.mbt#L2)、[流程与边界](../../IMPORTED_GEOJSON_ZONES.md#L7) |
| K06 | 独立表格与独立区域文件的空间关联报告 | **仅 CLI/API**：`table_zones TABLE.csv ZONES.geojson LAT LON NAME CATEGORY geojson\|csv` | **可用（本地）**：UI 未接通，抽屉一次仍只读一个文件；字节摘要不是 Book 认证；不是 live GIS | 专业 Advanced；未来并到 K04“区域关联”，不新增地图页面 | [明确无 UI](../../TABLE_ZONE_JOIN.md#L9)、[命令](../../TABLE_ZONE_JOIN.md#L19)、[实现入口](../../../src/cmd/table_zones/main.mbt) |
| K07 | ICS 日程源浏览、搜索、日期/地点筛选、选中行程导出 | 成果 → `.ics` → Calendar agenda | **可用（本地）**：只读源；无订阅、邀请、提醒、同步，TZID/浮动时间保留原样 | 保留“日程视图”；原始 ICS 与技术字段解释放 Advanced | [UI](../../../src/ui/rabbita-town/main/imported_outputs_agenda.mbt#L253)、[操作](../../IMPORTED_CALENDAR_AGENDA.md#L9)、[限制](../../IMPORTED_CALENDAR_AGENDA.md#L37) |
| K08 | 有限日期窗口内展开重复日程 | K07 → 选择源事件 → 日期窗口 → Expand selected source entries；CLI `calendar_itinerary` | **可用（本地）**：DAILY/WEEKLY、UTC/全天、COUNT/UNTIL/EXDATE；无 BYDAY、DST、覆盖/取消合并，不是完整日历引擎 | K07 内“展开重复事件”，相关控件按需出现 | [实际展开](../../../src/ui/rabbita-town/main/imported_outputs_agenda.mbt#L115)、[支持范围](../../RECURRING_CALENDAR_ITINERARY.md#L61) |
| K09 | 选中 occurrence 的 UTC 重叠检查 | K08 → Selected occurrence overlap review；CLI `calendar_itinerary … overlaps` | **可用（本地）**：只比选中且有结束时间的 UTC 事件；全天/未知时长不评估；不是个人空闲、预订或冲突解决 | 并到 K07“检查重叠”；摘要直接显示，详细对比按需展开 | [UI](../../../src/ui/rabbita-town/main/imported_outputs_agenda.mbt#L447)、[含义与覆盖](../../CALENDAR_OVERLAP_REVIEW.md#L25) |
| K10 | 本地材料笔记：跨 Book 搜索、上下文、按行摘录、观察/质疑修订、保存协作草稿 | **主要 CLI** `material_notebook import/find/read/context/select/remove/revise/save`；保存后协作 → 载入 Books/草稿 → 准备导出 | **可用（本地）**：前半段无图形材料浏览器；需要 JSON、至少两个 Book、人工问题/反证/负责人；不自动研究或执行 | 合并进协作的“选择资料”；CLI/原始 JSON 留开发者，摘录/上下文不另起产品 | [CLI](../../../src/cmd/material_notebook/main.mbt#L13)、[保存后 UI](../../MATERIAL_NOTEBOOK.md#L78)、[上下文](../../MATERIAL_NOTEBOOK.md#L87)、[边界](../../MATERIAL_NOTEBOOK.md#L137) |
| K11 | 本地材料变化关注：静默建基线，字节变化触发现有工作流 | 请求台 → 关注 → 本地资料 → Book/相对路径 → 保存 Watch | **条件可用；与 R01 同一能力，不双计**：保存不启动 daemon、不建立基线；需真实周期、MoonClaw、Book review；生产长期运行未验收 | 与普通关注合并，用来源区分；path/hash/journal/retry 进 Advanced | [模式](../../../src/ui/rabbita-town/main/viewport_material_watch_form.mbt#L2)、[字段](../../../src/ui/rabbita-town/main/viewport_material_watch_form.mbt#L49)、[运行边界](../../LOCAL_MATERIAL_WATCH.md#L60) |
| K12 | Domain Pack 图层、观察、候选流浏览 | 镇务 → Advanced 工具与维护 → 扩展工具 → Domain layers；旧文档称 Pack layers | **条件可用；公共 8443 已复现 404**：本地需配置 Pack；引用路径不自动读正文，操作可见不等于可执行 | 放研究工作台“领域资料”；无连接只显示简短状态及转工作区动作 | [当前菜单](../../../src/ui/rabbita-town/main/energy_valley_page.mbt#L613)、[面板](../../../src/ui/rabbita-town/pack_bridge_panel.js#L350)、[权责](../PACK_TOWN_BRIDGE.md#L7) |
| K13 | 从所选观察提交领域候选，来源绑定、同身份重试、pending receipt | K12 → Use as proposal source → Propose from N sources → Submit for review；`/api/pack-bridge/candidates` | **条件可用；公共未接通**：native mailbox 实现存在；仅 pending intake，不执行 operation、不接受 Book truth；重载不恢复未知 POST | 与 K14–K17 共用“提出问题/建议”；operation/JSON/schema 进 Advanced，来源/问题/下一步直接显示 | [统一 composer](../../../src/ui/rabbita-town/pack_bridge_panel.js#L383)、[native intake](../../../src/cmd/desktop_server/pack_bridge_api.mbt#L27)、[边界](../../SOURCE_LINKED_PACK_CANDIDATES.md#L60) |
| K14 | 相同材料引用分组，人工挑选/假设后转候选 | K12 → Shared-material groups → Review shared material → Continue to proposal | **条件可用；公共未接通**：仅精确 `(pack_id,evidence_ref)`，不读文件、不跨 Pack 合并同名路径，不证明独立证据 | K13“找资料 → 相同来源”模式，不并排铺长表单 | [共用入口](../../../src/ui/rabbita-town/pack_bridge_panel.js#L399)、[流程](../../SHARED_MATERIAL_GROUPS.md#L9)、[边界](../../SHARED_MATERIAL_GROUPS.md#L66) |
| K15 | 跨 Pack 问题草稿：支持/质疑/背景角色、适用条件、下载恢复、候选转交 | K12 → 至少两个 Pack 的观察 → Compose cross-pack question | **条件可用；公共未接通**：可携带的是未发送草稿；不自动综合、判矛盾、接受知识 | K13“跨领域”模式；与协作统一前台编辑体验，保留 Pack intake/Book execution 后端权责 | [UI](../../../src/ui/rabbita-town/pack_question_composer.js#L27)、[流程](../../CROSS_PACK_QUESTIONS.md#L11)、[持久化边界](../../CROSS_PACK_QUESTIONS.md#L67) |
| K16 | 观察基线保存/导入、前后差异、所选变化转候选 | K12 → What changed since your last visit? | **条件可用；公共未接通**：人工文件保存/导入、内存一份；不是常驻监测/提醒；历史内容未签名认证 | K13“查变化”模式；不默认铺开，baseline 文件/字段差异技术细节 Advanced | [UI](../../../src/ui/rabbita-town/pack_observation_review.js#L26)、[操作](../../OBSERVATION_BASELINES.md#L11)、[非 watch 边界](../../OBSERVATION_BASELINES.md#L80) |
| K17 | 跨 Pack 词汇连接发现、ANY/ALL lens、匹配转候选 | K12 → Discover words connecting different packs | **条件可用；公共未接通**：title/summary 词汇检索，不是语义关联；连续中文文本视为一个词 | K13“找相关资料”的 Advanced 检索模式，不称智能研究产品 | [算法](../../../src/ui/rabbita-town/pack_vocabulary.js#L51)、[接入](../../../src/ui/rabbita-town/pack_bridge_panel.js#L412)、[语言限制](../../VOCABULARY_DISCOVERY.md#L65) |
| K18 | 建筑关联领域目录、已有研究成果、政策/审阅/生成状态 | 点击注册建筑 → 研究成果；Advanced → 专题目录与运行规则；CLI `knowledge catalog/status/seed` | **可用（本地）**：目录不是资料，projection 不是接受；seed 先建缺失配置、来源齐备才排队；生产研究闭环未验收 | 保留建筑内成果；目录、规则、tier、ID 维持 Advanced，与成果抽屉共用浏览组件 | [成果与目录](../../../src/ui/rabbita-town/main/knowledge_domain_inspector.mbt#L218)、[CLI](../../../src/cmd/main/knowledge_commands.mbt#L2)、[真实性规则](../../KNOWLEDGE_TOWN_ARCHITECTURE.md#L179) |
| K19 | 模板化建册、安装请求、安装/失败状态 | 请求台 → 研究 → 创建研究（PDF 模板）；CLI `books templates/template install/template requests …` | **条件可用；含 R02 同一创建入口，不双计**：实际 installer 为 `pdf-evidence-watch`、`app-tool-book`；不是全部册类型通用向导 | 前台“创建研究”；自动生成 Book ID，template/config/ledger 进 Advanced；保留与 K20 不同验收阶段 | [UI](../../../src/ui/rabbita-town/main/viewport_book_template_requests.mbt#L2)、[实际 installers](../../../src/book_templates_runtime/installers.mbt#L7)、[CLI](../../../src/cmd/main/book_commands.mbt#L7) |
| K20 | PDF 证据监测执行：站点→PDF→提取/OCR→分析→review→知识变化；停止/归档 | K19 配置；CLI `books pdf-watch bootstrap/install/status/archive`，执行复用 standing goals | **条件可用**：安装建 workspace/goal；提取/OCR/分析依赖 worker prompt、工具及 review，未证明任意网站全流程。archive 是隐藏册/停用 goal，不是 PDF 文件仓库 | “资料研究”的来源类型和生命周期；站点/目的/结果主显，提取策略/周期/审计 Advanced | [goal 与执行要求](../../../src/pdf_evidence_watch/standing_goal.mbt#L2)、[具体 prompt](../../../src/pdf_evidence_watch/standing_goal.mbt#L51)、[归档语义](../../../src/pdf_archive_runtime/archive_command.mbt#L2) |
| K21 | Wenyu 入门课程知识册：课程、练习、进度 rubric、静态课程页 | CLI `course wenyu-game-design bootstrap/status`；生成 `book/Home.html`/MoonBook 链接；编辑器显示 course ref | **演示/脚手架**：课程内容生成器本地可用；作为完整学习产品，未见学生进度保存、答题评分和个性学习 UI | 放 AI 花园/知识内容内，不独立主入口；不得标为已完成学习管理系统 | [CLI](../../../src/cmd/main/planning_commands.mbt#L49)、[实际生成内容](../../../src/course_book_runtime/bootstrap.mbt#L18)、[静态页面](../../../src/course_book/projection_content.mbt#L35) |
| K22 | 知识册结构健康检查：契约、skill、projection、workspace、服务证据 | CLI `books doctor/quality`；audit JSON/Markdown | **可用（本地）**：确定性结构检查，不是内容质量分；doctor 会写文件/补默认 operational books，本次未运行 | 管理员/开发者 Advanced；普通用户只看阻止下一步的问题 | [CLI](../../../src/cmd/main/book_commands.mbt#L4)、[写入及含义](../../../src/book_quality_runtime/book_quality_audit_io.mbt#L2)、[说明](../../../README.mbt.md#L399) |
| K23 | AI 语义质量评审→修复任务→standing goal→达标退役 | CLI `books ai-review-packets/ai-review --dispatch/ai-review bridge/status`；daemon `review-book-quality` | **条件可用**：依赖 MoonClaw provider/Book review；有去重、结果和修复桥；不等于知识自动正确或真人验收 | 普通用户看待审阅/需修订/已接受及动作；packet/ledger/orphan/repair-score 管理员 Advanced | [CLI](../../../src/cmd/main/book_commands.mbt#L20)、[调度实现](../../../src/book_quality_runtime/book_quality_review_dispatch.mbt#L2)、[修复闭环说明](../../../README.mbt.md#L447) |

## 八个明确缺口

这些是现有能力边界，不另外计入“已有功能”。

1. **通用上传→浏览→选段→研究一体化 GUI**：成果抽屉只浏览已导入 MoonBook，材料选段仍 CLI/JSON。[来源](../../MATERIAL_NOTEBOOK.md#L9)
2. **表格—区域两文件关联 GUI**：K06 只有 CLI/API。[来源](../../TABLE_ZONE_JOIN.md#L9)
3. **完整日历服务**：无订阅、写回、RSVP、提醒、通用时区/覆盖规则、个人 free-busy。[来源](../../IMPORTED_CALENDAR_AGENDA.md#L37)
4. **自动语义关联、独立佐证和自动知识接受**：Pack 分组、词汇和变化只是导航与人工候选，不能提升成这些能力。[来源](../../VOCABULARY_DISCOVERY.md#L65)
5. **通用课程学习平台**：课程内容生成存在，学生学习闭环未见。[生成范围](../../../src/course_book_runtime/bootstrap.mbt#L18)
6. **所有类型 Book 的统一创建向导**：installer 有限，研究 UI 当前是 PDF-specific。[实现](../../../src/book_templates_runtime/installers.mbt#L7)
7. **PDF 提取/OCR 全流程稳定生产服务的验收**：代码定义目标和依赖，prompt 不是执行证据。[执行要求](../../../src/pdf_evidence_watch/standing_goal.mbt#L51)
8. **Pack 工具公共生产入口**：主审计实际复现 404，本地实现不能抵销线上不可用。

## 重复入口与合并建议

### 五种找资料方法不应表现为五个产品

手选资料、共用材料、跨 Pack 问题、历史变化、词汇发现都进入同一个 `openCandidate` / `candidateDialog`，但面板把这些 section 一起挂出。[共用转交实现](../../../src/ui/rabbita-town/pack_bridge_panel.js#L383)、[并排挂载](../../../src/ui/rabbita-town/pack_bridge_panel.js#L416)。

建议统一为“提出问题”：选择资料（浏览/相关词/相同来源/最近变化）→写问题→提交审阅。保留方法，仅在需要的步骤出现，不删除分析能力。

### Collaboration 和 Pack question 统一前台，但不抹掉权责

两边都编辑问题、来源、反证/质疑、可携带草稿。区别是 Collaboration 绑定 Book 文件并可能进入 participant work，Pack candidate 只进入领域 mailbox，无执行/接受 Book truth 权限。

建议共用“问题+资料”编辑体验，最后明确“组织协作 / 提交领域建议”，保留后端权限及持久化协议。不能因为 UI 相似就删除安全边界。[Pack 边界](../../SOURCE_LINKED_PACK_CANDIDATES.md#L60)、[材料到协作草稿](../../MATERIAL_NOTEBOOK.md#L78)。

### 三种变化共享工作区，不混淆自动与手动

普通 cadence watch、本地字节 watch、手动 Pack baseline comparison 可进入“关注与变化”工作区。但 baseline comparison 不是后台 watch，必须区分“自动检查 / 手动对比”。[本地监测](../../LOCAL_MATERIAL_WATCH.md#L3)、[手动基线边界](../../OBSERVATION_BASELINES.md#L80)。

### 导出是上下文动作，不是新入口

CSV、GeoJSON、Markdown、精确原始文件各有用途，但可用统一“导出”菜单：先区分“原始文件 / 当前选择”，下一层选格式。避免格式按钮占满主流程。[原始与派生导出](../../IMPORTED_DATA_TABLES.md#L15)。

### 四种资料来源共用浏览框架

建筑研究成果、镇务成果、材料 notebook、Pack projection 可共享“资料”浏览框架，区分已有成果/本地资料/领域观察。不要强行合成一个数据库；来源真实性、权限与选择状态仍由各自合同负责。[建筑成果](../../../src/ui/rabbita-town/main/knowledge_domain_inspector.mbt#L218)、[成果抽屉](../../../src/ui/rabbita-town/main/imported_outputs_view.mbt#L11)。

## Advanced 与默认展示边界

**适合放 Advanced：** template/Book ID、schema/version、manifest/digest、source path、request identity、domain JSON；词汇 lens 的 ANY/ALL/ignored words；baseline 文件操作；导出列投影；Polygon 技术限制；原始文本；cadence、quality threshold、review chain。

**应留在当前主流程：** 已选资料、来源变更/不可用；草稿/待审阅/已接受状态；保存/提交/修订/下载下一步；未知提交结果的“检查结果/重试同一次”；阻止动作的缺权限/缺配置问题；公共演示与个人真实执行的区别。不能把用户必须处理的错误藏进 Advanced。

**开发者/管理员专属，不宜混入普通 Advanced：** bootstrap/doctor、手工 ledger、native packet、包注册与 installer 配置、source schema/protocol debug、orphan/repair 内部状态。`books doctor` 实际会写状态，不能因名称像诊断就当普通只读按钮。[实现](../../../src/book_quality_runtime/book_quality_audit_io.mbt#L2)。

## 已核对的入口与文案不一致

- 文档仍指示“Pack layers”，当前菜单是“扩展工具（高级）”，面板标题是“Domain layers”。[旧指引](../../VOCABULARY_DISCOVERY.md#L11)、[现 UI](../../../src/ui/rabbita-town/pack_bridge_panel.js#L350)。
- 研究工具内部仍有大量英文长句，与已中文短标签的小镇菜单不统一。
- Pack 面板仍硬编码根路径 `/api/pack-bridge`、`/api/pack-bridge/candidates`；成果抽屉已使用 `moontown_product_api_path(...)`。这使子路径部署不能凭本地测试判为可用。[Pack URL](../../../src/ui/rabbita-town/pack_bridge_panel.js#L10)、[成果 URL](../../../src/ui/rabbita-town/main/imported_outputs_effects.mbt#L53)。
- 主审计实际在公共 8443 打开扩展工具后得到 404，五组长表单、禁用按钮、无效 lens 红错却仍渲染。优先改为简短“该工作区尚未连接领域资料”及进入个人工作区动作；不要展示整屏不可用表单。

本页只给审计与重组建议，没有实施上述改动。
