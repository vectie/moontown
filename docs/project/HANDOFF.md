# MoonTown handoff notes

## 2026-11-27 · BNO055 source preserved on .191

- Found `/home/elf/bno055` on .23:3 C++ readers,3 ARM64 binaries and2 Python
  examples. All8 originals copied unchanged to .191/QaQ at
  `/home/jiaanguo/Workspace/elf-bno055-transfer-20261127`, with a portable
  `.tar.gz` beside it. Archive SHA256 is
  `b6092d7ca5d1857a80df84877091c6922a1689f58325aae4af9958253256b69a`.
- Source/destination hashes match;3 C++ programs pass ARM syntax checks and
  compile/link into separate x86_64 verification outputs on .191. No sensor
  programs or new services were run there. Dependency/migration notes and known
  original bugs: `ELF_BNO055_TRANSFER_2026-11-27.md`. No credentials copied.
- Bus numbers differ between examples: fixed reader uses i2c-1/0x28; read and
  simple test use i2c-4/0x29. Preserve originals and configure a working copy
  when moving to another board. User subsequently plugged a sensor into .192;
  its hardware status must be checked independently from this source backup.

## 2026-11-27 · Exhibition idle cursor

- Native Lepusa exhibition now hides the cursor initially and after1.8s idle;
  deliberate mouse movement/click reveals it. Ignore displacement below4px
  from the last accepted point so jitter/stationary layout events do not wake
  it. The selector covers buttons too, avoiding cursor shape changes as moving
  ticker cards pass underneath. Ordinary web visitors retain normal cursors.
- Real .23 WebView probe verified cursorHidden=true and computed cursor=none
  while ticker still advanced. Original native manifest restored and app
  restarted. New CSS/JS are immutable cursor-v4 resources, HTTPS hashes pass.
  Two browser engines cover reveal/idle/jitter/keyboard and continuing playback;
  no global GNOME cursor settings, OS input devices or background agents changed.
- Evidence: `output/coffee-display-cursor-20261127/`; publisher
  `scripts/publish-coffee-display-cursor.mbtx`. Native probe accepts an optional
  expected script revision, retaining the previous4k-v2 default for old checks.

## 2026-11-27 · Partner label refinement

- Owner deferred native4K generation and requested only the label change.
  Preserve the current cover. Light/inverted partner lettering became illegible
  over snow and was rejected; it was never published. Keep original raster
  wordmarks and brand colors, without CSS inversion or drop-shadow treatments.
- The winter label now has a warmer translucent paper gradient with subtle
  corners, replacing the white panel. Mobile retains the transparent flow row.
  Checked4K,1024×600,1024×768 and390px in WebKit; no horizontal overflow.
- Label publisher changes only CSS and HTML; preserves artwork, logos, QR and
  ticker hashes. Guard mkdir with exists when restaging: the current standalone
  async fs still errors on an existing directory even with recursive=true.

## 2026-11-27 · 4K display asset and native ticker repair

- Responsive4K layout still served1672×941 artwork. Desktop>=1800px now
  selects `winter-cover-4k-v2.webp`3840×2160, about1.04MiB. This is an
  ImageGen restoration exported/upscaled to4K, not native4K generation;
  the tool still returned1672×941. Mobile retains its100KiB source.
  Exact prompt/hashes: `COFFEE_DISPLAY_4K_2026-11-27.md`.
- CSS hover paused the ticker even while data-paused=false. Remove that
  hidden pause; retain explicit pause/dialog/keyboard reading behavior.
  Native exhibition autoplays despite desktop reduced-motion; ordinary
  browsers honor it. Pointer/programmatic focus must not freeze playback.
- Actual WebView on .23 measured76.944px movement in1.6s. Original runtime
  manifest restored after the temporary title-based probe; normal topic and
  fullscreen checks passed again. Public Chromium/WebKit4K and mobile tests
  passed. Board still exposes only1024×600 DSI; physical4K awaits a screen.
  The5-minute app updater needs internet and defers while paused/enlarging.

## 2026-11-27 · ELF 2 native exhibition app

- Correct board is `192.168.2.23`, hardware `ELF 2 Board`, hostname
  `elf2-desktop`, desktop user `elf`; hostname is not the SSH username.
- Installed Lepusa ARM64 app0.1.3, opening the existing `/disp/` website.
  Actual build compiler is `v1.0.0-rc1+3c0520448 (2026-11-26)`, not final1.0.
  User-scoped systemd services and XDG autostart reuse existing GDM autologin.
  A real reboot passed: automatic start, loaded theme and native fullscreen.
- External4K detection selects only advertised3840×2160 modes, scale1,
  closest60Hz, temporary external-only output; absent4K preserves current
  display. Board currently has only1024×600 DSI. Physical HDMI4K and hotplug
  still need an attached screen; never report those as already verified.
- Moon async masks termination signals while GTK owns its blocking main loop.
  The isolated Lepusa build applies `scripts/patches/lepusa-linux-gtk-stop.patch`
  to unblock those signals and stop on the GLib thread, then restore masks and
  handlers. Normal stop252ms; Linux backend9/9 pass. Shared Lepusa source stays
  unchanged. Headless backend tests need an unavailable Wayland display and a
  PATH without SDK binaries so fixture servers cannot accidentally start.
- Full WebKit page accessibility and noninteractive GNOME screenshots are
  unavailable. Proof uses real native window geometry plus page-ready topic
  title after ticker creation and image decoding; no browser screenshot is
  presented as a board capture. Build/install/stop commands, compatibility
  patches, package hashes and evidence: `COFFEE_DISPLAY_ELF_2026-11-27.md`.

## 2026-11-27 · Fourth issue release

- Owner approved the exact 把冬天泡开 cover and scheduled Nov30 opening,
  Dec3 20:00 submissions close/22:00 voting opens, Dec4 18:00 voting closes/
  20:00 awards (Asia/Shanghai). Do not move these deadlines to preview time.
- Cover has its title baked in; the HTML heading remains accessible but is
  visually clipped. Phones show the complete composition, then existing logos,
  entry/QR and the unchanged18-work winner ticker. WebP derivatives are369KiB
  and100KiB; the exact1672×941 master is retained, not advertised as native4K.
- Reuse participation SVG bytes/campaign03: its canonical route selects the
  current event. New direct visits use campaign04. Fourth claim notifications
  use the existing community account QR; third group code expires Nov30.
- Third archive is `/coffee-week03/`; share redirects require an entry ID and
  third event campaign. Event/account-scoped drafts copy across canonical and
  archive routes without deleting their source or importing into fourth drafts.
- `scripts/*coffee-week04*.mbtx` stage/hash/package qualified UI overlays and
  guarded releases. Keep the native runtime and full hosted-app base pinned;
  never replace MoonBook/MoonClaw/Studio with a coffee-only build.
- Fourth cover and scheduled event are now live. QA natural seal/settlement,
  3/2/1 voting and prize publication passed; formal pre-open writes rejected
  without consuming quota. Third state is byte-for-byte preserved. Release
  details and pins: `COFFEE_WEEK04_2026-11-27.md`. Screenshots include320/390px,
  portrait977px and4K. Refresh pre-existing open tabs to load updated modules.
- MoonBit String.replace changes only the first match. Use replace_all for
  multi-occurrence release derivation and inspect IDs/paths before shipping.
  Historical publishers need a newly adapted frontmatter copy for current Moon;
  do not edit historical release scripts or receipts in place.


## 2026-11-27 · Fourth-theme cover preview

- The owner selected 把冬天泡开 and requested one artful cover preview, avoiding
  a cartoon look. V1 is a single16:9 silkscreen/paper-collage composition: a
  luminous amber coffee cup, cold blue snow town and one steam/road ribbon that
  thaws snow into terracotta and blossom. The exact theme and small fourth-issue
  line are baked into this preview; avoid double titles if later adapting it.
- Preview and exact built-in ImageGen prompt are retained in
  `output/coffee-week04-cover-20261127/{winter-thaw-cover-v1.png,request.json}`.
  This is a preview, not a fourth-event opening or a live cover replacement.

## 2026-11-27 · Third-issue award ticker

- The owner selected 勺子《惬意》 as the third first prize and authorized five
  generated display works to fill2 second/3 third slots. Record owner selection,
  not vote-based settlement: the formal event has one approved entry and0 votes.
  `COFFEE_WEEK03_AWARDS_2026-11-27.md` records all asset paths and exact prompts.
- Third groups lead the existing single ticker; earlier groups, current cover,
  QR bytes, borderless play/two-line pause controls and CSS are retained. New
  image masters are read on enlargement;384px thumbnails keep18-work initial
  image cost under1MiB. Preserve the real winner's exact PNG hash.
- Management display backup/receipt: `coffee-week03-awards-20261127`. The
  publisher checks the actual approved winner before switching HTML last.
- The fourth topic was subsequently selected as 把冬天泡开; see the preview
  note above. The fourth event/schedule has not been opened by that preview.
- Browser QA passed at390px and4K, including original enlargement and resumed
  rolling. Use full-page capture for the4K screenshot: viewport-only capture
  clipped the large emulated surface even though its DOM bounds were correct.

## 2026-11-27 · Management Moon script compatibility

- The management `.moon-new/bin/moon` now requires `.mbtx` imports inside
  opening/closing `----` frontmatter. Historical bare-import scripts fail before
  execution. Adapt a new copy for read-only audits; preserve old release scripts
  and receipts. The updated third-round audit completed successfully.

## 2026-11-23 · NAT 对照实验恢复内网访问

用户随后授权在 `.191` 启动临时测试服务，并亲自操作公网 18091 映射。两台同端口对照发现：新增／切换临时 NAT 后原 8443 恢复，删除临时 NAT 后两台同时重新超时（服务仍运行、LAN 直连正常、外网正常）。14:38 用户重新保存正式 `8443 → .173:443` 映射后，两台原 8443/443/32123 恢复；没有改 Nginx、服务器网络、权限隔离或 DNS/hosts。两台临时服务已停止、18091 映射已删除；14:44 间隔复测两台四个业务路径均 200，外网 8443 也为 200，临时目录已清理、端口无监听。外网 443 未纳入最终验收。详细时间线和证据边界见 [NAT 对照记录](nat-probe-comparison-2026-11-23.md)。这支持映射应用／回流运行状态问题，但没有网关内部日志可证明具体缓存机制或归责。

## 2026-11-23 · 公网回流复核与访问机边界

独立访问机 `.191` 曾成功访问公网 443/8443/32123，随后 13:53、13:57 均在 TCP 阶段超时；同期外网 8443 与 `.191` 直连 `.173:8443` 都返回 200。不要沿用“整个 LAN 从未支持回流”或“`.191` 已稳定恢复”的判断。目标端同步抓包看到外网和 LAN 直连 SYN/回应，未看到失败回流请求抵达 `.173`。本轮未修改 Nginx 或网络配置，尚未修通普通域名访问。用户明确 `.191` 是访问机，禁止修改；提出的 hosts 方案已撤回且未执行。详见 [诊断记录](management-public-self-access-2026-11-23.md)。

后续用户要求只查 `.173`。确认当前 Netplan/ARP 文件与 LunaNexa 11 月 10 日双网卡迁移归档逐字节一致。发现 `.175` 专属 `LNX-WORKSPACES` 规则，但它只管 NFS 2049，不能当作 HTTPS 故障根因扩大权限。`.191` 直连 `.173`、`.175` 的 443/8443 全部 200。14:13 从正确接口重新通告 `.173` 的 ARP 未改善公网回流；没有更改访问机、路由器或服务器持久配置。多网卡抓包和限制详见诊断记录后续段。

## 2026-11-20 · WLXK 服务缺失与 LAN 回流

下午的另一账户上传已把 WLXK 更新为 `2bfe3a…` 的新供稿，不能再把上午手册中的 11 月 18 日版本当成线上现状。新供稿只有 HTML，却新增了 API/WebSocket 调用；静态资源 200 不代表在线功能可用。已新增独立 MoonBit `src/wlxk_server`，委托原网关验证账户，访客和账户存档分离。部署和测试详情见 [修复记录](wlxk-server-repair-2026-11-20.md)。

LAN 域名解析到公网 `106.39.18.146`，内网连 8443 在 TCP 阶段超时；保持 SNI/Host 直连 `192.168.2.173:443` 则 21 ms 返回 200。已补 LAN 8443 listener，直连验证 26 ms 返回 200；LAN DNS/路由器配置仍需管理入口。不要将这个问题误诊为证书或 3D 页面故障。

18:20 后进一步确认：管理节点普通公网 HTTPS 正常，自身公网 443/8443/32123 均超时；另一网络桌面绑定真实网卡并固定公网 IP 可访问 8443。已有授权主机身份的只读抓包看到 SYN 重传、未见回包。源 `.175` 同样失败；它与 `.173` 是同一物理主机，不能计作第二台 LAN 客户端。路由器具体 NAT 规则仍未取得，需 WAN 地址与转发目标；旧 10 月部署记录已注明 LAN DNS 前提，不能归罪于本次静态发布。未修改主机路由/防火墙或路由器。详细证据在修复记录的 18:20–18:27 段。

修复 UI 已上线为 `66132aed…`，HTML 为 `0af76311…`；原账户网关 runtime 保持 `5baf6c9c…`。正式浏览器已验证进入、移动、保存恢复和小镇内嵌返回。原供稿手机面板为固定宽度且 `body` 隐藏溢出，`scrollWidth` 无溢出不等于无裁切；保留原样式的本轮没有修手机布局，也没有恢复供稿指向另一内网机器的 AI 服务。详见修复记录的验收边界。

该 namespace 有 default-deny；新服务必须同时配置 Traefik 入站、身份服务出站、DNS，以及身份网关接收新服务的规则。macOS 上传源码需去掉 AppleDouble `._*.mbt`；Linux native 链接需要 `-pthread -ldl`。浏览器测试与重启验收应串行，路由收敛可能晚于 Pod readiness。

## 2026-11-20 · 未来星科发布交接

[未来星科发布与 AI 交接手册](wlxk-publishing-runbook.md) 包含供稿选择、线上基线、增量打包、浏览器验收、回滚和下一位 AI 的任务说明。当天线上正文仍与 11 月 18 日供稿逐字节一致，两个入口的浏览器流程通过。

复查历史脚本发现，11 月 18 日 `package.mbtx` 的上传校验目录和镜像标签仍残留 11 月 13 日的值。派生下一版时应由统一参数生成全部路径和标签，验证本次上传目录。当前 Deployment 使用不可变 digest。

11 月 18 日资源清单继承旧清单，只更新了漫游记录。11 月 20 日实测咖啡页面正文哈希与清单不同，下一次应从实际镜像资源重建清单。`output/` 被忽略，漫游源文件和路由也仍是本机未跟踪文件，交接给新 clone 时需一并保留相关材料。详细证据与恢复路径见手册。

## 2026-11-18 · 未来星科漫游新版

新版供稿为 Downloads 的 `未来科学城能源谷_3D漫游-2.html`，373522 字节，SHA-256 为 `0d81dba2f4714302e3af054481e60d26e0604764e54ce8ba1cfe47bd8cd5c0ad`。原样替换 `wlxk.html`，独立 `/wlxk` 和小镇中的入口共用。原作的 AI 对话指向 `http://192.168.5.206:8001/v1`，公网 HTTPS 下不能把这项算作可用。原作新增车流在浏览器中显示 20 辆车。

发布脚本从部署当前的 hosted-apps 镜像增量打包。11 月 18 日之前的底包已含第二期咖啡活动，不能回退到 11 月 13 日的底包。漫游按需加载，原始 HTML、gzip、ETag 合计独立限制为 512 KiB。验收同时检查小镇首屏没有请求漫游文件。

此环境的网关对 HEAD 请求可能断开连接，Traefik 会返回 502；GET 同一路径返回 200。健康验证必须实际获取正文并检查浏览器。11 月 18 日旧 SSH 跳板 32122 不可用，已有授权的 `HwHiAiUser@106.39.18.146:32123` 可直接到达持有 kubeconfig 的管理节点。

