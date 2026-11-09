# 半醒咖啡转杯展示

原稿：用户指定的
`/Users/kq/.codex/visualizations/2026/11/05/01a1aa9b-7627-7c03-b1a0-e89dc3132ab0/output/rotating-cup-opposed-rows`。

- 4K 视频按字节复制 `coffee-competition-opposed-rows-4k.mp4`，保留 9+8 布局、原版品牌标志、12 秒均匀旋转及上下两排相反相位。
- HD 视频仅缩放和编码，静态首帧导出为 JPEG，均不修改原画内容。
- 当前二维码由 `PaiGack/moonbitqrcode@0.1.0` 生成 SVG，M 级纠错，四模块留白。其内容是正式参赛页
  `https://suanli.kechuangfuwu.com:8443/moontown/coffee-contest.html?source=display-qr&campaign=banxing-01`，不含测试账户或密钥。
- 二维码作为网页元素叠放，不改变原稿视频；手机版另有直接参赛链接。
- 公司字标使用用户指定的 LunaNexa `public-site/assets/company-wordmark.png` 原文件。
  集团标志从用户指定的 `group-logo.jpg` 原始位图裁出右侧新版标志，检测近白色转为透明，
  输出 `group-mark-raster-v5.png`；保留蓝色像素，不矢量描摹、不使用 CSS 混合模式。
- 活动标题由 HTML 覆盖原视频顶部英文区；保留原橙色条及其英文邀请语，联名缩小置右。
  手机版裁去视频文字区，保留两排咖啡杯；橙色条和两句英文改用 HTML 显示，保证可读。
- 半醒工坊沿用项目已从原杯身提取的 `src/ui/assets/coffee/logo.svg` 原轮廓及中文字样，
  保留原稿杯子和上下排文字的完整结构，直接栅格化，未重排字形。
  准备脚本固定原文件散列。发布位图为 `banxing-stacked-v6.png`。
  向量贴贴为本次设计的 SVG 字标草案：矢量箭头、叠贴便签和橙色衬底；中文文字保留可编辑，
  已恢复便签内部浅色填充，使用原版 `vector-sticker-wordmark.svg`。
  `prepare-coffee-entry-v6.mbtx` 重建 v6 标志和二维码；v5 位图与 v4 vectors 脚本仅保留历史。
- 社区二维码为用户提供的 PNG 原文件（SHA256 `8911f1e3c3fde77cb8e704bf1b113f17040a536516291455af4ee7ce58bc047d`），
  CSS 仅裁去原图说明文字，二维码、中心图案和至少四模块白色留白保持完整。未重新绘制二维码。
- 原画为主办提供的灵感参考，不是参赛作品、获奖证据或商品售价与奖品承诺。

页面使用浏览器硬件视频解码，避免每帧渲染 17 个 WebGL 场景。支持暂停、减少动态效果与后台暂停。

服务使用[官方 NGINX 非特权镜像源码](https://github.com/nginx/docker-nginx-unprivileged)
对应的 amd64 OCI 清单
`sha256:7b5016a10b41639c79df145998c67da5e51ca0aaf80083e836f5168c1858a1da`。
发布脚本逐一校验原始清单及层散列，不修改原始服务二进制。
