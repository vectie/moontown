# ELF 2 上的未来社区 Lepusa 活动展屏

设备 `192.168.2.23`，主机名 `elf2-desktop`，硬件 `ELF 2 Board`，ARM64、Ubuntu22.04.5、4GiB内存。桌面用户为 `elf`；主机名中的 `elf2` 不是用户名。通过集群管理机进入，不直接从公网暴露板子的SSH。

## 应用与赛题

- 应用标识 `dev.vectie.future-community-display`，版本0.1.3；使用真正的Lepusa系统WebView，Linux后端为系统WebKitGTK2.50.4/GTK3，原生ARM64运行时。
- 入口始终为 `https://suanli.kechuangfuwu.com:8443/disp/`，复用已批准封面、logo、双二维码和18件获奖轮播；比赛后端和公开网站本次没有改动。
- 页面就绪时自动进入原生窗口全屏，F11切换。原生窗口标题跟随已加载赛题；页面创建轮播且可见图片完成解码后才更新主题标题，便于确认真实WebView已经加载。
- 每5分钟同源GET核对展示HTML的主题、图片、脚本、样式版本；新版完整时重载。断网保留当前已加载画面；暂停或大图弹窗中延后更新。初次开机需要网络，启动服务先通过有效HTTPS取回展示页，再打开WebView；不绕过证书验证。
- 原生桥仅声明 `window.setFullscreen` 和 `window.setTitle`，限定当前窗口和正式网站origin，没有文件读写、Shell等页面权限。

## 4K策略

按3840×2160、16:9整屏展示。窗口全屏跟随当前显示器；Mutter监控程序只选择EDID实际声明支持的3840×2160模式，优先最接近60Hz且支持100%缩放的模式，不创建猜测的时序。

检测到外接4K屏时，临时切为该外屏单屏、100%缩放、横向并设为主屏，再重开展屏。每15秒检测接拔变化。未连接4K屏时保留系统现有输出。首次切换前备份Mutter状态，不写死某个HDMI接口号，不永久覆盖monitors.xml。

本次板上实际只有1024×600、约56Hz的DSI面板，HDMI尚未接入。原生窗口已按当前输出验证全屏。4K模式选择和60Hz优先、无外屏回退、已配置不重复变更的测试已通过；实际HDMI4K画面、刷新率和热插拔仍需接屏验收，不能把DSI验收称为物理4K验收。

## 安装与启动

安装包 `output/coffee-display-app-20261127/future-community-display-0.1.3-linux-arm64.tar.gz`，约1.5MiB，含原生安装程序，不要求目标用户安装MoonSDK。

SHA256：`fcc0678602de068e183947b66f1282e5cf2d23ec017d9e7d00ab3e4aba3e34cd`。

解包后以桌面用户运行：`./install /解包目录的绝对路径`。安装器校验payload清单，先备份本应用旧安装和配置，再原子更新。

- 程序：`~/.local/opt/future-community-display/`
- 用户服务：`~/.config/systemd/user/future-community-display{,-monitor}.service`
- 自动启动：`~/.config/autostart/future-community-display.desktop`
- 应用菜单：`~/.local/share/applications/dev.vectie.future-community-display.desktop`
- 备份、日志证据、安装回执：`~/.local/state/future-community-display/`

GDM原本已开启elf自动登录，保留原设置；GNOME登录后启动用户服务。运行期间通过gnome-session-inhibit阻止idle/suspend，停止应用会释放抑制，不修改锁屏或全局电源策略。异常退出由systemd重启。

停止：`systemctl --user stop future-community-display.service future-community-display-monitor.service`。

启动：`systemctl --user start future-community-display.service`。

日志：`journalctl --user -u future-community-display.service`。

## MoonBit 1.0和构建

实际编译器 `v1.0.0-rc1+3c0520448 (2026-11-26)`，构建工具 `moon 0.1.20261126 (ccd306a)`。这是官方1.0候选版，不称为最终1.0正式版。

- 官方ARM64 SDK归档SHA256：`258cbac118ab59c45fc3b419b6984d2b25cdeab43dd821f3d4cb1d2f671c16d2`。
- 对应core归档SHA256：`a3f7d82f1195e28ad9aad7b9b8b4cbca490cbf8146b306a376ea3beba4173751`。
- Lepusa源码基线：`a279408e22ee8d47e0f3ef3d8c976a4152920bda`（0.1.6）。
- 只在任务独立构建副本修正MoonLib0.1.19的旧trait方法调用为 `Json::string(Show::to_string(self))`，去掉ScaffoldFile重复derive；未修改本机共享Lepusa源码或全局依赖缓存。
- GTK停止修复保存在 `scripts/patches/lepusa-linux-gtk-stop.patch`：GLib主循环接管SIGTERM/INT/HUP，临时解除Moon async对此三种信号的屏蔽；销毁窗口后退出GTK，移除信号源并恢复调用方mask/handler，保证回调不再引用栈上下文。实测正常停止252ms、Result=success，idle抑制同步释放。
- 新SDK的cache复制需包括 `cache/deps/.moon-cache` 标记。只复制sources目录会被拒绝为未知cache。依赖材料和registry index离线复制到任务私有SDK后，使用frozen构建，避免构建时重置明确审阅的兼容改动。
- Linux测试带有不存在的本地server夹具，应使用无真实显示器的Wayland地址且PATH仅保留 `/usr/bin:/bin`；否则会打开测试窗口或把SDK的moon误当可用server启动程序。该环境下9/9通过。

## 验收与边界

3项前端测试验证原生启动/F11、窗口桥origin限制和更新恢复；4K选择自检通过；Linux后端9/9通过；真实原生窗口与当前屏幕几何一致，主题就绪检查通过；正常停止及重启通过。

此WebKit跨进程页面没有暴露完整AT-SPI网页树。验收结合原生AT-SPI窗口几何与页面就绪后设置的原生主题标题；不是只检查进程存活。GNOME拒绝无交互截图，未降低桌面截图权限。未取得板上截图，不用普通浏览器截图冒充板上截图。

整机重启验收通过：boot ID从 `a971d73a-2a3c-41d2-8d51-12e2b62dfe38` 变为 `908a1dbf-7197-462a-b6b6-04ff79aecfe7`，未手动启动服务。服务在开机后约9.5秒进入active（不是页面首帧时间），NRestarts=0；随后原生主题标题及1024×600全屏几何检查均通过，idle/suspend抑制生效。该次系统MemAvailable约2.1GiB，不能据此推断4K渲染性能。全部证据保留 `output/coffee-display-app-20261127/`，包括 `after-reboot-receipt.json`。