## 2026-11-13 · 未来星科漫游发布

原作含混合换行以及固定版本的 CDN 模块引用。发布时按字节复制到 `landmark-studio/wlxk.html`，构建会核验供稿的 SHA-256。公开短址 `/wlxk` 和小镇未来星科项目共用这一个文件。验收时从公网和小镇各打开一次，确认登记界面及 WebGL 场景均能加载。

## 2026-11-13 · RK3588 场景动画验收

OrbitControls 开启阻尼后会在 `controls.update()` 内同步发出 change。渲染器在帧首清空了 rAF 句柄时，change 回调和帧尾都可能预约下一帧；连续旋转会积累重复的绘制任务。所有帧尾续订都要检查是否已有预约。运行 `scripts/check-town-scene-frames.mbtx`，同时断言相机角度确实变化、每次显示刷新至多一次相机写入。

Chromium 114 会在首次 modulepreload 时解析模块映射。主入口的 Three.js import map 必须在预载之前。独立查看器正常不能证明从小镇进入室内或机房正常。

真板测量要记录连接的显示器、浏览器实际窗口、CSS 视口、2D/3D 绘制缓冲四种尺寸。rAF、WebGL 调用和实体坐标能证明场景逻辑在运行；上屏另用 Viz 呈帧事件验证。若场景完全在小尺寸客户窗口的可见区域之外，4K CSS 仿真仍会更新其相机，而合成器可以跳过上屏。须在覆盖该模型的真实窗口内复测。

滚轮压力用例要在以前没绘制过的中间倍率松手，并把恢复车流算入计时。六次放大再六次缩回会回到已缓存的画面，两个用例能发现不同的停顿。快速后退再前进时，MoonBit 的按钮状态可能还在等待下一帧提交；只让当前历史条目结束镜头还原。[全场景实测](rk3588-scenes-2026-11-13.md)

## 2026-11-12 · 4K wheel presentation

A cheap wheel callback can still precede a 0.8 s display gap: inspect scheduled semantic paints and image-ready callbacks outside the input handler. Defer only unchanged public scenery during the gesture, preserve the cursor anchor in projected coordinates, and include the return to live traffic in measurements. Compare changed zoom positions with Chromium Viz presentation events. Give each board memory sampler an explicit lifetime tied to its own temporary profile. [Same-path results and limits](rk3588-wheel-zoom-2026-11-12.md).

## 2026-11-12 · RK3588 outdoor candidate

Compare the same physical wheel path on clear canvas before judging zoom throughput. A projected marker can move under a stationary mouse as the camera moves. In Chromium on the board, copying screen pixels back and forth for each road depth cost hundreds of milliseconds. Pack transparent street strips into bounded shared GPU canvases and composite vehicles between road depths. One GPU canvas per strip showed lower whole-board memory headroom. Release the pool when leaving the scene and keep the ordinary-painter fallback. Remove test-owned temporary browser profiles between memory comparisons, as /tmp on this board is tmpfs. Browser-process PSS and system MemAvailable moved in opposite directions in the 4K overview. Record both alongside viewport and canvas dimensions. The public world package must match the compiled runtime layout and reference digest. Run a damaged-package recovery and an exact camera comparison when changing the release assembler.

[Real board measurements and evidence](rk3588-town-rendering-2026-11-12.md)

## 2026-11-12 · RK3588 public town measurements

The ELF 2 board runs Chromium 114 with hardware Canvas and Mali-G610 Panfrost. Its active DSI panel is 1024 × 600. A 3840 × 2160 CSS viewport at DPR 1 on that board exercises the 1431 × 805 map canvas and the larger visible world. Physical 4K HDMI scanout remains unmeasured. Use browser-tree PSS (all 11 processes were readable) and system MemAvailable together on this shared-memory GPU. The original indoor and 3D resources are outside this outdoor measurement.

On public `/town/`, cold map readiness took 12.68 s at both sizes. In the separate 4K startup CPU profile a 9.59 s main-thread task spanned world initialization and mount. Snapshot/world reconstruction, initial save migration, road lookup and world validation appear in those stacks. Measure from navigation to the first live canvas and ready ground/district, as the HTML load event occurred within 0.31 s. Home animation delivered about 18 full map callbacks/s in both sizes. The 4K full overview delivered 1.65/s, with 64.5% of main-thread samples inside tree drawing including descendants. Its browser-tree PSS was 918 MiB and system MemAvailable was 997 MiB at that sample.

During 4K home zoom the café button moved under the stationary pointer and received 14 of 18 wheels. On a clear point at Guoxian all 12 real wheel events reached the canvas and the camera returned to its initial zoom, but frame callback gaps still reached 1.16 s. Record event targets, visible car coordinates and camera recovery alongside paint timing. The matched project test used the same world center and each viewport's normal auto-fit. Measurements, CPU profiles and gesture traces are in `output/rk3588-board-20261112/`; `board-results.json` contains the comparison.

## 2026-11-12 · 4K display performance

Check both 3840 × 2160 CSS pixels at DPR 1 and 1920 × 1080 at DPR 2. Both produce the same physical display size and the compact outdoor renderer allocates a 1431 × 805 canvas in both configurations. The visible world and the cost of zooming differ. On the published 8443 site a 4× CPU-throttled desktop Chrome session reporting 4 GB gave about 20 full paints/s for the home and Guoxian close-ups, but only 6–7 for the full overview. These are simulated display profiles. They do not constrain physical RAM or measure Rockchip GPU presentation or thermals.

At 100% scaling, 4K overview sampling attributed about 47% of time to the botanical tree call stack, including its descendants. Trees are repainted even with a ground-cache hit. Bypassing the dedicated district volume renderer in an isolated browser only changed median overview paint from 116–117 ms to 113 ms. During pan, measure cached composites as well as full paints. During zoom, record frame gaps and ground-cache rebuilds. Raw observations are in `output/town-camera-20261112/r3/4k-field.jsonl` and `4k-overview-profile.txt`.

An isolated wide-view A/B/A trial at DPR 1 reused small rendered tree images at zoom ≤ 0.30. It retained each tree's kind, placement, size and shadow and grouped crown variation into eight seed buckets. Median full paint was 120.1 → 39.0 → 122.1 ms and full paints/s were 6.6 → 18.1 → 6.3. This was a browser experiment only. Check tree silhouettes across zoom thresholds and on-device memory before shipping. See `output/town-camera-20261112/r3/4k-tree-trial.jsonl`.

## 2026-11-12 · Original outdoor camera angle

The public street and overview both use the original 32:16 isometric projection. The extra vertical shear introduced with the navigation release changed the apparent angle of every registered road and building. Keep the display and pointer coordinates in the native projection when adjusting navigation, framing or rendering cost. The browser gesture check now asserts this in both views.

QA and formal use UI digest `sha256:da58e8ded58b9a0efbac24855eb2144d52ba092e81ba55971e76ec3653644a88`. The incremental release changes the camera module and its delivery metadata. See `output/town-camera-20261112/r3/` for the checksums and verification.

## 2026-11-12 · Public map navigation and 4 GB rendering

- Public project links, the former region view, the viewport alias and the town overview use the same outdoor canvas. The registered 256 × 144 design controls the core. Geographic surroundings use the local east/south frame at Future Vision and a spatial index. This outside registration is an approximation. Peripheral buildings have less detail than the individually studied landmarks.
- Preserve a camera per browser history entry. Project, campus building, fit, indoor and 3D navigation can visit the same URL at different zooms. An embedded viewer changing its own hash can silently consume the parent's Back button. The map has an explicit inverse display transform for picking, dragging, pinch anchors and wheel anchors. Testing the logical isometric coordinates alone misses off-centre gesture errors.
- Test the hosted prefix as well as the local build. On a fresh connection the district geometry becomes ready before a requested project's directory and camera finish loading. Wait for the selected project's name before measuring a drag. Run `scripts/check-town-camera-gestures.mbtx` against the published prefix for the complete route.
- On 4 GB clients the outdoor canvas caps its pixel count, caches static terrain, caps footprint and facade textures, and budgets moving traffic separately. Measure actual map paints and vehicle positions. Browser animation callbacks can continue at 60 Hz while the map is painting at 20 Hz. A six-second Chrome test on the public left-dike view at 1100 × 720, 2× DPR and 4× CPU throttle gave 63.1 → 7.3 ms median paint and 132.5 → 9.4 ms p95. Vehicles changed visible positions. This benchmark used a desktop with a simulated 4 GB browser profile; the RK3588 board still needs an on-device run.
- QA and formal use UI digest `sha256:a15c65fe43ae64556f15c3e1ecf1e5cacd1649e4eab01e9a18e001ca5e1563fe` from the init container. The runtime gateway stays pinned. Management retains the rollout records under `town-camera-20261112-r1` and `town-camera-20261112-r2`. The release evidence in `output/town-camera-20261112/` contains the production screenshots, measurements and asset checksums. The registered road asset, 3D models and account resources are inherited from the existing image.

## 2026-11-12 · 公共小镇改址与校岸版上线

8443 正式入口为 `https://suanli.kechuangfuwu.com:8443/town/`。新公共前缀在 Traefik 转给原服务；旧浏览器链接保留路径、查询参数并 302 跳转。原有身份交接与私有工作区仍使用 `/moontown/workspace/`。公共启动脚本与存储分区同时识别 `/town/`。路由配置见 `deploy/town-public-routes.yaml` 与 `deploy/town-public-legacy.yaml`。

预发布与正式服务使用同一 UI 镜像 `moon/hosted-apps@sha256:9d25d893a03bfd6c529e6c4092bc3c968226765ab6095074f01b886c61453ff2`。管理节点的 `/home/HwHiAiUser/town-public-20261112-r1` 保存上版配置、镜像与发布记录。新包已纳入 4a8e6c65 的咖啡模块；正式网关继续用 5baf6c9c，回滚 UI 应参照 `before-formal.json` 的 initContainer。新首页、校准路网、区域二进制、3D 核心库、品牌图和活动模块均经 8443 实际取回并与发布包逐字节核对。匿名公共账户返回 public，未登录访问私有账户接口返回 401。
## 2026-11-23 · Borderless motion control

- The owner removed the square frame around play/pause. Keep the control
  transparent and borderless in normal/hover states, with the44px touch target
  and keyboard focus indication retained. The later instruction also removes
  the circle inside the pause glyph: use two16-unit vertical strokes, sharing
  the play glyph's24px viewBox,1.65 stroke width and round caps.
- `publish-coffee-borderless-control.mbtx` publishes only versioned CSS and
  HTML, retaining the v2 main/data modules. Private display backup/receipt root:
  management `coffee-borderless-control-20261123`.
- Actual390px acceptance confirmed zero border, transparent background, no
  shadow,44×44px hit area and working pause/resume. Both public file hashes
  matched; ten display tests passed. Temporary viewport override was reset.
- The publisher's `plain-pause` option changes only HTML and retains the v3
  CSS/v2 modules. Its private backup root adds the `-plain-pause` suffix.

## 2026-11-23 · Third 暖暖 event and fresh group invitation

- `COFFEE_WEEK03_2026-11-23.md` records the approved Nov26/27 schedule, new
  group QR (valid before Nov30), qualified images, private backups and real
  generation/upload/review/voting acceptance. The third submission format is
  static PNG/JPG/WebP; do not imply animated uploads are connected.
- Keep old event state and draft scopes separate. A canonical shared entry
  link must route to its archived event before draft restoration. Historical
  pages read canonical same-event draft aliases without deleting originals.
- `platform-base.js` prefixes arbitrary same-origin root links with the active
  app mount. Explicitly preserve the two known public archive routes or
  `/coffee-week02/` becomes `/town/coffee-week02/`. Private APIs stay scoped.
- The current hosted-apps base was2bbbb394, not the older documented0e08 image.
  New third UI digest49c3c989 and second-history digestb0d04c5d preserve that
  qualified platform and native runtime5baf6c9c. Do not rebuild an older runtime.
- Formal acceptance data belongs in the isolated third QA event. Its natural
  windows are closed after two real generations, one external upload, review
  return/resubmit and six-ballot ranked settlement. Never copy those into formal.
- The display has a five-minute HTML cache. A newly opened tab may reuse the
  earlier preview within that window; ordinary Reload revalidates it. Management
  cannot hairpin the external8443 route reliably; deployment guards use validated
  internal443 and final verification uses public8443 from the local machine.
- The owner requested icon-only play/pause controls and fixed random aliases
  for the eight generated display works, then explicitly replaced the AI补位
  wording with ordinary 获奖作品/主办方确认获奖. Preserve internal provenance
  and every existing participant author; these display selections do not create
  backend contestants or ballots. This supersedes earlier display badge notes.
  Shared icon geometry comes from MoonVis's play/paused SVGs; touch target
  remains at least44px. Final display release is coffee-display-controls-20261123-v2.

## 2026-11-23 · Second first-prize Judy product photo

- The latest Downloads photo is the second issue's prize: 朱迪侦探手办. Keep the
  first issue's 史迪奇公仔 and 魔法使's winning artwork unchanged. Use an issue-
  specific prize key, not a global replacement of the shared figure sprite.
- `COFFEE_WEEK02_PRIZE_2026-11-23.md` records the transparent cutout, built-in
  extraction prompt, PNG and small alpha WebP. The renderer reads the per-prize
  thumb when present and keeps the existing click-to-enlarge behavior.
- Publish both new main/data module filenames together, then HTML; preserve
  warm-cover-v4 and accepted layout-v4 CSS. Release backup/receipt: management
  `coffee-week02-prize-20261123`. No formal contest state or prize voting changes.

## 2026-11-23 · Annotated pale-tail removal and medium rear tail

- The user marked the lower-left PALE furry crescent as an old tail remnant.
  V2's supposed torso contour was wrong: remove the whole pointed pale appendage
  and fill with tabletop, leaving a compact round abdomen and the actual diagonal
  forearm to the saucer. Do not preserve that crescent as body fur in later edits.
- The real rear tail was then too short. User requested two modest extensions,
  then an intermediate length between those two, and explicitly asked to put it
  on site. Current v4 has one tail at the rear haunch, curving down beside the
  upper-right saucer above the handle. Do not make a full cup/foreground loop.
- Current master/derivatives use `warm-cover-original-v4.png`, `warm-cover-v4.webp`
  and `warm-cover-mobile-v4.webp`. Prompt/lineage: `WARM_COVER_EDIT_2026-11-22.md`.
  Layout-v4, 暖暖 title, QR bytes, partners and award data stay unchanged.
  Release backup: management `coffee-warm-tail-mid-20261123`, with the earlier
  `coffee-warm-tail-clean-20261123` release also retained.

## 2026-11-22 · 暖暖 fluffy fur and tucked tail

- The user rejected the first tail correction: repeated editing lost the original
  fluffy brushwork and produced a tail longer than the cat. Current v2 edits the
  ORIGINAL `siamese-cover-original.png` directly, preserving the original face,
  separated dry-brush fur and feathered edges. Tail is tucked beside the rear
  haunch; do not reintroduce the foreground ribbon or wrap it around the cup.
- Current assets are `warm-cover-{original-,mobile-,}v2.{png,webp}` (see the exact
  paths and built-in prompt in `WARM_COVER_EDIT_2026-11-22.md`). CSS/JS layout-v4,
  暖暖 title, QR bytes and award data are unchanged. Release backup/receipt is
  management `coffee-warm-fluffy-20261122`; old versions remain for rollback.

## 2026-11-22 · 暖暖 name and tail correction

- The user renamed the third theme to 暖暖. This supersedes 杯中暹罗 in visible
  copy, metadata and accessibility names. Keep the preview status and existing
  accepted layout; only the HTML and two new immutable WebP paths are published.
