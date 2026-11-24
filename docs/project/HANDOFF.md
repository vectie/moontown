# MoonTown handoff notes

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
