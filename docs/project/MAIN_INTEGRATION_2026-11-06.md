# Main integration, 2026-11-06

## Scope

Integrated the working source previously based on `f75656af`:

- Cross-dossier inquiries retain exact historical excerpts, independent
  challenges and versioned provenance, then open an ordinary editable draft.
- The living street, courtyard, frontier world generator and navigation share
  existing terrain, registered landmarks and calibrated road coordinates.
- Building orientation, daylight/water rendering and the six updated landmark
  projection resources remain part of the existing renderer and product build.
- MoonDesk's Working style and UI/UX sections are adapted in `AGENTS.md`.
  Cross-dossier controls use Chinese labels and one applicable save action,
  including the existing unsaved-draft guard.

`f4214974` commits the source, documentation, formal resources and R796 worker
evidence. Merge `1f59d40a` reconciles all three preservation branches. The merge
adds no source diff: two snapshots were empty; the R560 MoonBook timestamp
changes already exist in the newer main implementation. Every local branch is
now reachable from main. The duplicate stash was checked against its retained
implementation and dropped; its backup commit remains reachable through main.

`output/` contains 102 MiB of local screenshots, build logs and unrelated PDF
review exports. These are retained locally and ignored, together with the
generated changed-file listing. Historical MoonClaw worktree session-progress
JSON is excluded locally as runtime state. Original R796 diagnostic logs are
retained verbatim under `evidence/R796`.

## Acceptance evidence

- Native focused packages: 212/212 passed, including world generation, inquiry
  contracts, imported outputs and MoonBook timestamp handling. Authoring inquiry
  checks passed 2/2 and cross-dossier store/API journey passed 1/1.
- Browser source tests: 177/177 passed with the explicit source patterns.
- Full Rabbita UI regression: all 194 test files passed in 25 batches on the
  final run, including the retained/cross-dossier inquiry rendering and save
  journeys, frontier navigation, cache bounds and local-life pause behavior.
- Production UI build, landmark build and deterministic asset assembly passed.
  The verifier accepted 778 files, 71.7 MiB; the minified main entry is 2.8 MiB.
  Its gzip representation is 597 KiB. Existing compiler warnings remain.
  These are artifact sizes, not startup or frame-rate measurements.
- `moon info` and `moon fmt` ran for both the root module and Rabbita UI.
  Public interface changes are the intended new inquiry and frontier APIs.
  Formatter-only rewrites of unrelated optional-argument syntax were removed.
- Browser acceptance used the rebuilt desktop server on loopback port 17870
  with a disposable suite root. Walking to the bench changed the action from
  Sit to Stand. Map settings opened and closed; each direction retained its
  Chinese accessible label. Desktop, 375×812 and 812×375 layouts were inspected;
  phone and landscape document widths matched their viewports, and the map
  utility targets were at least 44×44. No browser console errors were observed.
- Screenshots live outside the repository at
  `/Users/kq/.codex/visualizations/2026/11/06/moontown-integration/`.

The first full native run passed 2020/2026; six local-process crossings required
explicit Claw/Book binaries. Built the existing `moonclaw/cmd/oneoff_fixture` and
`moonbook/cmd/outcome_lessons` executables and configured the test environment.
No real model provider or paid dispatch was used. The next run passed 2024/2026,
including those six crossings, and exposed two intermittent failures in portable
transfer deadlines and reviewer source changes. Both isolated reruns passed.
Keep these observations distinct from the final acceptance results below.

Final native acceptance, with the configured local fixture/receiver binaries:
**2026/2026 passed, 0 failed**. Log:
`/tmp/moontown-integration-native-acceptance.log`. The intermittent failures
above were not reproduced in this final full run; no unrelated production
behavior was changed to make them pass.

The first UI shard pass found an outdated English-label assertion after the
Chinese control change. Its expectations were updated while retaining the
selection, escaping and exact-payload assertions.

Local command logs are retained as `/tmp/moontown-integration-*.log`. Browser
checks cover local public interaction, not production identity deployment or
packaged-app installation. This task delivers source to main.