- `WARM_COVER_EDIT_2026-11-22.md` records built-in ImageGen lineage, saved master
  and final prompt. The tail has one visible root at the rear haunch and a free
  lower-center tip, separated from the head/neck and foreleg. Inspect anatomy in
  the whole illustration and in the actual page: the footer overlays its bottom.
- Release backup: management `coffee-warm-20261122`. Previous layout-v4 CSS/JS,
  logos, QR bytes and all two-issue award data remain unchanged. Formal event
  state still refers to issue2; this name edit does not open issue3 registration.

## 2026-11-22 · Third-cover layout correction

- The user rejected the third cover's changed layout. Preserve the previous
  issue's full-screen artwork and single bottom ticker structure; do not shrink
  the full artwork into a shorter frame with internal side gutters.
- Restore the footer's8% desktop proportion, with a108px floor for normal
  browser widths. Give work images, captions and prize leads independent widths;
  percentage-only thumbnail sizing plus a squeezed flex caption made titles
  break into tiny fragments. Each caption now has a bounded width, at most two
  title lines, and full text in its accessible button name and enlargement.
- Portrait tablets up to1100px need the existing phone flow. The old700px-only
  breakpoint left a centered miniature landscape canvas with large blank areas
  at977×1044. All matching responsive blocks must use the same breakpoint,
  including theme overrides and the direct action.
- `fix-coffee-third-layout.mbtx` publishes only new versioned CSS/JS and HTML,
  with a previous-HTML hash guard and retained old resources. No art, award,
  contest state or QR bytes change. Browser acceptance covers320px,977px and4K.
  Final live modules are `display-week03-layout-v4.{css,js}`; final HTML hash is
  `12d502991b84f7c45a1e2a38c11a11ef98f0059b699ed0ff243b394961ba0fdf`.
  Both layout release roots on management retain their own previous HTML;
  screenshots are in `output/coffee-third-layout-20261122`. Live4K footer height
  is172.8px, prize lead149.5px, with no card image/text overlap. Live390px keeps
  two132px QR frames and a48px CTA. Live977px starts at the page top and shows
  the direct action instead of a centered miniature TV canvas.

## 2026-11-22 · Third cover and previous-issue award display

- `COFFEE_THIRD_COVER_2026-11-22.md` records the 杯中暹罗 cover, organizer-confirmed
  second first-prize work, and eight explicitly labelled AI supplements. The user
  rejected 对味; do not revert that earlier name. No third schedule is implied.
- Keep one complete static artwork with only the established footer scrolling.
  Full-resolution winner images load on click. Preserve clear AI labels both on
  cards and in the enlargement dialog; never create fake votes or contestants.
- Bound ticker speed in px/s on phones: using viewport-relative speed alone made
  a390px two-issue cycle take629 seconds. The48px/s floor gives about61 seconds.
  Query-version both JS and imported data together when adding a shared export.
- Native voting publication cannot issue three awards with one0-vote entry.
  This task's organizer-selected display winner must not be represented as a
  successful vote-based backend settlement. Backups are in management's
  `coffee-third-cover-20261122{,-final}` directories.

## 2026-11-22 · Siamese coffee visual direction

- The user explicitly rejected animating two isolated cutouts before establishing
  the artwork. First finish one beautiful, cohesive full-scene master illustration;
  then develop motion from that scene. Preserve the direct overhead perspective
  and the two coffee-colored faces. Current still-v2 uses a curled full Siamese
  cat, paw/saucer contact, latte-art face and a shared morning window shadow.
- Preview-only image/prompt live in
  `output/double-half-awake-20261122/still-v2` of the original MoonTown checkout.
  Current source image is1672×941; do not label it as a finished native4K render.
  The old local animation preview server was stopped. Formal competition content,
  permissions and schedule were not changed.

## 2026-11-16 · Second-round transformation release

- Nov19 read-only participation audit: `gallery: []` means no approved public
  entries, not no submissions. The ordinary QA host has no formal-event manager
  permission, so its empty review queue cannot answer an all-submissions request.
  Read the authorized durable event state or an actual formal organizer snapshot;
  preserve superseded submissions when exporting the complete history.
- For unsubmitted-work attribution, join generation.actor to an entry.actor and
  label the result with that submission nickname; do not guess a profile name.
  Guest actors identify browser histories, not real people. Nov19 export excluded
  both historical submitted generation IDs and separated the known Nov16 acceptance
  image: 8 unsubmitted images share the 魔法使 submission account, 4 belong to one
  unclaimed guest identity, plus 1 assistant acceptance image. All originals were
  SHA-256 checked against the durable state before delivery.
- Nov19 the owner explicitly approved the current 魔法使 submission
  `c14d65aa…` (generation `87796696…`). The existing ordinary QA login correctly
  lacks formal organizer rights. Owner-authorized maintenance instead used the
  same exclusive state lock, approval guards, atomic save and review-event fields
  as the application, with an explicit `operations:owner-confirmed:20261119`
  audit actor. Backup/receipt: management `coffee-review-20261119-c14d65aa`.
  Revision46 became47; only this pending entry, its audit event and revision
  changed. Public API verified one visible approved entry; no account roles,
  contest times, older entry, generations or votes changed.
- Nov19 the configured `lunanexa-access` jump at port32122 closed connections.
  The pre-existing authenticated management jump on port32123 worked with an
  explicit SSH `-J` override, retaining the destination's existing host-key check.
  No SSH config, access role, approval state or network protection was changed.

- See `COFFEE_WEEK02_2026-11-16.md` for approved dates, immutable image pins,
  preserved first-round history, QA evidence and rollback locations. Canonical
  live route is `/town/`; legacy `/moontown/` redirects preserve acquisition query
  parameters. Public HTTPS uses 8443; only internal 443 was verified.
- New event IDs require event-scoped browser drafts/file caches. Preserve legacy
  first-round keys and migrate non-destructively only into that same event.
  Snapshot revisions may reset across events: reject stale revisions only within
  the same event, and invalidate older asynchronous restoration callbacks.
- `participant_account_ids: []` means deny every registered participant; omit the
  field for open admission. Explicit manager IDs are scoped to the QA event,
  never promoted into global organizer roles.
- Use explicit UTF-8 encoding for HTML bytes: String.to_bytes() yields raw UTF-16
  here. Hash equality alone cannot prove valid HTML. Check UTF-8 document content
  and actual browser rendering before considering publication complete.
- Standalone scripts are formatted with explicit `.mbtx` paths. A whole-workspace
  `moon fmt` can introduce unrelated formatting churn in local sibling projects.
  Production assembly requires npm dependencies plus built/assembled Landmark
  Studio models; do not bypass these checks or remove the preserved studio.
- Group QR `claim-group-20261116.jpg` is the user's latest supplied image, valid
  before Nov23, superseding the temporary community-account fallback. The group
  code and public community-account code have distinct purposes.
## 2026-11-16 · Crystal coffee close-up direction

- User's latest composition is a large anime woman's head facing the camera and sky, holding a crystalline coffee mug that refracts sunlight onto her face, shoulder and hair. This supersedes the ornate butterfly/princess treatment as the current candidate. Prefer expressive linework, bold light/dark shapes and the face/cup/light relationship; no jewelry overload.
- New sibling preview is `output/transformation-crystal-20261116`; retain the preceding two candidates. Use its dedicated4:5 phone composition so the face, cup, handle and fingers stay visible together, rather than cropping the landscape. Exact original marks, equal QR codes, transparent physical prizes and only the bottom8% grouped ticker remain. No live event, ranking or deployment change is implied by design iteration.

## 2026-11-15 · Sparkling transformation and physical prizes

- Latest visual direction supersedes the earlier flat-print rule below: the user now explicitly wants beautiful magical-girl transformation, sparkling jewels and iridescent wings. Preserve one full-screen composition and only the bottom8% grouped ticker; do not reintroduce the right banner.
- Use user-supplied physical prize photos, with transparent backgrounds. The tote is white in reality: correct the yellow/gray photo lighting while retaining fabric weave, folds, dark handles and original print. Keep handle holes transparent and remove the external jute display string. Do not expose the source WeChat filenames, which contain query identifiers.
- The figure cutout was blocked twice by image_gen output review; user explicitly approved local tools afterward. Local rembg2.0.87/BiRefNet-general-lite + ViTMatte + decontamination preserves the photographed plush, with FFmpeg alpha cleanup for its attached dark display tag. Final asset is `assets/prize-figure-real.png` (810×1040 RGBA), with a640px-highWebP derivative; no cloud cutout or generated replacement toy. Keep failed/intermediate mattes out of the user preview package.
- Local preview assets are in `output/transformation-banners-20261115`. Brand marks and QR codes remain exact separate assets; generated hero illustrations must leave their space quiet. Recompose phone typography around the face rather than overlaying it. This remains a design preview, with no backend award settlement or production release.

## 2026-11-15 · Final banner and award-preview direction

- Latest steering supersedes the right-banner experiments: remove the right banner entirely, keep the full-screen4K artwork, and use only a bottom continuous ticker at8% height. Group first/second/third prize artwork beside its corresponding prize, with content-sized cards and tight internal spacing. The large side panel and ultra-thin4.4% ticker were both rejected.
- User selected 小王's《深秋半醒，刚刚好》for the first-place display. Spoon/forest are third-place display works; user requested2 generated second-place works and1 simple generated third-place supplement. Final host AI works deliberately vary in style: ink《一盏未醒》, op art《醒来频率》, line drawing《早安，半醒》. Keep AI provenance visible; do not invent participant identities. This is local display configuration, not a backend settlement or approval change.
- Local files are at `output/transformation-banners-20261115`. Native uploads are used only on explicit enlargement; ticker images are derived384px WebP. Keep clone cycles hidden from assistive technology and out of keyboard traversal. All original brand/QR assets remain separate.

## 2026-11-15 · Art direction: mature flat graphic design

- Final display-format correction: each candidate is ONE full-bleed3840×2160,16:9 composition for the4K screen. The user rejected the impression of several portrait posters tiled together and separate stacked image/information bands. Recompose the whole scene horizontally; keep logos, equal QR codes and adjacent vertical prizes in intentional negative space. Do not stretch/crop a portrait or default to a gallery/rotation.
- The user rejected Nov14's cute coffee characters and Nov15's realistic oil-painting concepts. For subsequent campaign work, “艺术” means mature conceptual flat poster design: silhouette, collage, printmaking, restrained solid colors, negative space and integrated typography. Avoid photoreal anatomy, modeled lighting, 3D and childish illustration.
- Current two directions remain the user's own: a kneeling woman holding coffee with one butterfly wing free and the other emerging from silk; a seated person on a raised stage undergoing change amid storm/lightning. Clever details should be legible visual relationships, not claims about invisible microscopic details. New design files belong in `output/transformation-flat-20261115`; old cartoon and realistic drafts are superseded.

## 2026-11-14 · Transformation poster preview

- Local design deliverables live at `/Users/kq/Workspace/moontown/output/coffee-transform-20261114`; no production event or display was changed. Existing QR bytes still target the first activity: reconnect to the correct second-round entry before publication.
- Keep original brand marks and QR/prize assets separate from generated illustrations. Generated blank cup fronts can receive the exact native logo as a positioned PNG. A percentage-height square in an auto-sized grid can resolve from its width and overflow the invitation footer; explicitly position the square inside its measured artwork bounds, and inspect captions as well as the image.
- A buildless offline design preview should use a deferred classic script when it needs no modules, so opening index.html locally does not depend on file-origin ESM permissions.

## 2026-11-12 · Supplied Banxing raster and production coffee imports

- See `BANXING_LOGO_2026-11-12.md`. The supplied new logo supersedes v6: keep its complete cup, Chinese lettering and English line; remove white by pixel alpha detection, never redraw. The optimized PNG is960×934 and282734 bytes. Original is retained outside production allowlists.
- Nov11 moved management to192.168.2.173 and deployed an account-storage-scope runtime fix. UI releases must inherit the current qualified hosted-apps image and preserve the formal runtime `sha256:5baf6c9c2c930abf41ab2a4ba839adedf7cc80ee624145ccc64954928803325e`; do not deploy an older checkout's runtime during a brand change.
- Nov11's production assembly omitted `coffee-share.js` and `coffee-qr.js`, leaving the activity loading forever. Both assembly and required-file validation now include them. `coffee-package.test.js` follows the actual coffee ESM dependency graph and checks referenced image assets so a normal build cannot silently omit these files again. HTTP200 on HTML alone is insufficient: verify rendered event name and schedule.
- The local ffmpeg has no libwebp encoder. Use its lossless PNG encoder for this raster workflow. Browser viewport overrides affect the selected tab; inspect actual innerWidth and reset after acceptance.
## 2026-11-11 · Cluster refresh compatibility fix

This isolated checkout is on `codex/cluster-refresh-20261111`, based on fetched
main ef19c952. The production gateway normalizes tagged account digests into
the existing `account-<64 hex>` browser storage scope; retain the frontend's
strict isolation guard. Its real HTTP fixture checks the exact scope shape,
two-account separation, expiry and revocation. Focused native tests passed
3/3 and browser storage tests 7/7; the real signed-in public map loads.
The three application services/launch profiles were updated with state and
rollback backups. GLM remains stopped, so new private launches are still gated
on model readiness. Full release evidence and digests are recorded in
`/Users/kq/Workspace/moontown/docs/project/CLUSTER_REFRESH_20261111.md` and
`/home/HwHiAiUser/moon-public/work/products-20261111-r1` on management node .173.

## 2026-11-10 · Equal QR codes, vertical prizes and subtle motion

- `COFFEE_EQUAL_QR_2026-11-10.md` supersedes v10's unequal QR sizes and horizontal prizes. Both QR frames and captions must match; prizes are vertical beside the participation code. Phones stack the equal codes with prizes alongside. Keep the prize stack close on both desktop and phone.
- Measure visible label edges, not only container bounds: fixed trailing text widths can hide a large visual gap. Right-align the whole phone prize stack inside its grid column. Only illustrations wiggle; pause/play and reduced-motion preferences control them along with the original video.

## 2026-11-10 · Unified coffee invitation band

- `COFFEE_INVITATION_DESIGN_2026-11-10.md` supersedes the v9 surrounding-prize design below, which the user rejected. Use one orange footer with equal-size prize illustrations in a row and primary/secondary QR hierarchy; keep partners upper right. The mobile direct action precedes the QR row.
- Clip the baked-in video footer and render the invitation in HTML; do not force new controls into the original video footer's fixed space. Preserve every poster caption. QR/prize artwork keeps its native proportions; compare complete desktop composition and phone action placement before publication.

## 2026-11-10 · Display QR and partner swap

- See `COFFEE_DISPLAY_SWAP_2026-11-10.md`. Partners occupy the upper right; prize illustrations surround the participation QR in the lower right. Mobile partners precede the posters in DOM order. Keep the QR area transparent on desktop so the native orange stripe and English remain intact.
- Validate the entire fixed16:9 composition, especially the bottom QR caption and artwork captions, plus320px prize/QR gaps. Keep QR module quiet space inside the original image and its white frame; surrounding prizes must never cover it.

## 2026-11-09 · Suggested titles and approved sharing

- See `COFFEE_TITLES_SHARING_2026-11-09.md` for release, role walkthrough and checks. Gate sharing on membership in the current public gallery, not a stale private `approved` state. A withdrawn saved card cannot be recalled; its link must handle removal without revealing private content.
- Nickname memory is account-scoped across events; existing drafts remain event/account-scoped. Async nickname restoration must not overwrite new typing or another identity. Suggested titles must use the selected generation's prompt; ignore color words such as 森林绿 when detecting themes.
- Load QR encoding on demand and render integer modules with a four-module quiet zone. Keep sharing on an explicit click after PNG preparation for mobile user activation, with download/link fallbacks. Inspect actual GET responses after rollout; this server's HEAD probes returned empty replies/502 and were not useful availability evidence.

## 2026-11-09 · Prizes, default creation and claim-group flow

