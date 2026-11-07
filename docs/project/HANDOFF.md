# MoonTown handoff notes

Read this with `AGENTS.md` before starting work. Keep task evidence in its
existing documentation and record concrete pitfalls here.

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
