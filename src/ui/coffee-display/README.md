# 咖啡转圈展示站

入口：`https://suanli.kechuangfuwu.com/disp/`；当前外网浏览器验收入口使用
`https://suanli.kechuangfuwu.com:8443/disp/`。

原版视频、活动标题、联名区与参赛二维码作为独立图层，保留原始 17 杯排版与旋转。手机显示 HD 视频、二维码与
48px 的直接参赛按钮；桌面显示原版 4K 视频和右上留白处的二维码。所有依赖均在站内。

当前正式参赛地址统一写入 HTML、SVG 及包清单。更换活动时要同时更新 HTML 的两条链接并重新
生成 `assets/participate.svg`，保持 M 级纠错和四模块留白。二维码必须经过独立核对，不应交给
图像生成模型绘制。

`scripts/package-coffee-display.mbtx` 导出十二个公开文件与散列清单，原稿说明不会公开到站点。
`scripts/publish-coffee-display-runtime.mbtx` 镜像经校验的官方运行时到内网仓库。
`scripts/deploy-coffee-display.mbtx` 创建专用入口、静态资源及容器候选。
本次节点外部镜像拉取被阻塞，最终使用 `scripts/release-coffee-display-host.mbtx` 的独立用户
服务，保留入口并将容器候选缩为零。`scripts/verify-coffee-display.mbtx` 验证两个 TLS 入口、
二维码文件、正式参赛页和视频 Range 响应。固定发布路径和镜像散列是本次发布的审计边界，
后续发布要使用新的目录并核对当前入口，不能覆盖已有发布。

标题与联名更新使用 `scripts/update-coffee-display-copy.mbtx`，核对固定清单和原版散列，备份
旧 HTML/CSS 后按新增素材、CSS、HTML 顺序原子替换，无需重启服务。公司字标沿用官方素材；
半醒工坊沿用杯身提取轮廓；向量贴贴为本次 SVG 草案。保留原橙色条和英文邀请语，联名
缩小置右。手机端裁去视频文字区后，以 HTML 恢复橙条和英文，避免跟随视频缩成无法阅读的小字。

右上方并排显示“扫码参赛”和“关注社区”，手机端两码下方提供 48px 的直接参赛按钮。
社区二维码原图逐字节保存，CSS 裁切保留四模块以上留白；其微信扫码识别需在现场设备上核对。

当前用户服务设置了自动重启和开机启动（已确认 linger=yes）。可用管理机用户执行：

```text
systemctl --user status moontown-coffee-display.service
systemctl --user restart moontown-coffee-display.service
```

浏览器已验证 320px、375px、1920×1080，包含播放、暂停、正确视频源与正式参赛跳转。
二维码文件已与部署包逐字节核对；物理手机扫码仍建议在现场距离下检查。
