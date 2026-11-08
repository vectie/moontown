# 咖啡活动：游客创作、登录参赛与私人作品墙

2026-11-09。沿用现有 Challenge、Generation、Entry、主办审核和站内投票模型。
正式入口：https://suanli.kechuangfuwu.com:8443/moontown/coffee-contest.html 。

## 实际行为

- 免登录生成，登录后投稿；`guest_generation` 缺省关闭，本期正式与 QA 显式启用。
  免登录仍受个人与活动预算约束。
- 提示词、选中作品、请求意图、投稿标题和昵称按活动和创作者保存。小文本有同步
  localStorage 备份和 IndexedDB 主存，待上传图片用 IndexedDB Blob。登录、刷新与
  短暂断线不主动清空草稿；失败保留原意图，重试不会重复出图。
- 历史由服务器持久保存。游客凭证是活动独立的 256 位 HttpOnly/Secure Cookie，
  不能冒充平台账号。登录在状态锁内接收游客作品，过期本活动旧凭证；其他账户和
  活动的草稿不删除。生成中登录，任务完成时保留当前持久化归属。
- “或”连接生成和外部 AI 作品上传。上传要求已验证账号，每账号每活动最多 20 张，
  活动也有总量上限，不占 GPU 次数。PNG/JPEG/静态 WebP，最多 8 MiB、2048×2048。
  失败可以继续上传或重新选图。
- 服务端检查实际格式、完整容器和像素尺寸，最多并行处理两份上传；完整解码后
  重建无元数据 PNG 并制作缩略图。原始上传字节不落盘、不公开返回。SVG、动画、
  伪扩展名、损坏或附加脚本数据被拒绝。这不是杀毒引擎，不能保证恶意文件永远
  无法通过；内容适合性仍须主办审核。
- 公共墙只展示过审作品；私人墙有未投稿、审核中、未过审、参赛中、已撤回等状态，
  显示退回原因，支持重投和撤回。先批准参赛，再大众投票与封榜决定前三等奖。
- 活动和主办页面改为“未来社区”与星星素材；源 PNG 保留，页面使用约 5.2 KiB 的
  128px WebP。内部 MoonTown 路由与协议名保持兼容。

## 验收

| 检查 | 结果 |
| --- | --- |
| 根项目完整 native | 2,072 / 2,072 |
| Gateway HTTP native | 10 / 10 |
| 创作核心 focused native | 27 / 27，含生成中登录及凭证隔离 |
| 图片 focused native | 3 / 3 |
| 浏览器 source 全套 | 192 / 192 |
| 正式、QA smoke | public/guest 200；mine/匿名上传 401；跨站上传 403 |
| 手机 | 375×812，另测 320×740，无横向溢出 |

完整 native 使用 HANDOFF 的 Claw/Book fixture 环境变量。首次 broad 运行因稀疏
工作区缺少 tilemap，编辑器 1 项失败；恢复已跟踪素材后全通过。浏览器 broad 还需
既有 ignored landmark-studio 运行资产，从原工作区复制后全通过，未提交该目录。

隔离本地 fixture：游客连续生成、刷新、登录 A 保留历史；A 投稿、上传 JPEG，
连接故障时保留提示词、旧图和意图，恢复相同持久状态后仅重试一张。B 看不到 A
私人作品，上传 PNG 并投稿。主办批准 A、退回 B；B 显示原因且不出现在公共墙。
375px 再走撤回、重新投稿、退回、修改重投、批准；最后 A 四张历史仍完整。
故障演练停止并恢复所拥有的本地 fixture，不据此推断生产网络故障的原因。

正式站真实验收：免登录提交一次 ComfyUI 生成，生成途中刷新后恢复同一提示词和
完成图。参赛要求登录，既有普通 QA 账户 A 登录后接回表单；标题昵称刷新后保留。
随后 JPEG 上传由 Linux 后端重建成功，两种 WebP 正常，历史变两张，生成次数仍为9。
没有在正式审核队列投稿或公开测试图片。保留原 QA 已封榜投票，未重新压测20人。

截图目录：`/Users/kq/Workspace/moontown/output/coffee-participation-20261109/`。
`mobile-live-generated-full.png` 为真实 GPU 出图；`mobile-*-fixture.png` 为隔离接口
演练画面（含投稿、审核中、未过审、参赛中、撤回、私人墙和主办台），不能混淆。

## 发布

QA 和正式站均使用：

- runtime `sha256:dfc9d4d371874dc3348e8139bd5e0a09ea70c907ff0bf8afd6a6ed8adf90278e`
- UI `sha256:d6176e2d7396ab89dedb41e07cddf4f24adc35b5d35ce52a1fdb3f9e70cb4389`

私人发布根目录：
`/home/HwHiAiUser/coffee-auth-queue-20261107/participation-20261109/`。
`qa-final-runtime` 与 `formal-final-runtime` 保存停写后完整两份 PVC 备份，归档和还原
摘要通过；各有 `*-final-config-before.json`，只开启 guest flag，保留原赛程、模型、
权限和预算。`native-source-final.sha256`、`release-final.json` 记录最终产物。
正式 UI 使用部署工具省略 deployment 参数的默认模式；初次传正式名称被参数检查
拒绝，修正后成功切换。先前候选未带 worker 归属修复，没有发布到正式。

JPEG 为官方 libjpeg-turbo 3.2.1，私有解包与镜像内动态库，不安装宿主包。
包 SHA256：`21c7af6e505386dda0fa05e9eab5a8d288947f2e09ade8d7a48ff393ed08182d`。
177 的 Qwen/ComfyUI 未调整或重启。字节、像素、两请求并发限制约束 CPU 解码内存；
列表沿用缩略图，明确放大/保存才请求原图。未测上传 P95 或冷启动，不作性能承诺。

清理站点数据、Cookie 过期、无痕或设备损坏不能保证恢复；账号服务器历史仍可找回，
游客跨设备恢复需要未来的接续能力。
参考：[OWASP](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html)、
[官方 JPEG 版本](https://github.com/libjpeg-turbo/libjpeg-turbo/releases/tag/3.2.1)。
