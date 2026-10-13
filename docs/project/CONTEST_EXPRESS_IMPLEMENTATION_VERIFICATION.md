# Contest Express implementation verification

Verified on 2026-10-13 on branch `hackethon`.

## Existing concepts extended

| Competition capability | MoonTown concept and implemented surface |
| --- | --- |
| Event creation and public information | The Mayor's civic Challenge remains the brief. CompetitionProgram adds draft/publication, calendar, lifecycle, tracks, team policy, prizes, partners, FAQ and update history. Overview keeps name, topic, scope, possibility wiki and first person solution prompt. |
| Rules and benchmarks | Tracks & rules publishes required materials, metric baselines, weights and qualification gates. Evaluation guidance and reviewer roster stay private. |
| Registration and participation | Existing teams gain captain-owned registration, track and affiliation, consent-based invitations, capacity checks and one-team-per-event enforcement. |
| Online submissions | Immutable solution receipts add required material links, SHA-256 declarations, versions, server timestamps, quotas and benchmark snapshots. |
| Online evaluation | The Review desk supports human rubric review and a trusted process worker queue, hashed evidence receipts, explicit approval, failure recovery, retries and appeals. |
| Ranking | The Champion Wall adds per-track raw metric columns and derived scores, current benchmark eligibility, qualification gates, deterministic ties and provisional/final status. |
| Shared knowledge | Private event/team MoonBooks retain brief, research and receipts. The existing civic contest coaching identity and a MoonClaw review profile support evidence recommendations. The ledger owns official decisions. |

## Browser acceptance

Two separate cookie origins shared disposable suite state: a Mayor on `localhost:17862` and a participant on `127.0.0.1:17863`. The loopback-only identity fixture supplied synthetic Mayor, Alice, Bob and reviewer accounts. No production identity or real participant artifacts were used.

Verified through the actual UI:

1. Mayor authored a two-track draft, calendar, evaluator roster, private guidance, required materials, metric rules, a prize, partner and FAQ. Draft stayed hidden from anonymous visitors.
2. Publication exposed the public event without private reviewer guidance or Mayor controls.
3. Alice registered Valley Builders, selected Performance and invited Bob. Bob could see the invitation but could not see Alice's submission before accepting. Acceptance granted team access; captain-only controls remained hidden from Bob.
4. Alice submitted source/report links, synthetic checksum declarations and a first person solution. The receipt carried a server timestamp and benchmark version.
5. Mayor queued the registered synthetic runner. The background worker produced a retained metric receipt, and the board stayed empty until approval.
6. Approval produced a provisional board entry with latency 50, quality 95 and score 147.500, derived as `(100 / 50 + 95 / 100) / 2 * 100`. These values are synthetic acceptance data, not hardware measurements.
7. Bob raised an appeal; Mayor resolved it with an explanation; Bob received the decision on his receipt.
8. FAQ search/expansion and a published story worked. Mayor's MoonBook synchronization retry reported two current private books at the same ledger revision.

The first browser pass exposed a read-only textarea `type` assignment that prevented startup. The editor constructor was fixed and covered by a regression test. Fresh final Mayor and participant tabs reported no console errors.

Desktop screenshots are saved outside the repository under `/Users/kq/.codex/visualizations/2026/10/13/contest-express/`. A temporary browser viewport override behaved inconsistently in the browser tooling, so no completed phone acceptance is claimed.

## Automated checks

| Check | Result |
| --- | --- |
| Native hackathon and desktop server tests (`moon test src/hackathon src/cmd/desktop_server --target native --strip --warn-list '-all'`) | 89 passed, 0 failed |
| Competition UI and existing hackathon tests (`node --test competition-ui.test.js hackathon.test.js`) | 10 passed, 0 failed |
| Static product assembly and production artifact verification | Passed; 306 files verified |
| `moon info` and `moon fmt` | Passed; generated public interface changes reviewed; unrelated formatter changes removed |
| `git diff --check` | Passed |
| Full native repository tests | 1,849 passed, 7 failed |
| All existing UI test files | 67 passed, 2 failed |

Full native failures are outside the changed feature files: one Wenyu no-change owner test expected `running` but observed `waiting_input`; six collaboration-authoring crossings require separately configured local Claw/Book binaries. The full log is `/tmp/moontown-competition-full-tests.log`. No baseline reproduction was performed, so these are not claimed to be pre-existing failures.

The two broader UI failures are source-pattern assertions in `runtime_intersections.test.js` and `transport_runtime_disabled.test.js`, against unchanged Energy Valley/metro implementation files. They concern map entry hiding and portal positioning. Competition-specific checks pass.

## Deployment boundaries

Real evaluation requires an installed trusted runner, datasets and authorized hardware. Remote dispatch, artifact retrieval and environment provisioning belong in that runner. The acceptance fixture does not verify a production LunaNexa deployment, actual Ascend execution or external MoonBook rendering. Artifacts are linked submissions rather than hosted binary uploads; prizes are published descriptions rather than payout processing.

See [the operator guide](CONTEST_EXPRESS_OPERATOR_GUIDE.md) for configuration and the [competition contract](CONTEST_EXPRESS_COMPETITION_CONTRACT.md) for the domain model.
