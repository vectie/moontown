# 半醒咖啡：奖品入口、默认创作与领奖群

## 已实现

- `/disp/` 参赛二维码增加橙色圆角高亮圈，文案为“一键参赛有奖”。标题下用手办、帆布包、咖啡券三张小插画说明奖项；保留原17杯视频、橙条、英文、联名和原二维码内容。
- 提示词可留空，采用已有“杯里小城”默认灵感，回填到输入框供用户查看和修改；自定义提示词与原请求意图、断线重试、草稿保留逻辑不变。
- 只有投稿请求被服务端确认成功才弹出领奖群。可关闭、下载原二维码，并从“我的作品”再次打开。关闭或不入群不影响审核。
- 微信长按识别和其他浏览器保存到相册的说明分别呈现。当前群码仅用于首期及既有私有验收活动，11月16日00:00北京时间起显示到期提示并隐藏旧码和下载，不把其他主办方活动导入本群。
- 有私人创作记录时默认显示“我的作品”；顶部也提供直达入口。审核中、未过审、参赛中、撤回等状态放在图片右上角；退回原因和修改重投入口保留。公开墙仍只展示过审作品。

## 素材与生成

- 最新群二维码来自 Downloads 中2026-11-09 16:27的微信群分享 JPEG。原文件1031×1495、153705字节逐字节复制到 `src/ui/assets/coffee/claim-group-20261109.jpg`，SHA256 `ef57f6cea248b01a7fed9a613fc8c1245465ae23288cd6be1872a4aaa983f6f7`。页面仅用 CSS 裁切，下载保留完整原图；没有交给图像模型重画。
- 奖品为示意插画，非实物承诺。使用内置 imagegen，透明底三格横向图；源图保留在 `/Users/kq/.codex/generated_images/01a10af2-c8fb-7663-b4df-2fd1b2c9d71c/exec-3dcd7164-a11f-4348-bab5-b09b398adbbf.png`。
- 使用 cwebp 缩到720px、质量82后约40KiB，保存为 `src/ui/assets/coffee/prizes-v1.webp` 和 `src/ui/coffee-display/assets/prizes-v1.webp`。同一张图由 CSS 选取三格，无额外图标库或绘制循环。群二维码约150KiB，仅打开弹窗时设置图片地址，不增加首页图像下载。

生成提示词（built-in image_gen；原文）：

> Create one transparent-background PNG sprite sheet for a warm friendly Chinese coffee community art contest website, with THREE equal square cells arranged as one horizontal strip, each object centered in its own third, ample transparent spacing so objects never cross cell boundaries. No text, no letters, no numbers, no QR codes, no brand marks. Left cell: a charming original small collectible desk figurine of a round sleepy coffee bean character, terracotta orange and deep forest green, on a tiny cream circular pedestal, clearly a physical toy. Middle cell: an attractive cream canvas tote bag with green handles and a small orange abstract circle print, soft fabric texture. Right cell: a little cream coffee redemption ticket with scalloped edge, an embossed small green coffee cup pictogram and an orange seal, clearly a voucher, no readable writing. Consistent high-quality playful miniature product illustration, gentle three-dimensional clay and paper textures, diffuse studio light, clean silhouette, restrained palette cream #f1eee6, forest green #243e32 and orange #f74f29. Designed to remain recognizable at 56px per cell. These are prize illustrations, not exact product photos. Exactly three objects, one in each equal cell. Wide 3:1 composition. Transparent background with real alpha, no ground plane or checkerboard.

## 验收与发布

- 浏览器全套200/200，含留空/空白提示词、自定义提示词保持、私人墙各状态保留、群码到期边界和活动隔离。`moon info`、所改脚本格式和检查通过；既有1250条弃用等告警没有引入公共接口变化。
- 既有原生 HTTP fixture 在 loopback 4396 运行，使用显式静态咖啡杯样图，不调用 GPU、不是真实参赛作品。手机走完：游客留空生成 → 登录A接回同一张图 → 投稿成功群弹窗 → 主办退回 → A看到未过审图片和原因 → 修改重投 → 主办批准 → A参赛中 → B自己的作品为空、可看公开过审图 → A重新打开群码。没有修改真实活动的审核结果。
- 320×568群弹窗保持在544px高度内、可滚动且关闭按钮可见；375×812验证成功/重开。海报320px和375px无横向溢出，桌面1920×1080保留原排版。未声称已通过实体手机扫码入群。
- 正式/QA最终UI镜像 `sha256:0bb38c76166c9e796f661ac4794d5bb2480f84f36806c563c266944087425dfd`。原生运行时、身份、GPU服务和持久卷未变。
- 发布目录 `/home/HwHiAiUser/coffee-prize-claim-20261109/ui-v2/` 保存UI收据和QA/正式之前的部署。正式持久状态在发布前后均为revision35，10张图片及2份投稿全部保留。
- 展示站发布目录 `/home/HwHiAiUser/moontown-display-20261108/copy-prizes-v7/`；清单SHA256 `d61c6cbe29a54900450c91915aa4b0948f1025e7536086954dac34621b113537`。逐项散列校验后新增素材 → CSS → HTML原子替换，旧HTML/CSS备份。443/8443均通过资源字节校验、视频Range206、参赛页200。
- 截图保存在原工作区 `output/coffee-prizes-claim-20261109/`。`display-*-live.png` 是线上页面；`*-fixture.png` 为隔离验收，不能当作正式投稿证据。

## 后续建议，尚未实现

1. 给出可编辑的作品名建议并记住昵称，减少重复填写，展示授权仍由用户主动确认。
2. 过审后提供作品分享卡片和投票直达；投票未开放时明确显示开放时间。
3. 每周五换题时同步更新群码和有效期，在群内安排截稿、开票、开奖提醒。统计上区分“打开/下载群码”和“实际入群”，当前页面无法确认微信入群结果。
