# 展示站4K素材与轮播修复

线上入口：`https://suanli.kechuangfuwu.com:8443/disp/`。

## 修复

- 原背景实际1672×941。新增3840×2160 WebP，仅1800px及以上视口选择；普通桌面与手机保留原轻量素材。新图1095174字节，解码RGBA约31.6MiB，不增加逐帧JS渲染。
- 内置ImageGen恢复已确认封面细节；工具虽收到3840×2160请求，仍返回1672×941。随后用cwebp1.6.0（q90、m6、sharp_yuv、resize3840×2160）导出。这是修复后放大的4K交付图，不是原生4K生成，不应声称恢复了原稿没有的真实细节。
- 旧CSS悬停暂停可在两种浏览器复现：data-paused=false，但animationPlayState=paused，位移不变。去掉悬停暂停和启动2秒延迟。
- 原生Lepusa展示自动播放，不继承桌面减少动态效果的初始暂停；普通浏览器仍尊重该偏好。明确播放选择不会被后续系统偏好变更覆盖。
- 仅键盘Tab导航触发阅读暂停；鼠标/触摸及程序恢复焦点不再冻结轮播。保留手动暂停、大图、后台暂停。data-pause-reason区分manual/detail/keyboard/hidden。
- QR、logo、18件获奖数据及赛程未变。发布器检查旧HTML散列，上传不可变素材，最后原子切换HTML，保留回滚备份。

## 素材

- 目标原稿：`src/ui/coffee-display/assets/winter-cover-original-v1.png`。
- ImageGen结果：`output/coffee-display-4k-20261127/winter-cover-restored-v2.png`，SHA256 `3f1f591d947a3d5170d744771d33e3566cbead2e0cf37143f26944081eb1de0e`。
- 正式素材：`src/ui/coffee-display/assets/winter-cover-4k-v2.webp`，SHA256 `9a6e3366e0b86d8ad553e535236ddc468942e0c94dfafe22ec10357fb6182730`。
- 使用内置工具，未调用API/CLI生成。完整原样提示词：

```text
Use case: precise-object-edit / high-resolution restoration.
Asset type: existing approved 16:9 full-screen exhibition cover on a real 3840×2160 4K display.
Primary request: faithfully restore this exact approved image at 3840×2160 pixels, with genuinely finer paper grain, sharp clean Chinese typography, delicately resolved cut-paper edges and snow/cup detail suitable for viewing across a large 4K screen. This is resolution restoration, not a redesign. Output a single full-bleed landscape image at 3840×2160 pixels.
Input image 1 is the exact edit target and visual composition to preserve.
Invariants: keep the exact composition, camera, object shapes and placements: navy upper-left sky, oversized ivory Chinese title at left, amber translucent faceted coffee cup lower-right, cup steam becomes a winding warm ochre/terracotta road up through blue snow-covered town, branches with pale yellow blossoms, same restrained artful silkscreen/collage/paper texture and colors. Keep typography exact and in its current positions: small upper-left line "未来社区创意活动 · 第四期"; large title arranged exactly as input "把冬天" above "泡开". Do not add logos, QR codes, borders, frames, people, extra text or decorations. Keep the original layout and mood intact; just resolve the source detail for 4K.
```

## 验收

- 本地29项测试通过，含Chromium/WebKit各6组浏览器场景、获奖数据/资源、原生启动与更新测试。正式HTTPS重复跑两种浏览器全部场景通过；4K视口实际解码3840×2160，390px手机仍取原手机图，无横向溢出。
- 测量实际transform连续位移；悬停、暂停/继续、鼠标打开/关闭作品、键盘焦点、减少动态偏好、原生自动播放均通过。4K/手机截图及采样JSON留存 `output/coffee-display-4k-20261127/`。
- ELF板192.168.2.23恢复联网后，在真实Lepusa WebView临时注入页面探针，经既有setTitle桥把测量值放入真实原生窗口标题，由AT-SPI读取。1.6秒位移76.944px，paused=false、playState=running，正式v2脚本已加载。
- 探针未新增原生权限或后端接口；完成后逐字节恢复原manifest并重启，正常主题标题及全屏几何再次通过。脚本 `scripts/verify-coffee-display-playback.mbtx`；证据 `native-playback-receipt.json`、`after-playback-v2-receipt.json`。
- 板上仍只检测到1024×600 DSI，因此取1672×941普通桌面图属预期。物理4K/HDMI尚未验收；不能用4K浏览器截图冒充板上截图。
- 四个正式文件经有效HTTPS逐字节散列核验。管理机备份及回执 `/home/HwHiAiUser/coffee-display-4k-20261127/display/`；旧HTML `4cb6216d…`，新HTML `f81a4485…`。只更新展示静态站，未修改比赛数据或模型服务。

浏览器测试入口 `src/ui/coffee-display/display-browser.test.mjs`，需要Playwright Chromium/WebKit；非默认模块路径设置PLAYWRIGHT_MODULE。设置COFFEE_DISPLAY_URL测试正式站，缺省启动只读本地素材服务器。

现有Lepusa应用每5分钟检查网站版本，暂停或大图期间推迟刷新。能访问网站时SSH不通不影响此机制。本轮恢复连接后已重启并确认新页面生效。

## 联名字标后续调整

用户随后决定暂不进行原生4K重制，只调整联名字标。反白字在雪景上难辨，用户要求恢复原配色；反白方案未上线。最终保留原黑色公司字标、半醒工坊原线稿和向量贴贴原填充色，把白色底板改为半透明暖纸色渐变，边角轻微柔化，无阴影或发光。手机继续使用原透明背景。

发布 `scripts/publish-coffee-display-label.mbtx`，只更新 `display-week04-label-v3.css` 和HTML；旧HTML固定 `f81a4485…`，管理机备份/回执 `/home/HwHiAiUser/coffee-display-label-20261127/display/`。封面、logo位图、二维码、获奖数据和播放JS均校验未变。WebKit检查3840×2160、1024×600、1024×768及390×844，原图字标filter=none，无横向溢出；预览位于 `output/coffee-display-label-20261127/`。

正式HTTPS两文件散列核验通过；正式站四尺寸复查通过。ELF板应用刷新后正常主题与全屏几何再次通过，证据 `output/coffee-display-label-20261127/native-receipt.json`。