- See `COFFEE_PRIZES_CLAIM_2026-11-09.md` for assets, exact release and acceptance. Keep group QR bytes intact; CSS cropping and downloading the full original are separate concerns. This invitation says valid before Nov16, so expiry is conservative at Nov16 00:00 CST.
- Never hide a creator's own work because public gallery approval is pending or rejected. Default to the personal wall when private records exist, and place the latest review state on each image. Only public gallery exposure remains approval-gated.
- A local HTTP preview must strip query strings before filesystem resolution: versioned CSS otherwise 404s and shows an unstyled video. On macOS a stopped test listener can briefly remain unavailable; inspect listeners rather than repeatedly retrying the same port.
- Package only after final small-screen button checks. Long primary labels can wrap in a two-button QR dialog on 320px screens; “查看作品” keeps the next action concise. Formal asset-only updates preserve creative state; verified revision35 and all prior IDs after rollout.

## 2026-11-09 · Contact registration and stacked display mark

- The user's final choice is the original stacked 半醒工坊 logo. v6 rasterizes the entire original SVG without rearranging glyphs; it supersedes the single-line v5 note below.
- See `COFFEE_CONTACT_REGISTRATION_2026-11-09.md`. Attribution uses its own first-touch cookie, never draft or image-cache keys; it is untrusted marketing metadata, not authorization.
- Management kubelet has 5% eviction thresholds plus 10% minimum reclaim and a five-minute transition period. DiskPressure recovery needs roughly 15% free, not just the 5% threshold. Remove only reviewed inactive image export caches; retain source, executable/venv symlinks, PVCs, models and rollback releases.
- Check standalone release scripts with `moon check path.mbtx` before upload. Source overlays exported from macOS need `COPYFILE_DISABLE=1` and `--no-xattrs`; AppleDouble `._*.mbt` files break Linux package compilation. Native Linux builds must use the current moonleaf sibling containing CSV, not an older release sibling.
## 2026-11-19 · Read-only worker access review

- Audited.176/.177/.178/.179 through existing management SSH, without changing
  services, access controls, keys, deployment or models. No.191/build-VM action.
  User explicitly treats192.168.2.x access as expected; do not flag.6's older
  password sessions as suspicious solely from the address.
- Nov19 00:00–21:00 China time:4,151 external failed-password records on.176,
  19,337 on.179; none on.177/.178 in retained records. Automated guessing is
  ongoing. No successful public-IP login found in the retained histories;
  do not equate failed attempts or TCP established state with compromise.
- Large successful SSH volume from.173 on.178/.179 matches management key and
  system unit lunanexa-glm-control.service/PID1265. Its native observation
  launches per-target SSH queries, both during2-second monitoring and status
  requests. This creates70k/day logins per node; no optimization applied here.
- Evidence/report:output/node-access-audit-20261119/REPORT.md. Retention differs:
  .178/.179 success journals startNov14, not the full requestedNov12 interval.
  Helpers stayed in exact /tmp task paths on management, no worker install.
- Analysis pitfall: current StringView Compare orders by length first. Use
  lexical_compare for timestamp bounds; ordinary comparison against a short
  date cutoff wrongly discards longer log lines. Final history-r3 summaries
  correct that analysis-only bug; earlier history summaries are superseded.
- Ingress follow-up21:14: bounded header-only tcpdump on.179 enP7s7 captured
  six public-source SYNs to192.168.2.179:22. All Ethernet source MACs match
  gateway192.168.2.1/b8:27:c5:bb:5b:f9. This proves upstream wired IPv4 ingress,
  not website/Wi-Fi/public IPv6 exposure. Exact NAT/DMZ/automatic rule remains
  unconfirmed; router admin page requires login. Do not claim user published
  SSH or assume UPnP/DMZ is enabled without reading authenticated settings.
  Management NAT search found only relevant80/443 web rules, no worker SSH
  forward. Public32123 is management; limited other-port probes were negative
  and do not rule out other ports/WANs. No network or service change.
- User then disabled mappings.120-second.176/.179 header-only captures saw
  zero new external SYNs and no new external SSH auth events in the window;
  management SSH to all four and public8443 lead/userHTTP200 remain working.
  Do not call the short observation exhaustive proof of all closed ports.
- ExplicitNov5–19 search for192.168.110.x found no SSH/auth/wtmp/btmp/current
  connection evidence on all four or management.173. Own sudo/zgrep query
  strings are not connection evidence. .176/.177 journals include the period;
  .178/.179 detailed journals beginNov14, so earlier successful non-PTY SSH
  access cannot be excluded from surviving wtmp/btmp alone. Management journal
  beginsNov6. Evidence and exact coverage are appended to the same report.
- Month extensionOct19–Nov19: old btmp archives show sustained public guessing
  in October on.176/.179 and management.173. Retained failed SSH records total
  473,211/.176,783,526/.179,218,743/.173 (not unique attempts). .177/.178 show
  only expected LAN failed records. Worker last external failures21:16:39/45;
  management still under guessing at21:38 and still permits external password
  auth (root SSH disabled). No access restriction applied during this review.
- Management successful public-key sources all match this Mac's existing SEMq
  fingerprint. Own-public-IP password sessions require qualified reporting:
  .176 has143 onNov9 10:29–16:01, paired with103 management password sessions
  from.176; management has one own-public-IP password sessionOct26. Likely
  relay/hairpin maintenance is an inference; original operator is not proved
  by NAT-masked source alone. No successful login from guessing IPs or unknown
  key found. .178/.179 earlier detailed-success coverage remains missing.
- Management rotated auth files use traditional Oct/Nov timestamps; normalize
  these rather than discarding them as non-ISO. Only172.16–31 is private,
  not all172.x; initial helper diagnostic label corrected, counts unchanged.
  Month evidence appended to output/node-access-audit-20261119/REPORT.md.

Read this with `AGENTS.md` before starting work. Keep task evidence in its
existing documentation and record concrete pitfalls here.

## 2026-11-09 · Display partner correction v5

- This supersedes the v4 partner treatment recorded below. The group mark must
  come from the user's original group-logo.jpg raster, cropping the newer mark
  and detecting near-white pixels for alpha; do not substitute vector tracing.
  group-mark-raster-v5.png is 196×218 with alpha=0 at its background corner.
- Coffee contour indexes are not glyph IDs: a later contour may be a counter
  inside the preceding letter. Group complete glyphs by spatial bounds, align
  all four to one baseline, then rasterize; banxing-single-line-v5.png retains
  the original cup/letter contours. The sticker uses its original filled SVG,
  not the unfilled v2. The two PNGs total about 70 KiB.
- prepare-coffee-partner-rasters.mbtx pins both source hashes. Packaged manifest
  SHA256 is d31e9a1c7a6c5b668918d0e5bc74c33c31c8a3302ed72650447d9a7ec4d755cd.
  New assets, CSS, then HTML were published atomically; old HTML/CSS are kept in
  /home/HwHiAiUser/moontown-display-20261108/copy-partners-v5/. No service restart,
  video replacement, account/contest change or QR modification was needed.
- Live desktop 1920×1080 and phone 375×812 render all six images, no overflow;
  local 320×740 also has no overflow and retains its 48px CTA. Phone selects HD,
  desktop 4K. Both 443/8443 checks passed exact HTML/CSS/logo/QR byte comparison,
  video Range 206 and participant page 200 (verification-v5.json on management).
  Screenshots: output/coffee-disp-20261109/{desktop,mobile}-raster-partners-v5.png
  and partner-detail-v5.png. CSS cache key is 20261109-partners-5.

## 2026-11-09 · Guest creation and authenticated participation

- See `COFFEE_PARTICIPATION_2026-11-09.md` for actual acceptance and immutable
  deployed digests. Root native 2,072/2,072, gateway 10/10, browser 192/192.
- platform-base scopes localStorage by identity. Use IndexedDB as canonical
  draft text storage plus synchronous localStorage backup; localStorage alone
  loses the guest-to-account handoff after reload. Never delete the old account
  draft when switching. Pending uploads remain private IndexedDB Blobs until a
  confirmed response; stable intents survive uncertain network outcomes.
- Guest capabilities must be event-scoped Secure/HttpOnly cookies and expire
  after an atomic claim. Worker completion must use the CURRENT durable job,
  not its dispatch-time actor: login can claim a running job before it finishes.
- Rebuild allowlisted uploaded image pixels before persistence. Bound bytes,
  decoded pixels and concurrent bodies; do not serve original uploads or claim
  this is an antivirus engine. Public visibility still requires explicit review.
  JPEG requires `-ljpeg` in every native executable consumer, not only the FFI
  package. Production uses private official libjpeg-turbo 3.2.1 libs and license.
- Native HTTP cookies live in Response.cookies, not its raw headers map. Use
  send_response(cookies=...) and test parsed cookies. Dynamic activity routing
  must forward thumb/preview paths as well as original images.
- A sparse worktree without tilemap breaks the editor movement contract test;
  the full browser asset suite also needs existing ignored landmark-studio
  runtime assets. Restore those inputs before interpreting broad failures.
  A new compiler's root fmt/info can touch hundreds of unrelated files; retain
  only changed-package outputs and inspect all generated interfaces.
- GUI fixture public roots must use canonical `/private/tmp/...` paths: the
  strict immutable-root guard correctly rejects a `/tmp` symlink. Rehearsal
  state retention is limited to `/private/tmp/coffee-participation-*`. Verify
  actual innerWidth before labeling screenshots mobile; viewport overrides
  affect the currently selected browser tab. Allow smooth anchor scrolling to
  settle before capture. Retained fixture screenshots are not real GPU evidence.
- Production UI deploy defaults to formal when its optional deployment argument
  is omitted; it deliberately rejects an explicit formal name. Preserve stale
  gzip/ETag invalidation when overlaying UI assets. Runtime upgrades require
  stopping writers and verifying both complete PVC backups before resuming.
## 原镇路网与校岸结果

原镇默认入口曾把左堤路用零平移、单位缩放重新生成，审查图里的校正没有进游戏。生产构建现在通过 `scripts/rebuild-wenyu-bank.mbtx` 重放 `wenyu-major-road-fit.json`，一次生成道路图层、步行和车行轨迹、街坊地块、镇内导航与外围出口。冻结的 `wenyu-bank-node-overrides.json` 和 `wenyu-bank-surface-audit.json` 是拟合基线，不要用最终产物覆盖。新路口使用按保存的连接树拆分的节点；真实桥面保留原坐标。云谷东西两街坊共用创元路与北侧骑行道的五个定位点，引用分叉路口时须用 OSM 道路和原节点的组合。

原镇普通路面含连接段的累计压水由 493.78 格降至 308.53 格。左堤路 47518902 的 63 个顶点保留，84.54 格降至 0；其他同名路段仍有压水。详见 [镇图验算](wenyu-town-road-audit.json)。从原镇 `?view=overview&road=47518902` 查看这一段，地图设置里的「路网复核」标出全镇剩余压水（红线）、新增交叉（紫圈）、缺失交叉（紫叉）。复核数据按需加载。

## A21 与星科地块配准

