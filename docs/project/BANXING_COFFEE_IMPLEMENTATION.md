# 半醒咖啡首期实施记录

更新：2026-11-07。首期页面已上线并接通 177 的真实出图。
外网：https://suanli.kechuangfuwu.com:8443/moontown/coffee-contest.html 。
计划周期保持用户确认的 2026-11-06 至 11-13；不能将计划开赛日期解释为已在 11-06 开放服务。
工作分支：`codex/banxing-coffee-week01`。

## 已实现

- 自有 `coffee-contest.html`：提示词起点、单图生成、私人预览与历史、主动投稿确认、
  过审作品墙、腾讯文档入口、主办审核/退回、固定版本导出、奖项记录与人工公布。
- Challenge/RubricCriterion 提取为轻量 `competition_brief`，原 hackathon 路径继续 re-export，
  每周创作沿用 Contest Express 的赛题概念；原数值评分赛事仍保留原有路径。
- `creative_contest`：持久文件锁与原子提交、用户配额/全场配额、一人一件有效投稿、
  投稿替换后重新审核、截止与投票窗口、自己不能批准自己、撤回后公共图片不可读。
- `account_gateway`：统一账户验证、账户切换一致性校验、Origin + JSON 防跨站写入、
  主办身份从已验证的 PlatformOperator 得出，不扩展旧操作员 gate 或私有工作区代理。
- 图片先在私人目录落盘；公开投影不包含提示词或内部账户 ID。去掉 PNG 的 prompt/workflow
  元数据，加入 AI 元数据；页面有 AI 标签，正常下载增加可见说明条与 AI 元数据。
- 轮询只重绘变化部分，不在状态未变时重新下载整面图片；后台页签停止轮询。
  账户变化时清理私人预览与输入，审核意见和未保存投票链接不会被正常刷新冲掉。
- LunaNexa 新增独立 `media/image/provider`、`media/image/service`、`cmd/image-adapter`。
  固定 Z-Image-Turbo graph，持久意图先于唯一的上游 POST；超时与丢响应只查历史/队列恢复。
  模型别名、节点、artifact、origin 和 profile 绑定到日志，不能默默把旧任务迁到另一运行时。
  适配器需要私有凭据、明确资格证据及总量限制；没有为生产伪造 approved 记录。

## MoonBook / MoonClaw

私人书：`/Users/kq/moonsuite/books/banxing-coffee-curator`，已登记现有 MoonTown 书目，
原书目录权限 0700。37 个原始文件逐字节导入，带 SHA256/size 清单。

可复用内容：品牌与视觉方法、首期运营方案、每周策展、待审事项、coffee-curator skill、
MoonClaw `coffee_curator` profile、合并式激活工具、首期配置和 ComfyUI 接入运行说明。
策展 agent 起草内容，人工决定批准、发布、奖品采购与开奖；未创建自动付费模型任务。

完整原稿在原书 `raw/curation/`。可移植媒体经 MoonBook 正式 outputs manifest 携带，
导入到 `portable/outputs/coffee-curation-materials/`，技能提供该路径的回退。
编译缓存移出技能目录；激活时指定外部 `--target-dir`，避免把缓存带进下次导出。

最终可移植包：`/Users/kq/moonsuite/exports/banxing-coffee-curator-1.1.0.moonbook-agent`，
bundle digest `sha256:4c4ee1a279bfb9df109524b3c8146a8447d24b90c7a98efb842404d6eb2c6bf2`。
92 个文件校验通过；导入另一目录后 verify-import 无 changed_members，策展 profile 激活成功。
含带 AI 标识的真实出图样张，明确标注为私有验收作品；不含服务凭据、生产投稿或编译缓存。

## 验证

- MoonTown 全量 native：2035/2035；创作包 9/9，包含只 GET 恢复、失败不重置全场消耗上限和预览投票。
- 原界面全部 194 个测试文件、25 个批次已通过；浏览器源脚本：180/180。
- 独立 gateway 依赖闭包：8/8，包括实际 HTTP 的 A/B 隔离、普通账户、审核与撤回。
- LunaNexa 图片 provider/service：2 个针对测试通过，含丢失 Comfy 接受响应、重试不重发、
  重启恢复、总量上限和资格绑定不一致拒绝。其他 LunaNexa 正在进行的改动未被本任务覆盖。
- 桌面、375 手机和横屏验收；375 宽度实测 scrollWidth 等于 clientWidth。
- 浏览器私有联调使用真实 177 图片：A 生成/投稿 → B 看不到 → 主办批准 → B 看到 →
  A 撤回 → B 的公共图片请求 404，A 自己仍可读。页面明确标注隔离测试身份，未连接生产账户。
  另有 1 像素接口 fixture；它没有被当作真实出图证据。没有创建正式参赛作品、票数或获奖者。
