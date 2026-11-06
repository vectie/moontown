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