镇图、全域图、独立 3D 是三个验收入口。项目目录里有条目或区域图里有体量，均不能作为镇图落位计数。星科老总平少一栋，单 POI 尺度失真。现用两个影像窗口并指定五个路口，三个拟合、两个验证。A21 图纸以北为上，斜视影像的高楼屋顶相对基座有视差。模型以基座排布，两个渲染入口共用地理原点。改模型或相机后须重新烘焙两套投影，再从两个项目的镇图链接验收。[本轮依据](science-city-building-review.md#site-vision)

## 2026-11-07 · 20-user coffee load test

- Read `COFFEE_LOAD20_2026-11-07.md`. Twenty real ordinary sessions submitted
  within 2ms; all twenty distinct images completed. The formal-first-event
  creative path was cloned into an isolated instance; this is not a benchmark
  of twenty physical browsers or twenty concurrent Book launches.
- The worker and image adapter serialize inference. Median execution was 8.56s,
  but median user-visible completion was 105.20s and the tail 204.12s. Do not
  equate twenty accepted jobs with twenty GPU executions.
- Forty of 620 authenticated polls returned 503 in two waves near the 3500ms
  identity budget; subsequent polls recovered. Idle read-only replay was 80/80.
  Diagnose the auth dependency before claiming the concurrent UX is ready.
  Do not cache completed authorization to hide this while breaking revocation.
- First image-download verification retained one truncated file; a download-only
  replay passed 20/20 without GPU resubmission. A load tool must persist all
  response/transport errors before failing; early task-group cancellation loses
  diagnostic evidence and must not be mistaken for a complete success report.
- Test route/policies removed, dedicated deployment scaled to zero, PVC and
  evidence retained. Existing formal/QA events and model settings were untouched.

## Integration and UI rules, 2026-11-06

- `AGENTS.md` now carries MoonDesk's working style and UI/UX guidance, adapted
  to MoonTown's source layout, icons, shared styles and project-note location.
- The R560 timestamp stash is already present in main: the MoonBook client,
  numeric timestamp contracts and snapshot regression tests match its saved
  content. R792 preservation commits carry no additional source changes.
  Their branches are reconciled in main without replacing newer code.
- Run browser-side Node tests with an explicit source pattern:
  `node --test *.test.js styles/*.test.js` from `src/ui/rabbita-town`.
  Bare `node --test` also discovers generated MoonBit test drivers in `_build`;
  those require the MoonBit runner and fail under Node's test protocol.
- Use `moon run scripts/test-rabbita-sharded.mbtx 4 8` for the large Rabbita
  suite. It builds once and runs bounded batches. Native commands sharing
  `_build` serialize on Moon's lock; avoid launching redundant native builds.
- `output/` contains local screenshots, logs and document exports, including
  unrelated PDF review materials. It is ignored and retained locally.
  `evidence/R796` preserves the feature worker's original diagnostic evidence;
  diagnostic diagram whitespace is intentional.
- Cross-dossier research uses one save action for the current selection mode.
  The existing unsaved-draft guard applies to both modes, and busy saves disable
  cancellation. Keep the Chinese controls and provenance disclosure together.
- Full native acceptance needs `MOONTOWN_MOONCLAW_BIN` pointing to the built
  local `cmd/oneoff_fixture` and `MOONTOWN_BOOK_OUTCOME_BIN` pointing to the
  built Book `cmd/outcome_lessons`. Use the fixture, never a real provider.
  Final native 2026/2026, Rabbita 194 files/25 batches and browser source
  177/177 passed. Earlier transfer-deadline and reviewer-source tests failed
  intermittently, then passed isolated and in the final full run; see
  `MAIN_INTEGRATION_2026-11-06.md` for the actual sequence.

## 2026-11-07 · 半醒咖啡首期

- The published creation page is `/moontown/coffee-contest.html` on the existing
  8443 public origin. Use `BANXING_COFFEE_IMPLEMENTATION.md` for current facts,
  qualification measurements and remaining real-account/prize/voting work.
- The source visuals and reusable curator live in the private registered
  `banxing-coffee-curator` MoonBook; do not copy original posters into a contest
  gallery as submissions. Portable media use `portable/outputs/`, not `raw/`.
- Only 177 changed its Qwen reservation and device-plugin profile, with explicit
  user authorization. CPU adapters, event code and credentials remain on 175.
  Fresh-seed warm images took about 8.1s; text latency increased during overlap.
- Package static UI from the existing web base: the native gateway base lacks
  `/bin/cp`. Public deployment uses one replica and maxSurge=0. Exclude macOS
  AppleDouble files when exporting MoonBit sources to Linux.
- The private UI harness can use a loopback qualified provider only when its
  explicit rehearsal environment is present. Test logins remain `_wbtest` code,
  never production auth. Real images plus A/B/moderation/withdrawal were tested;
  real SSO accounts still need the owner's participation.
- Current acceptance: native 2035/2035, gateway 8/8, browser JS 180/180 and the
  unchanged 194-file Rabbita batch suite passed. A same-seed cache hit is not
  a fresh-generation benchmark. Downloaded PNGs have a visible AI footer and
  structured AIGC metadata. State backup extraction matched its source bytes.

## 2026-11-07 · 手机端精简复核

- Keep the established cream/green coffee page. The hero, prompt and generation
  action fit a 320×568 viewport, including the private rehearsal banner. Keep
  rules/prizes collapsed, an empty result area hidden on mobile, 44px touch
  targets and 16px form inputs. Do not add a fixed footer above the keyboard.
- Submission dialogs follow visualViewport and retain a sticky close control
  while scrolling. Verified a 375×400 contracted viewport, not a real iOS/Android
  keyboard. The gallery opens an accessible, AI-labelled image dialog; landscape
  812×375 was checked. New generations select the newest image and focus the
  result on mobile without interrupting someone typing into another field.
- For visual QA, the `_wbtest` harness can load an explicit local base64 image
  only in rehearsal mode. Its banner says static sample/no GPU. Never describe
  that path as fresh inference or ship its test login routes in production.
- UI-only releases use `deploy-account-ui.mbtx`: compare resourceVersion and
  previous digest, back up privately and patch only the public-assets image.
- This pass: browser JS 180/180, isolated gateway native 184/184, production
  artifact 797 files verified. `moon info`/`moon fmt` passed in the isolated
  dependency closure; the shared workspace info command encounters unrelated
  in-progress dependency errors. Do not rewrite neighbouring projects to fix
  those while making this UI change.

## 2026-11-07 · 真实账户三方手机验收

- Read `COFFEE_MOBILE_JOURNEY_2026-11-07.md` and `ORGANIZER_ACTIVITY_PROPOSAL.md`.
  QA lives under `/coffee-qa/` with an independent state PVC, three invited
  ordinary accounts and an event-only manager. Never grant PlatformOperator
  merely to test organizing; the QA host's formal-event mutation returned 403.
- Registration can create the identity then return TrialProvisioningPending.
  The coffee page now uses the existing same-origin identity gateway in a
  dialog and tries one normal login after registration 503; never blindly
  register again. A fresh real signup verified this recovery. The general
  portal's trial initialization remains a LunaNexa issue.
- A/B each generated one real image (7.7 / 8.6 seconds), submitted, and the host
  approved A, rejected B, then approved B's revised title without a new image.
  Exported CSV contained exactly those two approved entries. Preview selections
  did not change revision 13; there is still no real counting or live leaderboard.
- UI now prioritizes pending reviews for hosts and voting after the deadline.
  State-dependent controls must update even when the data revision is unchanged.
  Preserve private drafts, but hide unusable prompt forms after closure.
- Verify the actual DOM viewport dimensions when using browser overrides; the
  capability targets the selected tab. A request to resize another tab is not
  evidence that it changed. This pass checked real 375×400 DOM bounds, not a
  physical mobile keyboard.
- Static UI digest is `4e95f7cc5e51f5ab628c8253c51e1ad85a64134d346a06bce3640789e9814655`.
  The formal native service remains fdb14e92…; scoped delegation is active only
  in QA runtime 98e8924e…. GPU services were unchanged. Focused gateway closure
  187/187, browser JS 180/180, 800 static files verified.
- For Linux builds, export a fresh dependency closure without AppleDouble or
  caches and target `src/main`; building every package in the reduced workspace
  can attempt to link dependency libraries as executables. Keep sources and
  credentials out of the UI layer and use the existing web base for its copier.

## 2026-11-07 · 主办申请、真实 Book 落地与站内投票

- Current evidence is `ACTIVITY_LAUNCH_ACCEPTANCE_2026-11-07.md`; earlier mobile
  journey/implementation/proposal files are historical snapshots. The expanded
  flow is deployed formally and verified end-to-end in isolated QA. Natural
  13:30 voting passed vote/cancel/revote and the two-entry live tie; natural
  13:35 close sealed settlement 16 / roster 11. No three-award result was published.
- Ordinary A submitted a bounded two-event application; the QA scoped approver
  granted 4 total generations / 2 per event / 2 per participant, cash 0 and
  allow_publish=false. A completed the three-step workbook; actual native Book
  readiness preceded preview and the independent host's publication. A/B each
  generated and submitted a real new image; the host approved both. B's actual
  UI exposed no A private preview or organizer entry; A's self-review stayed
  disabled. HTTP 403/404 isolation assertions are separate regression evidence.
- Activity Book imports are real, immutable and resumable. The 1.2.0 thin runtime
  preset retains source methods/provenance without duplicating 1.1.0's media.
  Actual Linux import fell from 869,216 KiB / 9.55s to 20,228 KiB / 1.50s. Ship
  the trusted CLI with seed/ and configure book_cli_cwd; never fake Book init.
  The curated profile is configured-not-started and needs a runtime grant.
- ConfigMap projected files are symlinks; use individual subPath mounts for the
  strict regular-file configuration reader. After vote-state schema changes,
  never resume an old native writer against the new state; it can discard fields.
- Keep success/error feedback current, derive dynamic dates/quotas from the
  selected activity and invalidate stale identity responses when switching users.
  Quota exhaustion copy must distinguish personal and event limits.
- Validate grant time after the body is read, using a fresh server clock; the
  actual streamed-body regression returns 403. Hotfix native image 62213c1b… is
  deployed formally and in QA (Ready 1/1). After upgrade QA retains settlement
  16 / 2 votes / the same f9afbe6e… digest and the second event's 2 remaining uses.
- Focused native 44/44 (11 program, 5 bridge, 19 creative, 9 gateway), browser JS
  190/190; static package 809 files / 72.1 MiB. Both native digests are 62213c1b…;
  final UI v3 4914aeaf… is deployed formally and to QA. This is not a full-suite run.
- Formal program registry returns 200 and is empty; no QA approver allowlist was
  copied. The logged-in QA host sees New proposal, not approval controls. The
  existing formal event changed only voting_mode under an exclusive backup guard;
  all other configuration deep-equals its prior value. It has no votes or gallery
  entries and retains 500 generations. New program template limits are separate.
- For the QA hotfix, stop the writer before backing up both complete PVCs through
  a read-only UID 1000 Pod. kubectl cp, archive digest and restored terminal state
  were verified; root access fallback was not used. Private 175 archives remain
  in qa-runtime-final-apply with mode 0600; the owned backup Pod was deleted.
  Formal backup guards record state-file presence/absence rather than inventing
  an empty state file when none existed.
- Still bounded to the coffee template and three awards. No automatic MoonClaw
  jobs, payments, anti-Sybil identity or monthly reset; physical mobile keyboard
  testing remains outstanding. Do not turn those proposal items into claims.

## 2026-11-08 · Coffee queue, image variants and authentication diagnosis

- Current work/evidence: `COFFEE_AUTH_QUEUE_LOAD20_2026-11-07.md`. Runtime
  b760272c… and UI 7dccb07f… are deployed formally and in QA. They retain the
  real MoonBook CLI/seed/1.2.0 curator package. Original PNGs remain unchanged;
  gallery/history use 384px WebPs, review/results 768px, explicit zoom/save use
  originals. Approved media checks current visibility without repeated identity
  HTTP calls; private variants and withdrawal retain the same ACL.
- Native libpng/libwebp flags must preserve `-pthread -ldl` in executable/test
  consumers. Ship libm as well as libpng/webp/zlib. Normalize OCI layer directory
  modes; async mkdir under host umask can produce 0750 despite requesting 0755.
  Explicitly chmod nonroot hostPath executable directories. Startup failures in
  private candidates were rolled back before any inference or state write.
- Thumbnail backfill never resubmits inference or rewrites event/vote state.
  The bounded cache remembers only derivative presence, never authorization;
  missing media reads invalidate it for repair. R5's 20.35 MB originals became
  0.20 MB thumbnails / 0.55 MB previews. A 400-image, twenty-visitor public load
  succeeded; this does not qualify the separate live identity pipeline.
- Auth latency has multiple layers: account authorize used to persist a whole
  snapshot on every read; global 30s activity checkpoints retain fresh role and
  revocation checks. Browser gateway session I/O was synchronous and serialized;
  use the existing async PgPool. GET profile responses must not wait for durable
  operational metrics; mutations retain their existing audit order. Preserve
  the internal TLS service alias, strict origin and unchanged 3500ms deadline.
- Retain failed iterations. R2/R3 had 20/49 HTTP503s, R4 had one timed-out image
  body, R5 had 150 profile-stage HTTP503s despite all 20 generations/images
  completing. Do not call these a passing end-to-end load test. R3/R4 are stopped
  with public routes/policies removed and PVC evidence retained.
- Native database test URLs must name a disposable *_test database. A management
  host cannot resolve cluster DNS; use the verified service IP for host-side
  tests. The session-pool regression passed against lunanexa_test. Large native
  API test linking needed `ulimit -s 65536` to avoid a compiler stack overflow.
- Formal programme registry may legitimately be absent. Accept absence only for
  a wholly empty programme volume (apart from an empty regular registry.lock),
  preserve it, and back up both full PVCs. Failed/Succeeded historical Pods are
  not active writers and must not block a stop-and-backup wait forever.
- Final paired controller 7bef5632… / browser gateway 2c973649… retains both auth
  fixes. A later controller release had overwritten checkpoint source; final
  build receipts now pin both source hashes and the executable. LunaNexa main
  0685c0e is on both remotes; its strict native check and full 1,959-test suite
  passed. The local LunaNexa checkout was fast-forwarded without touching its
  unrelated dirty files. Session/profile P95 is 42/57ms; 1,000 reads had no 503.
- R6 completes twenty distinct new images (20 concurrent admissions in 1ms),
  all forty WebPs and 1,147 HTTP200s / no 503. One original body still timed out
  after HTTP200; first hashes were 19/20, download recheck 20/20. HTTP/1.1's
  twenty originals succeeded first time; HTTP/2 recovered one timeout with a
  single retry. Retain these attempts; do not describe all original first loads
  as successful or infer the exact client/proxy/network fault from this alone.
- Final zoom/save uses one bounded image-only retry, cancellation on close or
  identity change, and explicit recovery. It does not retry authorization errors
  or inference. Queue status hides exhausted-quota copy while a job is pending.
  Browser tests are 194/194; actual mobile zoom/save verification is recorded in
  the report. Await build/transfer completion and verify archive hashes before
  OCI packaging: a private empty-UI candidate was rejected before publication.
- R2/R3/R4/R6 routes and added policies are removed, replicas zero, all PVCs and
  evidence retained. R5 remains the single twenty-work public example, with
  twenty votes naturally sealed. Formal still has no public entries/programme
  activities and retains 500 generations. Only the final OCI archives/caches
  and state backups are needed; superseded generated OCI caches were cleaned.
- Final MoonTown native suite is **2,067/2,067**, browser source **194/194**.
  Provide the two documented Claw/Book fixture variables above; without them,
  six crossings correctly refuse to run. Do not substitute a real provider.
  Use `--jobs 2` when development disk headroom is tight. The first broad run
  exhausted local storage; `moon clean` removed owned generated caches, and the
  bounded complete rerun passed. Root async 0.16.6 defaults file writes
  differently from gateway 0.22.4: explicitly select creation modes in preview
  writes and fixtures. Production's effective CreateOrTruncate behavior is the
  same. Generated .mbti changes are the new image variants/preview API only.
- Mobile review/ranking inspection: R5 now has zero pending entries; distinguish
  its archived real twenty-pending screenshot from the current sealed activity.
  Do not reopen votes or reverse approvals for screenshots. Remaining UX gaps
  are always-visible review textareas, equal approve/reject styling and ranking
  titles without a way to inspect their artwork. Details/captures are in the
  existing report. These are findings, not implemented changes.

## 2026-11-08 · Mobile review and vote-based prizes

- Work branch `codex/coffee-mobile-review-voting`; QA and the v2 rehearsal have
  runtime 1c409d85… / UI 73170424…. Formal and main remain unchanged until
  phone acceptance. Browser transport is closed; no new screenshots exist.
- Review opinions are disclosed on return, approval is primary, ranking rows
  open artwork. Built-in prizes derive from sealed ranks; ties, insufficient
  votes and withdrawn sealed winners block publication. External voting keeps
  manual verification. Native 2070/2070 and frontend source 192/192 passed.
- The v2 real API journey completed twenty submissions/approvals/voters and
  naturally sealed 9/6/5, then published three test prizes. Reused real R6 images,
  no inference. The earlier zero-vote rehearsal is stopped with evidence kept.
- Derive rehearsal schedules from a fresh host clock and wait on HTTP server
  time; script clock drift closed the first window. Exclude AppleDouble files
  with COPYFILE_DISABLE=1 and tar --no-xattrs. Build gateway src/main explicitly;
  building all workspace library packages can try to link executables without
  main. Use qualified Linux PNG/WebP include/link directories. See the report.
## 2026-11-08 · Coffee rotation display at /disp

- Source `src/ui/coffee-display`; original 17-style, 9+8 opposed-row 12-second
  animation is preserved. Desktop gets the exact original 4K MP4; phones get a
  1,039,830-byte 1080p rendition. QR SVG and both visible links point to the
  formal `https://suanli.kechuangfuwu.com:8443/moontown/coffee-contest.html`.
- Live backend is the unprivileged user service `moontown-coffee-display.service`
  on 175:18089. User linger is enabled. Its official NGINX runtime is verified
  from OCI manifest 7b5016a1…; files/config live in the private management release
  `/home/HwHiAiUser/moontown-display-20261108`. It uses no GPU or account token.
- Existing Traefik TLS exposes `/disp` and `/disp/`. The display Service has no
  selector and mirrors a single explicit Endpoints address, 192.168.2.175:18089.
  Never replace the missing selector with `{}` (which could select other Pods).
  The failed container candidate is scaled to zero; manifests/evidence retained.
- Direct external image pulls hung and serialized the node's pull queue. Do not
  restart the shared runtime to serve this display. The official amd64 image was
  fetched with crane, blob hashes verified and mirrored in the internal registry;
  rootless NGINX avoids the unavailable container pull path. Runtime limits are
  declared, but this user's legacy cgroup did not report MemoryCurrent; do not
  claim that those limits were measured or enforced.
- Under systemd's journal socket, `/dev/stderr` and `/dev/stdout` cannot be
  reopened as ordinary log files. Host config uses `error_log stderr` and
  `access_log off`, with `-e stderr` during startup. Read UTF-8 manifests through
  fs Data.text(), not Bytes.to_unchecked_string(). Check before mkdir on an
  existing directory even with recursive=true.
- Verified from 175: HTTPS 443/8443 both return 200, `/disp` redirects to `/disp/`,
  SVG matches exactly and video byte requests return 206/1024 bytes. The local
  external 443 probe failed TLS, while the actual browser verified 8443; retain
  the explicit 8443 public link and do not infer global 443 reachability from
  the management probe alone. No TLS validation was bypassed.
- Actual browser acceptance: 320/375px without overflow, 48px phone CTA, phone
  HD and desktop 4K playback, pause/resume, QR visibility and navigation into the
  formal first event. Captures are in output/coffee-disp-20261108. Browser access
  recovered for this display; the separate mobile moderation branch a9f8aa12 is
  still pending its own complete phone journey and is not part of this release.
- Display copy follow-up: HTML now supplies the requested Chinese event title,
  masks the video's baked-in English heading/footer and adds three partner marks.
  Mobile crops only those video text bands; both poster rows remain. Official
  company assets are byte copies from LunaNexa; the new group mark uses the same
  CSS crop as its public site (the source JPG is an old/new comparison, not a
  standalone logo). Half-awake keeps the cup's existing extracted SVG contours;
  Vector Sticker is a new editable SVG wordmark draft. Avoid font substitution
  for the cup logo. Explicit `left: 0` is required on the absolutely positioned
  company wordmark image; centered inline static positioning otherwise clips it.
- `update-coffee-display-copy.mbtx` validates a pinned 11-file manifest and old
  HTML/CSS hashes, preserves private rollback copies and publishes four new brand
  assets, CSS, then HTML. It changes no GPU, routing, login or service runtime.
  Verification now compares served branding and stylesheet bytes on both TLS
  ports in addition to QR, Range and participation checks.
- This copy/brand release passed management-side 443/8443 byte comparisons and
  actual public 8443 desktop/mobile acceptance. Checked 320/375px without horizontal
  overflow, all five images loaded, 48px mobile CTA and pause/play. New captures:
  output/coffee-disp-20261108/{desktop,mobile}-title-brands-v2.jpg.
- User correction: preserve the original orange invitation banner and its two
  English lines. The previous full-width brand overlay incorrectly replaced
  that content. The event-series heading is now 1.75cqw (was 3cqw), and the
  partner marks are compact and right-aligned inside the orange area. Desktop
  exposes the original video footer without a masking background; mobile
  reflows the same invitation in HTML, with small right-aligned partners below.
  Keep the top English subtitle removed. Publish only HTML/CSS; original video,
  QR, brand files and display runtime remain unchanged. The pinned copy updater
  now targets copy-footer-v3 and preserves the preceding v2 HTML/CSS for rollback.
- Footer v3 acceptance: checked desktop 1920×1080 plus mobile 320/375px;
  no overflow, all images loaded, mobile CTA remains 48px. Management 443/8443
  checks pass for exact HTML/CSS/brand/QR bytes, video 206 and participant 200.
  Public browser needed a normal reload to invalidate its cached v2 document;
  stylesheet URL is display.css?v=20261108-footer-3. Captures:
  output/coffee-disp-20261108/{desktop,mobile}-orange-footer-v3.jpg.
- Partner/community follow-up: use the existing LunaNexa official vector sheet
  (pinned SHA395701ab…) with a viewBox around its newer mark. This provides true
  transparent blue paths without changing hue through CSS multiplication. The
  sticker SVG's cream fill is now none, and the extra partnership label is gone.
  Company, coffee and sticker text now have matching optical heights. Coffee's
  complete original contour groups are arranged horizontally with their counters
  intact; do not split the original curved lettering with a rectangular crop.
  `prepare-coffee-partner-vectors.mbtx` pins source hashes and regenerates SVGs.
- Community QR is an exact copy of the user's supplied PNG, SHA8911f1e3…;
  CSS crops its caption, preserving the complete code and at least four modules
  of white margin. Display labels distinguish participation from community.
  Mobile shows two equal QR frames above the full-width 48px entry button.
  Never remove white quiet margins from QR images while removing logo backgrounds.
- Copy updater targets copy-partners-v4, pinned 12-file manifest, and v3 source
  hashes. It adds three SVGs and the QR, then CSS and HTML; private backups remain
  in the release folder. Media, login, routing and service processes are unchanged.
- V4 acceptance: actual desktop 1920×1080 and phone 320/375px have no horizontal
  overflow; all six images load, CTA is 48px, both QR captions are distinct.
  Public 8443 displays transparent blue group paths, unfilled sticker interior,
  complete coffee lettering and no partnership label. Management 443/8443 passed
  exact served HTML/CSS/brand/community/participation QR comparisons, video Range
  206 and participant page 200. Captures are
  output/coffee-disp-20261108/{desktop,mobile}-community-transparent-v4.jpg.
  QR source and deployed bytes match; no physical WeChat scan was performed.
## Wenyu shore fit: exact connections before parcel generation

- Run `moon run scripts/check-wenyu-shore-fit.mbtx` from this checkout. See
  `wenyu-bank-fit-review.json` for the candidate transforms and controls.
  This is an offline test only, not input to the renderer or land compiler.
- With other streets and bridge geometry untouched, preserve their shared OSM
  nodes exactly; conservatively pin in-frame dry T/cross junctions too. The
  24 target ways have zero joint degrees of freedom for translations plus
  uniform scale. Even splitting at actual junctions (98 reaches), 1,046 of
  1,277 strict river/lake samples are on immovable reaches. Two right-bank
  bridge endpoints are themselves inside open-river cells.
- The bounded search (10% scale, 1.5-tile maximum movement) found one fewer
  wet sample, but the *actual* wet length increases slightly. Optimizing length
  instead only improves 0.089 grid units and leaves the sample count unchanged.
  Neither is accepted. Do not substitute the historical display connectors,
  move the terrain, or bake false parcel boundaries against this failed fit.
- A separate, non-uniform cross-chord scale trial holds both endpoints fixed,
  caps each endpoint bearing change at 3 degrees, and improves 16 reaches:
  1,277 to 1,198 wet samples, 288.28 to 270.19 grid units. It remains a review
  candidate, not a completed shoreline correction. No production data changed;
  decide the tie-in/shore tolerance before cutting the riverside blocks.

## 2026-11-08 · Bank-registered surface roads and bounded display parcels

- The previous trial is a baseline, not the current local renderer. After
  owner approval the default renderer, frontage, occupancy, decorative walks,
  landmark navigation and frontier routes consume the bank-v2 coordinates.
  The original terrain, historic overlay, landmark geometry and 3D bridge
  registrations remain unchanged. No change has been deployed.
- Rebuild from repo root with `moon run scripts/rebuild-wenyu-bank.mbtx` once
  the landmark studio model is built. This is offline work. Stopping after the
  first stage omits the parcel runs required by the scene reader.
- Classify *ways*, not names: a named dike road can contain both an explicit
  OSM bridge and an ordinary ground way. 338 tagged bridge ways are invariant;
  21 contact open-water cells by the conservative pavement envelope in frame.
  Fourteen tagged tunnels are separate; no ordinary way inherits an exemption
  from its name, its neighbour or a bridge cell. Keep those ambiguous cells
  separate from strict river/lake length and defer their adjacent parcels.
- Transforms are whole-reach cross-chord scales, common translations of
  misplaced wet junction groups, or translations of a long body with at most
  two existing tie-in reaches stretched along fixed local axes. No vertex
  snapping, new connectors, road clipping, new bridge tags or terrain carving.
  Original dry junctions, shared bridge nodes and calibration control
  neighbourhoods are pinned. Veto a reach if it changes a proper crossing in
  the visible grid; this prevents damage elsewhere but reduces apparent gains.
- See `wenyu-bank-surface-audit.json`: 154 adopted reaches, four fully clear
  even at pavement width; centerline open-water length 524.77 → 496.48 grid
  units, conservative width-envelope contact 580.10 → 550.29. These are not
  surveyed metres or pavement area. 141 OSM ways still contact an open-water
  cell by width. Named-corridor samples are 617/361/229 versus 641/373/263.
  Eleven wet endpoints moved together with their incident ways; zero shared
  node disagreement, zero changed proper crossings. Do not label this a
  zero-overlap result or infer two bridgeheads have been moved onto dry land.
- Only closed, uncontested dry components with street frontage and >=6 cells
  are parcelled on the 256×144 design grid. The resulting 177 blocks, 280
  connected frontage parcels, 9,371 land cells and 52 deferred coastal blocks
  are display-land semantics, not a renumbering of the 75 planning blocks.
  New infill may not straddle a verified parcel boundary. Existing landmarks
  and user buildings are not displaced to make a plot fit. See
  `wenyu-bank-land.json` for IDs, entrances and exact cell runs.
- No extra runtime fetch for parcels: the scene JSON grows 35,261 bytes, the
  default road SVG shrinks 5,462 bytes, and fitting never runs per frame.
  Native/Wasm reproduce the same SVG, accepted node coordinates, land mask
  and scene bytes. The review script verifies both packaged navigation
  coordinate sets and produces three before/after crops from the shipped
  SVG geometry. The local static preview has no live account/activity API.
- Acceptance: 24/24 focused MoonBit scene/frontage/density/landmark/walking
  tests, 194/194 browser-source tests; 812-file production artifact verified.
  The in-app browser loaded the new default layer and the overview. The
  comparison shows a sidewalk now clear at full width, the unchanged 东路桥
  and an improved but still wet greenway. No online release or live SSO test.

## 2026-11-08 · Left-dike design exception, validated on the shipped geometry

- After approval to redesign the left-dike pilot, reline only the ordinary
  road and parallel cycleway between the same two dry junctions (4178135388
  and 4178135989 on ways 47518902 and 417225061). Moving just the road can
  swap the two lanes. A common smooth displacement along the corridor keeps
  their order; its value and slope are zero at both ends. The two selected
  fitting parameters are height 3.0 and skew -1.3 in the design grid.
- Preserve original OSM nodes. Extra negative IDs are deterministic local
  shape vertices, not surveyed points, new junctions, bridges or new streets.
  Display occupancy, SVG and walk paths use the same curves; both navigation
  compilers consume the expanded shape index when selecting a way. Keep the
  original sample stations when comparing named-corridor counts: densifying
  a curve must not improve the metric by changing its denominator.
- The prior version's full-width contact lengths were 10.3875 (road) and
  7.1477 (greenway) grid units. Both are now zero, even after serialization
  and with an extra 0.17 grid units around the pavement against river, lake,
  ambiguous bridge and wetland cells. Bridge geometry and shared junctions
  stayed fixed. Comparing the actual previous output found zero changed
  coordinate overrides outside the pilot and just three changed SVG paths
  (road, cycleway, decorative green spine).
- This is *local* clearance, not clearance of the entire named dike or town.
  Town-wide ordinary-road centerline contact goes from 496.48 to 480.11;
  pavement-envelope contact from 550.29 to 532.76. 140 OSM way records
  still touch open water by width. The parcel file is byte-identical: 177
  blocks, 280 lots, 52 deferred. Do not promote adjacent unresolved areas.
- Rebuild with the same bank rebuild command. The added authoring search is
  offline, not a startup/per-frame step; SVG and scene grew only 2,639 and
  2,010 raw bytes respectively. The review checks the actual SVG, exported
  walk polylines and route graphs. 24/24 geometry/walking tests, 194/194
  browser-source tests and the 812-file build verification passed. Screenshot:
  `output/left-bank-pilot/comparison.png`. Local main; not deployed.

## 2026-11-09 · Connected shore roads beyond the left-dike pilot

- Rebuild with `moon run scripts/rebuild-wenyu-bank.mbtx`. The additional
  pass starts from the validated pilot geometry. Connected, movable wet
  junctions share one translation. The approaches ease along their length
  into fixed dry junctions. Both full-width contact and centerline contact
  are checked at exported precision. Retain smaller candidate shifts if the
  best one creates or removes a crossing, touch, or collinear overlap.
- A closed OSM way can visit an endpoint twice. Review a reach by its
  stored start index and count, then verify both node IDs. Looking up each
  endpoint separately selected the wrong side of a residential loop.
- 41 groups cover 51 reaches on 38 OSM ways. Relative to the previous local
  main geometry, 50 reaches improve at pavement width and nine become dry.
  No ordinary way's wet length increases. Centerline contact is 480.11 →
  464.37 grid units, and the conservative full-width measure is 532.76 →
  514.23. A total of 135 ordinary way records still touch open river/lake
  cells (previously 140). Left-dike way 47518902 still accounts for 73.86.
  Thirteen distinct shared OSM bridge endpoints in the residual road records
  are themselves in open water. The audit lists them per way. The terrain,
  all 338 bridge ways and both previously cleared pilot reaches are preserved.
- Repartitioning gives 180 dry blocks / 284 frontage parcels / 48 deferred.
  The default SVG grows one byte and the scene grows 449 bytes. All search is
  offline. The review checks changed SVG ways, their eligible walker paths,
  and both exported navigation graphs. See `wenyu-shore-groups-comparison.svg`
  for two clear reaches and one partially corrected residential road.
- Acceptance: 25/25 focused map and movement tests, 194/194 browser-source
  tests, verified 812-file production package and local in-app overview.
  `output/shore-junctions/comparison.jpg` captures the local comparison.
  This change is on local main and has not been deployed.

## 2026-11-09 · Wenyu dike bends and side-road connections

- A connected set of submerged junctions can extend around several bends
  with different shore directions. Fit each bend in road-bearing coordinates.
  Compare translating nearby lanes with translating just the branches joined
  at moving junctions. Dry junctions, surveyed control neighbourhoods, the
  earlier cleared pilot, and tagged bridge geometry are pinned. A design
  bridge cell alone cannot identify an OSM bridge. Allow ordinary dike nodes
  there only away from registered structures and calibration controls.
- Testing only the final geometry misses two parallel roads trading places.
  The bend veto checks for contact throughout each linear translation,
  including sliding collinear edges and branches at a shared intersection.
  The wet interval at each pavement station may only shrink. Measure net wet
  length per whole OSM way so that a short, already-submerged tie-in can
  stretch with its parent road. Require at least 0.1 grid units of formerly
  wet dike stations to emerge for a candidate to qualify.
- Against the previous local build, ten bends improve all 17 affected way
  records. Width contact falls from 514.23 to 467.16 grid units and centerline
  contact from 464.37 to 417.24. The worst left-dike way (47518902) improves
  from 73.86 to 66.92. All 135 previously wet ordinary ways still retain
  some wet pavement. The audit's `dikeWayContact` is per unique way;
  `dikeBends` contains shorter comparison spans and their original vertices.
- Rebuild with the standard bank rebuild. The updated road boundaries yield 180 dry blocks
  and 284 parcels; 49 coastal components are deferred. The SVG gained three
  bytes, the scene lost four, and fitting remains offline. The complete local
  rebuild took 22.5s. Packaged geometry, the two route graphs, overview and
  walking fixtures were verified. Focused map tests 25/25, browser-source
  tests 194/194; production packaging 812 files. Local review assets are
  `wenyu-dike-bends-comparison.svg` and `output/dike-network/comparison.jpg`.

## 2026-11-10 · Rejected left-dike strip experiment (OSM 47518902)

- Measure this way against its actual preceding 66.9209-grid-unit pavement
  contact. The new full-width result is 5.0113, with 2.7055 at centerline.
  Fifteen other ordinary ways clear the open-water mask and none worsens
  above exported precision. The town-wide width measure is 369.59.
  The review uses the same crop and projection for both full alignments;
  orange traces come from exact segment intervals on river and lake cells.
- Translate the dike and its feeders together, then scale the strip across
  each bend. Split edges at triangle boundaries to retain the same mapping
  on long roads, narrow paths and walk routes. Fix registered bridges and
  dry junctions. At Qinbei the submerged shared junction can slide along
  the original approach while both the bridgehead and three-way junction
  retain their coordinates. The 1.5431-unit approach between OSM nodes
  3351127195 and 605038669 has zero length clear at full dike width. The
  projected spread of each bridge must be checked over the complete deck;
  a crossing can slide from one deck segment to the next.
- `wenyu-left-dike-shapes.json` records source stations and synthetic
  shape vertices. Both navigation compilers read them. A virtual bend has
  degree two and must never create an intersection. Curve simplification
  retains original nodes and checks water contact and swept intersections.
  The prior pilot and all 338 tagged bridge ways remain registered.
- Production packs the source walker paths as four-decimal delta polylines.
  Navigation keeps original OSM nodes at source precision and recreates
  intermediate shape IDs on their original edges. The decoded graph matches
  every source node and edge. The decoded walker layer matches all 18,099
  coordinates on 1,612 source paths. The 812-file package verifies at
  72.9 MiB against the existing 73 MiB ceiling. On the same expanded graph,
  ten native route searches took 1,190 ms with the full scan and 12 ms with
  the priority queue. This benchmark excludes loading and drawing.
- The full map comparison is `wenyu-left-dike-full-comparison.svg`.
  Acceptance includes 29 map/routing tests, 194 browser-source tests and
  inspection of the packaged town and comparison. This is a local main build.

## 2026-11-10 · Whole-road correction for the Wenyu left dike

- Start from the original OSM node sequence in `wenyu-lower-perspective.json`
  after applying the approved gentle camera registration. Apply one positive
  uniform scale up to 1 and one translation to the whole connected corridor.
  The dike, parallel greenway and their directly connected ways comprise 23
  ways. Local strip fits produced abrupt bends and 842 display vertices.
- The left dike has 63 source vertices and seven fixed dry junctions. Three
  non-collinear witnesses are 605039789, 9732173880 and 4087374387.
  Holding these positions fixes any affine transform to identity. The build
  checks connections by OSM ID and verifies every tagged deck against source.
  Keep conflicts visible in the shoreline audit and parcel exclusion mask.
- The 66.9209 grid units came from an intermediate, locally edited road.
  The rejected strip reduced conservative full-stroke contact to 5.0113.
  The registered source line measures 84.5380 with a 0.12 half-width and
  79.8043 along its center. These are lengths along the road in cells tagged
  river or lake, independent of the visual guide or walker sampling.
- The retained off-corridor coordinates are the 907 original OSM node
  overrides copied from the pre-strip calibration. Both seed ways' vertices
  and all vertices of their connecting streets were excluded, then other
  ways sharing displaced junctions were checked until the set stabilized.
  The pilot designs, strip-shape files and authoring traces are historical.
  The surface compiler now supplies the overlay, occupancy and walker paths;
  the two navigation compilers use the original OSM edges with its export.
- Rebuild with `moon run scripts/rebuild-wenyu-bank.mbtx`. To compare a saved
  strip build with the current export, pass its scene/audit directory and an
  SVG destination to `scripts/review-wenyu-road-surface.mbtx`. Both panels
  use the same crop. The close-ups show the largest local deviation. The
  current local package verifies at 72.6 MiB. The focused map and routing
  suite passed 29 tests, and the browser-source suite passed 194. Packed
  parity covers 11,102 walking coordinates, 788 graph nodes and 847 edges.

## 2026-11-10 · Movable junctions on the left dike (offline trial)

- Junctions may move with their roads. A fixed bridge deck needs a connected
  approach. Pinning every dry junction answers a different question.
  Run `moon run scripts/trial-wenyu-dike-group.mbtx` from the calibrated main
  worktree. The script writes its audit and same-scale comparison to
  `output/left-dike-group/`; the selected parameters are recorded in
  `docs/project/wenyu-left-dike-group-trial.json`.
- The 22 ground ways on the dike, greenway and immediate branches travel with
  19 adjoining park paths under one affine map. Translation and positive
  compression along orthogonal principal axes preserve vertex order and
  straight edges. The 63 dike vertices are original stations. The nine
  boundary junctions reconnect through straight surface approaches, including
  the two to stationary bridge heads. Water under the approaches is counted.
- Search bounds for this experiment were five grid cells of travel per vertex
  and up to 15 degrees of approach deflection at a bridge. The best tested
  crossing-preserving fit reduces full-width dike contact from 84.5380 to
  76.2415 and group contact including approaches from 146.3902 to 138.5337.
  The two principal compressions are 6.0085% and 0.1978%. Parameter trials
  include refined and repeated candidates; these are sampled minima.
- Optimizing the dike alone can give zero with both bridges connected. The
  selected zero-contact candidate still has 3.7014 units of wet pavement over
  the group and introduces 64 exterior crossing or contact conflicts while
  removing 10 prior crossings. Keep this variant in the study. The crossing
  check compares proper crossings for each pair of ways at export precision
  and checks the new boundary edges. Passing graph reachability alone misses
  the changed street layout. Both trial variants are outside the default town.

## 2026-11-10 · Outer road groups around the zero-water dike

- The initial geometry is the third saved placement in
  `wenyu-left-dike-group-trial.json`. Replaying it must reproduce the
  64 extra crossing/contact events and 10 missing original crossings.
  All ten missing crossing relationships involve a fixed deck and one of
  the 41 inner ways. Moving exterior surface streets alone cannot change
  those pairs. The inner ways can travel together to another zero-water fit.
- `scripts/trial-wenyu-outer-roads.mbtx` tests whole-way translations and
  positive compressions along orthogonal axes. Group cut proposals include
  streets sharing junctions with the conflict roads. Each proposed result
  is rescored against the stationary network and all explicit ordinary
  approach segments. For a mixed junction, use the deck position when
  present, otherwise an incident road position minimizing total tie length.
  Choosing a junction by a transient transform index changes replay results.
- The selected local trial moves 104 exterior OSM ways in 10 transform groups.
  Maximum exterior travel is 3.69 terrain cells. Of the original 64 conflicts,
  56 were cleared and 8 remain. There are 17 newly introduced conflicts, for
  25 in total. Two of the ten missing crossings returned, including the
  crossing of the dike and the Future Science City Road bridge. Eight remain.
  The count tracks crossings by pair of OSM ways, with explicit boundary
  contacts separately identified by the shared source junction.
- All 63 original dike vertices are present and pavement contact is zero.
  Whole inner road and approach contact falls from 3.70 to 2.72 cells.
  The 104 moved outer roads measured zero pavement contact in both snapshots.
  Connectivity checks cover 245 affected junctions. Independent acceptance
  recomputes crossings from the complete candidate polylines and all ordinary
  ties without using the optimizer's cached interactions or segment halo.
- To reproduce the comparison without running a new search, run
  `moon run --target native scripts/trial-wenyu-outer-roads.mbtx -- --review docs/project/wenyu-outer-road-trial.json`
  from the calibrated main checkout. The audit and same-scale SVG are written
  under `output/outer-group-review/`. The default town continues to use its
  previous road assets.

## 2026-11-10 · Continuing from the 25-conflict layout

- The comparison baseline for this pass is `wenyu-outer-road-trial.json`.
  The selected result is `wenyu-junction-fit-trial.json`. The source road
  and water masks, default town and fitted bridge decks are unchanged.
- The offline solver fits pairs of real OSM junctions with one symmetric
  contraction. When an old bridge crossing is missing, it searches translation
  windows where a whole compressed inner way would intersect that fixed deck.
  It clips placements colliding with inflated river or lake cells and independently
  remeasures the rendered coordinates. Exterior refinements test both sides
  of actual crossing events, including the ordinary junction approach segments.
- Relative to 25 extra crossing/contact events and eight missing crossings,
  nine old conflicts clear, 16 persist and two appear, leaving 18. One more
  deck crossing returns (OSM ways 1137139855 and 47518902), seven remain
  missing and no previously present crossing is lost. Five missing pairs have
  an actual crossing of the same inner way on the surveyed adjacent approach
  within 3.16 cells. Keep their original deck deficits in the count.
- The dike, including its entry, measures zero open-water pavement contact.
  The 41 inner ways plus boundary links measure 2.64 grid cells, previously
  2.72. The union of peripheral surface roads moved in either layout accounts
  for another 0.12 cells, previously 0.82. The largest change of a peripheral
  vertex from the comparison layout is 2.18 cells. Connectivity was checked
  at 247 affected junctions including six at structures, with zero endpoint gap.
- From the calibrated main worktree, replay with
  `moon run --target native --release scripts/trial-wenyu-outer-roads.mbtx -- --compare docs/project/wenyu-junction-fit-trial.json`.
  Use `--continue docs/project/wenyu-outer-road-trial.json` to run the search
  from the earlier layout. Output is under `output/wenyu-next-pass/`. The
  report measures both layouts on the same set of roads. The candidate
  evaluation count includes earlier saved search stages and repeated fits.

## 2026-11-10 · Left dike and adjoining streets, 18 to 16 conflicts

- Replay the saved trial from the calibrated main worktree with
  `moon run --release --target native scripts/trial-wenyu-outer-roads.mbtx -- --approach-review docs/project/wenyu-approach-continuation.json`.
  The comparison uses `wenyu-junction-fit-trial.json` as its before state.
  It writes `audit.json` and `comparison.svg` under `output/wenyu-approach-pass/`.
  The optional `--approach-fit` mode searches from the supplied layout.
- The core road group retains its previous fit. The solver adjusts whole
  peripheral ways by translation or positive compression, tries adjacent
  groups together, and checks the result against all road and connector
  segments. A multiway junction can store a short tree linking its actual
  transformed road ends. Treat that tree as part of the saved layout when
  replaying the trial. Decks retain their surveyed sockets.
- Six previous extra crossings or contacts cleared, twelve persisted, and
  four appeared elsewhere. All seven missing source crossings persist. Of
  the five that previously intersected the dike on an adjacent bridge
  approach, three still do so. The other two now intersect the surface ties
  at nodes 3983803696 and 9161744180 on 未来科学城东路. Both remain charged as
  conflicts and missing source deck crossings. The other two missing pairs
  involve pedestrian way 1059215627 and the same two bridge decks.
- The dike and its entry remain dry. The 41 inner ways plus their boundary
  links still contact 2.64 grid cells of open water. On the same set of
  affected peripheral ways, contact fell from 0.12 cells to zero. There are
  72 boundary links totalling 88.99 cells, down from 76 totalling 91.85.
  The independent geometry audit and endpoint graph check verified the result
  across 249 affected junctions, eight at structures, with zero endpoint gap.
  This is an offline trial. The default town uses the existing road assets.

## 2026-11-10 · Town-wide review of long stretches of road over water

- Use `wenyu-major-road-fit.json` to replay the saved road groups on local main.
  From the repository root run
  `moon run --release --target native scripts/trial-wenyu-outer-roads.mbtx -- --major-review docs/project/wenyu-major-road-fit.json`.
  The baseline is `wenyu-approach-continuation.json`. The command verifies the
  complete polylines and boundary connections, then writes the interactive
  review, a same-scale comparison SVG and the marker data to
  `output/wenyu-major-roads/`. `wenyu-major-road-markers.json` is the portable
  copy. Open `index.html#w1280498644` to inspect a way or use the point list.
  A file URL works for the HTML and SVG. The default town still uses its
  previous render, parcel and navigation assets.
- Count all 6,420 source ways. Measure all 6,068 ordinary roads and the
  ordinary connections to their moved junctions. Keep bridges and tunnels
  separate. The full-width contact length drops from 349.21 to 308.53 grid
  units inclusive of ties. Road contact goes from 346.91 to 291.14 and tie
  contact from 2.29 to 17.39. The summed length times rendered width index
  goes from 75.89 to 68.25. It is an index in grid units squared, not a
  surveyed or polygon-union footprint. Eleven ways still have a continuous
  run of at least five units, previously thirteen. The longest is still
  18.33 on a right-dike way tagged `highway=construction`.
- The search includes whole-way translations, symmetric contractions with
  pivots on lines between real junctions, and the adjoining surface ways.
  On the selected layout the primary left dike and entry stay dry, as does
  right-dike way 1280740322 (17.53 previously). An earlier placement of
  the latter sent 0.71 original wet units outside the finite image. Track
  the original parameter intervals through the exported geometry and reject
  candidates losing wet stations over the frame edge. The accepted result
  loses none. The independent graph check covers 299 junctions, including
  13 at structures, with zero endpoint gap. All 16 existing crossing/contact
  conflicts and seven missing original crossings retain their previous keys.
- For hand correction, rank individual continuous runs by length times road
  width. The worklist contains every wet run with its terrain coordinates
  and OSM identity, including wet boundary connections. Keep explicit
  construction tags visible. The inspector also records source stations
  farther than the five-unit search radius from any dry cell, including
  construction way 1093379797 (8.44) and Gaobai Road 969649954 (5.32).
- Qinbei bridge way 47518657 is identifiable in the original Wenyu plan
  (`~/Downloads/wenyuvalley.jpg`, SHA-256
  `8363abfdeda33d759a185c8a54c3ef8f971711a4dbf149028ee9447e38f90e62`)
  and the derived 1672 × 941 terrain image. The brown span has approximate
  end picks (1175, 457) and (1191, 437). Moving the whole deck by their
  mean displacement gave a connected trial with 60 conflicts and 12 lost
  crossings. It was excluded from the saved layout. Node 11510352170 is an
  internal connection of a staircase to a ten-node pedestrian bridge.
  The plan alone does not locate its stair landing.
- To reproduce the independent compatibility check, export geometry with
  `--constraints` and run
  `moon run --release --target native scripts/check-wenyu-dike-feasibility.mbtx -- 20 126860128,126860137,395525260`.
  For the two Jingcheng decks and one Shunyu deck, the covering test exhausts
  588,067 parameter boxes with no unresolved box. Even dropping bridge angle
  constraints, a single symmetric contraction and translation moving each
  vertex at most 20 cells cannot both keep this dike dry and preserve all
  three original deck crossings. This concerns these specific source
  relations and terrain, not every remaining conflict on the map.

## 2026-11-10 · Future Center and multi-parcel siting

- The `center` landmark has one geographic anchor, setback, oriented reservation
  rectangle and door. Its 3D study contains multiple courtyard buildings and
  paired towers. Map presentation uses one campus projection. The decorative
  infill single-parcel check does not bind a landmark to its intended parcels.
- In the local bank-v2 scene, the projected reservation center is
  (200.531, 102.259). All 25 cell centers inside its rectangle have parcel
  ID zero and 22 are flagged in the road occupancy raster. A zero ID denotes
  unpartitioned display land. It does not establish a building or cadastral
  boundary. The crossing centerlines are two secondary ways on 鲁疃东路 and
  tertiary ways on 鲁疃路 and 英康路. Preserve these public streets when
  assigning individual building footprints.
- The previous A/B/C siting diagram selected the three street enclosures that
  intersected the inferred reservation. None of those labels establishes
  membership. Old A is open land west of 英康路. Old B contains the western
  office pair. Old C contains only the western pair of the middle group.
  Building 7, the eastern twin tower, was missed. Register the buildings as
  groups of 2, 4 and 1 using the named streets and imagery in the
  [siting verification](town-landmark-integration.md#future-center-siting-verification).

- Future Center now has seven registered building footprints. Use the
  [placement workflow](town-landmark-integration.md#placing-the-campus-in-the-town)
  after a road or model change. Its campus arrival is on 英才南一街 at node
  12695823112. A candidate on the east bend, 9559733230, appears in the OSM
  drawing but is absent from the packaged pedestrian graph. Validate arrivals
  after applying the graph filters. An empty campus-wide footprint is intentional:
  map drawing, reservations and picking use the individual buildings.

- For other Future Science City estates, use the [source and placement register](science-city-estates.md).
  A named OSM landuse polygon is an imagery window, not proof of title, phase, or an
  individual tenant's building number. Multi-sheet plans must register to one combined
  parcel drawing: even individually correct footprints can erase the separating street.
  Digitise individual review windows rather than contact-sheet coordinates. Accept
  street arrivals only from the shipped walking graph component: the closest tagged
  sidewalk to Greenland Cloud Valley was disconnected from Future Center.

- Test a fresh district deep link before creating an avatar. Read the active tool
  from the town model, even when onboarding hides its dock button. The town
  canvas owns touch: one-finger drag pans; a two-finger gesture preserves the
  world point under its moving midpoint. A drag or pinch must never pick a
  building or dispatch a ground click on release. In embedded 3D rooms, turning
  off rotation should leave drag-to-pan available.
- Street scenery is presentation-only. Generate motor lanes from the corrected
  dry surface lines, not the walking graph. Keep static cars in the canonical
  3D source for map baking; substitute moving cars only in the interactive
  studio. Do not add vehicle motion or simulated telemetry inside machine rooms.


### 住宅与园区外立面（2026-11-11）

- 研究楼体的原始米制轮廓、顺序和稳定楼号是 3D 与小镇共用的立面坐标。不要按相机投影后的屏幕边长重新排窗；缩放或旋转会让同一面墙改变开间。地图只给通过原有岸线、道路和占地检验的楼体绘制对应立面。
- 星科按集团实景区分深色实墙、横向条窗、玻璃段和银灰板；机器人园按公开鸟瞰图区分白色深框和深色玻璃；星耀、国誉、寰宇参考公开方案图。其他项目采用用途研究，未核验的开间、材料和夜景不可作为竣工事实。来源在 [项目核对表](science-city-estates.md) 和各项目查看器的“资料与依据”。
- 专用地标修改后需重烘焙城镇投影；研究楼体使用共用的米制立面规则和按可见面缓存的地图贴片。地图背景建筑则使用 MoonBit 的按用途与可见方向生成的简化立面。

- [逐栋位置及立面复核](science-city-building-review.md)区分门牌、屋面投影、楼脚、园区竣工实景和四向立面。逸园 12 个法定楼号分为 14 个体量；按开发商附件中的带号鸟瞰和逐单元层数配对。北排高楼的屋顶视差曾导致两段被院界裁掉。星科一期与二期 1 号厂房的面材、横带及凹口不同，按楼体选择外观。

## 2026-11-11 · Regional map and building registration

- The legacy camera migration uses the old wide zoom and center as its signature. A just-fitted Wenyu overview can have the same values, especially with reduced motion. Only migrate the legacy camera and verify the final fit after canvas input has mounted.
- In a multi-parcel plan the same building number can recur, and postal POIs can disagree with the design sequence. Use phase-qualified controls and check direction, retained support and actual project bounds. Huanyu’s numeric subset admitted an implausible rotation. Its independently identified north/south parcels give the stable fit.
- A good footprint overlap can still cover a courtyard. Check both outer and inner rings against the image. Prefer a unique reference inside the enclosure for a previously rejected roof. See [regional checks, source and build workflow](science-city-regional-map.md).

## 2026-11-08 · Wenyu road and parcel audit

- Do not equate the planning reference's 75 stable road enclosures with a
  partition derived from the displayed OSM overlay. Core building placement
  checks occupied cells and frontage; exterior lots use world-grid candidates.
- The historical `waterSamplesAfter` mixes river `r`, lake `l` and bridge `b`
  terrain cells even after excluding ways tagged bridge/tunnel/ford. Keeping
  the original gentle projection and sampling scheme, strict `r`+`l` counts
  are 641/1327 (左堤路), 373/1498 (右堤路), and 263/958 (绿道昌平段); bridge-cell
  counts are 92, 54, 12 separately. These are design-grid samples, not lengths
  or surveyed encroachments. The public 8443 unshifted overlay and terrain
  labels matched the local asset hashes during the audit. No map changes.

## 2026-11-11 · Cluster application refresh

- Read `CLUSTER_REFRESH_20261111.md` for source provenance, artifact digests,
  services, backups and acceptance. The ordinary checkout is on an older
  mobile-review branch. Latest Town was built from fetched `github/main`
  ef19c952 in `/Users/kq/Workspace/moontown-release-20261111`; the compatibility
  fix and HTTP regression are on `codex/cluster-refresh-20261111` there.
- All three personal launch profiles, the active Desk workspace, public Town,
  shared Robo and management-node Desk/Town user services were upgraded.
  Existing volumes, permissions and companion/model services are preserved.
  GPU nodes, GLM pause state, training and ComfyUI were not changed.
- A real login exposed `account-sha256:<hex>` versus the browser's canonical
  `account-<64 hex>` scope contract. Strip the backend digest tag; never relax
  the frontend storage-isolation guard. Native public tests 3/3, browser scope
  tests 7/7 and the real signed-in map passed. The stopped allowed GLM model
  still blocks new private handoffs; that is separate from login success.
- Preserve legacy nested MoonBit module metadata in snapshots. Preserve base
  image glibc/loader when adding host-built binaries. A static UI image is not
  a full Town runtime; package the launcher-required policy templates too.
- Private build/source/state backups and final inventories are on management
  node .173 under `moon-public/work/products-20261111-r1`. New shared releases
  are `moondesk-20261111-r1` and `moontown-20261111-r1`; old releases remain.
  Keep the first state backup when retrying, and wait for real endpoint health
  after rollout rather than treating a ready/stale Deployment count as HTTP
  acceptance. Failed historical Pods are not live state writers.

## 2026-11-17 · Standalone .25 GRUB repair

- User's test machine 192.168.2.25 is not a cluster node. Used management only
  as an SSH jump; no cluster mutation or enrollment. Old access port 32122
  closed before key exchange; existing direct management port 32123 worked
  with its current key/host-key identity. SSH config was not rewritten.
- Arch ISO was BIOS-booted. Samsung 1TB contains Arch; ZHITAI 2TB Ubuntu
  22.04.5. Old Arch GRUB default selected an absent Windows EFI UUID; its
  Ubuntu entries referenced removed kernel files. Ubuntu EFI was empty and
  its fstab referenced the absent UUID. See
  `output/grub-repair-20261117/REPAIR.md` and its original-files archive.
- At user's explicit correction, restored Arch GRUB as primary, with Ubuntu
  first/default and Arch retained second. `09_ubuntu` uses Ubuntu root UUID
  and maintained `/boot/vmlinuz` + `/boot/initrd.img` symlinks. Reinstalled
  Arch native and fallback EFI; restored Ubuntu signed EFI independently and
  fixed its fstab. All changes backed up on both systems and this Mac.
- Syntax, EFI type, root UUID, kernel paths and unchanged partition tables
  passed. All repair mounts unmounted and disks synced. Physical reboot into
  Samsung UEFI/GRUB then Ubuntu is pending user confirmation; do not claim
  OS boot acceptance before observing it. BIOS live mode cannot set EFI
  NVRAM. Do not install BIOS GRUB by altering these GPT partition tables.

### .191 boot and login acceptance

- User confirmed the repaired system booted and received 192.168.2.191. Existing
  `jiaanguo` Mac SSH key works through the management jump on port 32123.
  Actual system: QaQ, Ubuntu 22.04.5, 6.8.0-138-generic, UEFI, Ubuntu root and
  EFI on nvme1n1p2/p1. This supersedes pending OS boot acceptance above.
- Important: the historical k3s-agent was still enabled and automatically
  rejoined under `lunanexa-gpu-180` on boot. To keep the machine standalone,
  cordoned that existing record, then used user-supplied sudo authentication
  to stop and disable its k3s-agent. Verified inactive/dead/disabled. No join
  command was issued; no software/data removed. Do not uncordon or enable it
  without a new user request. Credentials were not saved in project files.

### .191 slow shutdown investigation

- Read-only journals show three consecutive boots spending ~90 seconds on
  `session-1.scope`, then killing remaining `sogoupinyin-ser` processes.
  `output/grub-repair-20261117/SHUTDOWN_DIAGNOSIS.md` records timestamps and
  boundaries; private raw log `previous-boot-shutdown.log` retains evidence.
- Existing user@.service 5-second timeout does not affect the login session
  scope's actual 90-second timeout. Do not conflate those units or label the
  old k3s-agent as this bottleneck: it stopped in ~0.066 seconds in boot -1.
- Startup separately takes ~56 seconds; it is not shutdown time. No reboot,
  active input-method kill, package change or timeout change was performed.
  Next repair should preserve Chinese input and verify the Sogou lifecycle
  with an actual shutdown/reboot comparison rather than claim it is fixed.

### .191 Sogou lifecycle repair applied; no further testing

- At user's repair request, installed two per-user Sogou units and XDG
  autostart overrides. Use Type=forking for these daemonizing binaries,
  PartOf=graphical-session.target and After=dbus.service. Stop watchdog first;
  call SogouImeServerExit before a Sogou-only 3-second cleanup fallback.
  Keep vendor packages, dictionaries and global timeouts unchanged.
- Existing Sogou processes migrated into dedicated user service cgroups.
  A stop/restart took 4.36 seconds; both services and D-Bus owners recovered,
  and Fcitx still advertised enabled Chinese Sogou. Internal Sogou threads
  still required the targeted fallback; do not claim upstream code was fixed.
- User then explicitly said **no reboot** and **no testing**. No reboot was
  issued. Stop here; do not resume tests automatically. Whole-machine shutdown
  and next-login behavior are unverified. See
  `output/grub-repair-20261117/SHUTDOWN_REPAIR.md` for applied files, backup and
  rollback. The active desktop/input method and disabled k3s-agent are retained.

### .191 ToDesk desktop crash repair — 2026-11-19

- New explicit user request authorized ToDesk-only diagnosis and repair; prior
  no-reboot restriction and independent-machine setup remain. Do not resume
  earlier shutdown tests or operate its build VM as part of this repair.
- Old 4.8.6.2 daemon was healthy but the frontend segfaulted after ~4 seconds
  in its bundled HTML renderer (`determine_style`/`window_frame_ctl`). Fresh
  application data, accessibility-environment and XIM probes did not fix it;
  missing libraries, disk capacity and Wayland were not the observed cause.
- User downloaded official Ubuntu amd64 4.9.8.1 after the vendor download's
  CAPTCHA blocked automation. Transfer SHA-256 matched. Backed up old package
  files, service, launchers and user state before dpkg upgrade. Private 0600
  rollback archive on .191: `~/.local/state/todesk-repair-20261119/before-upgrade.tgz`.
- Installed app remains open with a viewable X11 window; new daemon active,
  no restart loop, IPC listener present, no repeated old crash signature.
  End-to-end external remote-control session was not tested. Existing vendor
  autostart matches the new package; no persistent workaround was required.
- Only ToDesk was restarted. No reboot, build-guest action, cluster join,
  global display/input/accessibility change or configuration reset. Verified
  k3s-agent still inactive/disabled. Full evidence and scope limitations:
  `output/todesk-repair-20261119/REPORT.md`.
- User subsequently requested removal of the old installation. Dpkg already
  replaced 4.8.6.2, so removed its mixed `before-upgrade.tgz` rollback only
  after successfully extracting config and user data to root-private
  `~/.local/state/todesk-repair-20261119/preserved-user-data/`. Removed the
  repair directory's extracted update/control files, fresh diagnostic profile
  and redundant installer copy. Working 4.9.8.1, current settings, original
  user state and the Mac's downloaded installer are retained. No restart or
  reboot; full old binary rollback is no longer available.

### .191 ToDesk lag investigation — 2026-11-19, pending UI control

- Physical DP-4 display already runs 4K/60 Hz. Last completed ToDesk session
  aggregate instead reports 4480×2520 VP8/libvpx software decode, target60,
  mean42.055/min28/max50 fps and12 decode stalls/3063ms. These are historical
  aggregates, not a fresh controlled test. Current connection requests60fps.
- Decoder thread is busy; GPU decode utilization stayed0% in four samples.
  Mapped NVIDIA libraries do not establish actual hardware decode. CPU is a
  homogeneous i9-7900X, not hybrid P/E cores. No scheduling workaround applied.
- The user is actively controlling this Mac from .191. Avoid a reverse
  remote-control loop or an unannounced client restart. User cannot find
  hardware-decoding controls. Native UI tools control only this Mac; explicit
  permission requested for SSH command-based UI control on .191 and pending.
- No settings/performance fix applied yet. Do not claim the lag is fixed or
  guess private configuration keys. Evidence and next action boundary:
  `output/todesk-repair-20261119/PERFORMANCE.md`.
- User approved SSH UI control. Installed only xdotool/libxdo3; restored classic
  ToDesk toolbar to expose Display → Advanced. Renderer acceleration and
  hardware decode/encode preference were already on, vertical sync off,
  fixed frame rate off. Clicked fixed-fps control, but final state/performance
  remains unverified; action log alone is insufficient.
- User confirmed intentionally closing the remote connection, then could not
  reopen. Desktop PID104832 stayed hidden and ignored SIGTERM; cleared only
  its user unit and relaunched installed client as PID140647. Main window is
  viewable; daemon PID104717 stayed active with zero restarts. No reboot,
  settings reset or build-VM change. Task's transient client stop timeout is5s.
- Actual reconnect dialog now says account permits one simultaneous controlling
  device, occupied by host466932609. Asked permission before disconnecting
  that different host; no account/purchase/other-session action performed yet.
  Do not mislabel it a stale .191 connection or claim reconnection is fixed.
- Follow-up15:01–15:30: user had reconnected and reported10fps. Read actual
  per-device JSON config and logs. Historical received/decoded fps~42–47,
  rendered~8–10; do not confuse decoder throughput with presentation rate.
  GPU driver/GLX is healthy; no driver update. Low-level .xlog is encrypted.
- Enabled and verified hardware-decode preference (saved PreferHardDecode=1),
  but live VP8 remained software. A Smooth-quality trial was reverted; final
  Quality=2/High.60fps target and fixed-frame preference were already enabled.
- Found logged4480-wide VP8 stream exceeds NVIDIA's documented4096VP8 limit;
  this is a real incompatibility but not proof of the only fallback reason.
  At15:26 selected ToDesk remote1920×1080HiDPI, physical3840×2160, preserving
  HiDPI and High quality. This changes the sending Mac workspace; .191's
  monitor stays4K60. User then reported60fps. No session/service restart.
- GPU counters still do not show active ToDesk NVDEC after that result. Report
  the effective resolution/rendering-load change, not a proved GPU decode fix.
  No reboot, build-VM/driver/network/account change. Current outcome, exact
  settings and remaining limits are in the performance report.
- Follow-up15:42–15:43: a temporary PID-filtered uprobe of ToDesk's log
  appender captured live plaintext before encrypted xlog writing. Removed the
  task-owned probe afterward; no process-memory patch or restart. Twelve
  reports show3840×2160 VP8/libvpx, rendered57–60fps, quality2. Hardware
  decoding remains inactive; this was steady-state capture, not a captured
  initialization failure. Root-private raw trace retained in the repair
  directory on .191; selected metrics saved locally in the report's ui folder.
- Desktop currently locked (loginctl LockedHint=yes, GNOME ScreenSaver=true).
  XWD still returns the underlying window, but menus do not receive input.
  User asked to unlock locally; do not bypass the screen lock or misdiagnose
  the blocked clicks as an app hang. Need native codec/decode selection test
  once unlocked, preserving current4K60/High. Build VM untouched.
- Nov23 recurrence: reconnect log selected2240×1260HiDPI again at11:26
  (physical4480×2520). User reported21fps, then independently selected
  1920×1080HiDPI at11:42:57 and confirmed recovery. A subsequent20-second
  PID-filtered trace verified3840×2160, High/quality2 and four rendered
  reports59,59,60,60fps. Still VP8/libvpx; GPU decoding is not fixed.
  No evidence establishes why the larger mode returned or a persistent
  reconnect fix. Probe removed/absence verified; no restart, VM or cluster
  operation. Evidence: `output/todesk-repair-20261123/REPORT.md`.
- Nov23 later: attempted persistence/GPU investigation after explicit request.
  Saved profile still follows remote (ResolutionX/Y=-1); no config change.
  Reconnection blocked by one-channel account limit occupied by137815886;
  did not disconnect it. User then said no testing, requested only restart
  of .191 ToDesk. Stopped frontend, restarted todeskd.service (PID886370,
  active/running), relaunched frontend with existing environment. Temporary
  trace probe removed/absence verified. No VM/reboot/quality/resolution change.
  Persistence and GPU decode are still unresolved; do not resume tests unless
  newly requested.

### .191 network activation notifications — 2026-11-23

- Root cause: auto-generated `Wired connection 3` on Ascend PCIe vNIC
  `endvnic` repeatedly timed out DHCP after45s (`ip-config-unavailable`).
  udev/modinfo identify Huawei pcivnic host driver, not a build-VM bridge.
- Backed up original runtime keyfile/profile in root-private
  `/root/network-repair-20261123/`. Deleted only UUID
  `684e00ca-6e29-3b6b-b27b-5d77f4ac5ba0`; installed matching-only-endvnic
  managed=0 config `/etc/NetworkManager/conf.d/90-ignore-ascend-endvnic.conf`.
  Reloaded conf without restarting NM; set live endvnic unmanaged. Verified
  loaded config, unmanaged state, deleted profile and intact LAN/robot routes.
- Do not unload Ascend drivers or delete the interface as a stale VM network.
  Main192.168.2.191/enp4s0 and robot192.168.55.101/eno1 retained; no VM,
  reboot, cluster, other-host or ToDesk operation. Evidence/rollback:
  `output/network-repair-191-20261123/REPORT.md`.
