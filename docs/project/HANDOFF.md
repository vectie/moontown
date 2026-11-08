# MoonTown handoff notes

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