- 实际下载为 1024×1084 PNG，含可见 AI 说明条和 AIGC 元数据；原始 prompt/workflow 元数据不进入公开文件。
- MoonBook 已做正式 bundle verify、导入到另一目录、verify-import 和 profile 激活验证。

构建兼容：gateway 使用 async 0.22.4，而根模块仍含旧 API。用
`scripts/stage-account-gateway.mbtx` 导出真实依赖闭包，并在独立工作区构建；
gateway 显式依赖 moonlib 0.1.23。不要为了构建 gateway 在原仓库批量改写无关包。

## 实际部署与容量边界

用户已授权将 Qwen 预留从 80% 下调至 55% 并短暂重启，现已执行。启动、加载和预热约 5 分钟。
仅 177 改为独立 time-slicing profile，逻辑 GPU=2；仍为同一块物理 GPU，内存和故障不隔离。
其他三台插件不变。ComfyUI 请求一个共享槽位，内存 requests=24Gi / limits=40Gi，并发 1。

固定 ComfyUI v0.33.2（`7cee3ceb1a35503172e0dfb8dbdbdedee2aba8aa`）；
模型 revision `6fc90a3b1b653e935a0d175e260736de25b84df5`，三份文件均按官方 blob SHA256 校验。
运行时镜像 `moon/comfyui-runtime@sha256:d215c569d3bcade249a4e28a8dd56bc45c355a0616d45b6ab5e99984e3702e65`。
依赖通过可达镜像源下载；模型镜像只作传输，校验仍用官方元数据。

实际固定工作流 1024×1024、8 步：首次模型加载并取图 18.169 秒，换 seed 热态 8.095 秒，
热态与 Qwen 并行 8.086 秒。同 seed 的约 2 秒结果是缓存命中，已排除。
文本在图像加载前预热后约 0.342–0.344 秒；实际热态并行约 0.667–0.698 秒，全部成功。
文本首个请求含预热约 16.48 秒；不能把后续短提示词结果推广为长上下文吞吐。
统一内存可用采样从约 44 GiB 到约 11.1 GiB，不是持续采集的峰值；仅完成小样本共存资格验证。

175 部署私有图片适配器、服务端凭据、资格文件及独立 8Gi 状态卷；177 只运行第三方模型。
ComfyUI 不通过公网入口开放。MoonTown 继续使用现有统一身份、主办角色和公共入口，新增独立 8Gi 创作卷。
外网 8443 页面/API/资源/投票预览返回 200；内网 443 从 175 按域名与有效证书访问也返回 200。
外网直接 443 不可达，不将其当作公网活动链接。无效统一身份会话预检返回预期 401。
正式网关 Pod 的网络命名空间中，受限的临时诊断容器运行原生
`scripts/verify-creative-provider.mbtx`，只读请求适配器 `/health` 成功。
该检查不读取服务凭据，不提交图片任务，补齐私有 UI 联调之外的生产跨命名空间网络路径。
Linux 原生脚本链接需要 `-pthread -ldl`；本次独立脚本工具链未自动加入这两个参数，已显式链接。

发布时静态资源初版误用缺少 `/bin/cp` 的基础镜像，造成短暂中断；已改回支持既有 init 命令的
web-live 基础层，现为 Ready。不要把 native gateway 的精简镜像用作静态资源复制容器。
公共发布采用 maxSurge=0 / maxUnavailable=1；持久意图与模型幂等另行保护退出中的任务。

状态卷已在持锁、无未完成任务时备份；解包比较日志和真实 PNG 逐字节一致。
独立本机副本：`/Users/kq/moonsuite/backups/banxing-coffee/20261107/`，目录 0700、文件 0600；
归档 SHA256 `19347b924b371f07d56ebbb41decef6d06a3210e99fe25731a9faebbe595710c`。
不含密钥，也未创建定时备份任务。后续活动进行中的备份要使用同一锁与未完成任务检查。
图片适配器更新重启后，以原任务 ID 进行 GET，取回的 PNG 与持久文件哈希一致，未再次生成。
原始图像与状态的空间上限按每张最多 8 MiB、每场 500 张预留；应用与适配器各自留存，
每期分别至少按 4 GiB 原图加余量规划，不能只按一个缩略图大小估算磁盘。

## 仍需主办完成

真实统一登录的两个普通账户和一个主办账户尚未提供；已完成真实模型 + 隔离身份的 UI 全链路，
不能宣称完成了生产账号的双用户验收。正式作品墙仍为空，等待真实投稿。
腾讯文档实际投票链接尚未提供，按用户要求使用明确“不计票”的自有预览页；可替换正式链接。
不伪造票数或实时排名。奖品采购、款式和兑奖细节仍由主办确认。
当前支持一份活动配置，每期更换 Challenge ID 与独立状态目录；自动周更发布仍未实现。
月预算 1000 元的收益、奖品和风险方案见同目录 WEEK01 / LAUNCH_GAP。

没有把用户提供的集群密码写入源文件、配置、书、日志或导出包。
