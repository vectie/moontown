# Hackathons in Contest Express

## Product decision

A hackathon is a Mayor-published **Contest Express challenge**, not a new town or a second competition backend. Contest Express already describes contest calendars, team preparation, readiness scoring, submission review, mock judge feedback, and champion-wall stories in `src/civic/services_registry_learning.mbt`. The Wenyu vision gives the venue a spectator and battle mode in `docs/project/wenyu.md`. The hackathon adds a governed challenge, teams, online submissions, evaluation receipts, and a live score projection to that lane.

Use the established boundaries: Mayor routes and supervises; the Contest Express civic protocol coordinates the event; MoonBook owns durable briefs, team work, submissions, rubrics, reviews, and evidence; MoonClaw workers may coach or run bounded evaluation work; a human evaluator signs off on consequential scores; Rabbita/Lepusa and any later mini-app show audience-safe projections. The town map's Contest Express building is an entrance and status surface. Its animation and civic quest cards cannot establish that a team submitted or earned points. Only durable records can.

| Town concept | Hackathon responsibility |
| --- | --- |
| Mayor | Publish and amend the topic, deadline, benchmark, rubric, evaluator roster, and visibility; resolve disputes and close the event. |
| Contest Express | Own the challenge lifecycle, registration queue, submission window, evaluation queue, and public event page. |
| MoonBook | Keep the challenge's immutable versions and each team's private workspace, submission receipts, evaluation evidence, and review trail. |
| Bookkeeper / reviewer | Preserve the source and decision history; verify eligibility, scoring evidence, and publication suitability. |
| Civic quests | Turn the next concrete action into a team-facing checklist: join, complete brief, submit, address review, or present. Quest status comes from durable records. |
| Energy Valley projection | Show the Contest Express venue, active challenge, deadline, queue health, and leaderboard revision without disclosing private artifacts. |
| Social Square / Talent Avenue | Help residents form teams by consent and display team profiles when published. They do not silently enroll people. |

## People and journeys

**Mayor / organizer.** From Contest Express, draft a challenge and preview the information page. Attach the benchmark package and evaluation materials, set the scoring rubric and timing, designate evaluators, then publish a versioned brief. A post-publication change creates a new version with a visible amendment notice. The Mayor sees registration counts, submitted/evaluated/pending totals, overdue work, score disputes, and a publish/close control. A Mayor can pause scoring or mark results provisional while correcting a benchmark; old evaluations remain in the audit trail.

**Team lead and member.** A resident can inspect the public brief before joining. The lead registers a named team and invites members; each member accepts before gaining workspace access. Members see the same scope, benchmark version, deadline, and checklist. Their private MoonBook workspace holds research, drafts, rehearsal feedback, and submission history. The lead or an authorized member submits an artifact link and a first-person solution statement online. The system returns an immutable receipt with submission version, server timestamp, and benchmark version; edits produce a new version instead of overwriting the receipt. A team can see its private evaluator feedback and whether its score is pending, provisional, or ranked.

**Evaluator / keeper.** An evaluator opens an assigned submission in a review queue with the exact benchmark, rubric, and artifacts used. Each criterion requires points and evidence. Automation may calculate reproducible benchmark measures, but the evaluator confirms the run, handles unavailable or invalid artifacts, and signs the review receipt. A keeper maintains the evidence links and amendment history. Evaluators should see team identity only when the event's published rules require it; a blind review mode is preferable where feasible. An evaluator's own team cannot be assigned to that evaluator.

**Spectator / operator.** A visitor opens the Contest Express information page, watches the countdown and public team list, and follows the leaderboard. The board labels pending and provisional results, last update, benchmark version, and tie rule. It does not show private draft links, raw judge notes, or internal paths. The operator sees projection freshness and failed evaluation jobs separately from team rank, and can trace a displayed rank back to durable score receipts.

## Information page and source records

The public page is a projection of a versioned challenge brief. Its required editorial fields are:

| Field | Meaning and presentation |
| --- | --- |
| Name | The event and challenge title, stable enough to identify the competition in cards and receipts. |
| Topic | Mayor's specific problem statement and desired outcome. |
| Scope | Included work, exclusions, eligibility, deliverables, limits, and deadline/time zone. |
| Possibility wiki | Linked background, prior approaches, useful sources, open questions, and allowed assumptions. It is context, not a hidden answer key. |
| First-person solution | A short Mayor-authored example of how a participant might approach the problem, explicitly labeled as inspiration rather than the required solution. Each team provides its own first-person account with its submission. |
| Benchmark | Dataset or task inputs, runner/instructions, expected output format, constraints, version, provenance, licenses, and a published subset when hidden holdout data is used. |
| Evaluation materials | Rubric with criterion IDs and maximum points, test instructions, reviewer guidance, evidence expectations, tie-break rule, and appeal window. |

The page should also show event state (`draft`, `open`, `closed`, `evaluating`, `final`), organizer, registration/submission deadlines, amendment history, public teams, FAQ, and contact/appeal route. Separate the public brief from private benchmark holdouts, team workspaces, and evaluator notes. Every link should be an audience-safe URL; local MoonBook paths are for the operator, not the browser.

## Lifecycle and scoring rules

1. **Draft and publish.** The Mayor validates nonempty brief fields, deadline, benchmark materials, evaluation materials, and a rubric with unique criteria and positive maxima. Publication records the author, timestamp, and benchmark version.
2. **Register.** Teams join a published challenge. Membership changes have explicit invitations and receipts. One resident's identity cannot be silently reused by another team. Eligibility and team size are challenge rules, checked before acceptance.
3. **Prepare and submit.** Teams work privately. Contest Express may generate readiness checks and mock judge advice, clearly separated from official scoring. The server timestamps submission. The accepted version at deadline is frozen by a stated rule; late submissions are rejected unless the Mayor publishes a recorded extension.
4. **Evaluate.** The evaluator uses the benchmark version associated with that scoring round, records complete criterion scores and evidence, and issues a review receipt. A run failure is `pending` or `invalid`, never zero points without a reviewable reason. Corrections create superseding receipts, preserving the old ones.
5. **Publish and finalize.** The leaderboard is derived from valid current-version evaluations, with one ranked result per team. For an open iterative event, use the team's best eligible evaluated submission; if final-submission-only is chosen, publish that rule in the brief before registration. Sort by total descending, then earlier evaluation completion, then stable team ID; label the tie rule. Final ranking requires the Mayor's close/finalize action and a completed review or explicit disposition for every accepted submission.

Changing benchmark inputs, rubric, or evaluation guidance increments the benchmark version. Old scores remain auditable but leave the current leaderboard until re-evaluated under the new version. A public banner should say that ranks are being recalculated. A change that affects fairness should be announced to all teams and may require a deadline extension. Evaluation materials and benchmark inputs must have provenance and access controls; holdout answers cannot leak through the public page or team response.

“Real time” means a revisioned, server-derived projection that updates after each committed registration, submission, or evaluation. The client can poll at a short bounded interval and refresh when the revision changes; push transport is optional. It must show `last updated` and a stale/unavailable state, never animate simulated scores or silently keep an obsolete board as live. Teams without an eligible completed evaluation appear as `pending`, not rank zero. A private preview may show feedback before a score is public; public visibility follows the event policy.

## Rollout through the existing architecture

1. **Canonical use case.** Put validated lifecycle operations behind a shared application contract and durable product ledger. The desktop adapter supplies same-origin operator actions; a network-facing or mini-app adapter needs participant sessions, role checks, request limits, and audience-specific response shapes before opening writes. Keep transport, authorization, and page rendering out of the domain scoring functions. A durable `revision` supports projection refresh.
2. **MoonBook integration.** Create or link one Contest Express challenge book with versioned brief and rubric pages, plus an isolated team workspace per challenge/team. Store artifact references and hashes rather than copying arbitrary URLs into public HTML. Queue submission and score reviews in Contest Express's existing `wiki/reviews/contest-submissions.md` pattern; link every published result to a receipt. Guard workspace reads by team/evaluator/Mayor roles.
3. **Contest Express projection.** Add the challenge card and information page to the existing civic module entrance and route. Project the public scoreboard from the ledger, the team's private submission/feedback status from its authorized view, and the operator's queue/freshness status from the same source. Show civic quest progress only after a matching durable receipt exists. Keep demo simulation labels explicit until wired to real state.
4. **Evaluation operations.** Add reproducible benchmark execution with bounded resources, captured input/output hashes, retry and failure states, evaluator assignment, conflict checks, score override with reason, and appeal workflow. Mayor can inspect the audit trail before finalization.
5. **Wider access.** Expose participant and spectator routes through the same product use cases after authentication, privacy review, and load testing. Add streaming updates only if polling fails the measured freshness target.

## Acceptance criteria and current gaps to verify

- A Mayor can publish a complete brief, add benchmark/evaluation materials, amend them with visible version history, and close/finalize the event. Invalid rubrics and missing inputs are rejected.
- A team can join with confirmed membership, work in a private workspace, submit online before deadline, and recover its timestamped versioned receipt after restart. Other teams cannot read its drafts or private feedback.
- An authorized evaluator can score every criterion against the correct benchmark version with evidence; conflicts are prevented and corrections remain auditable. Benchmark execution failure cannot become an ordinary numeric score.
- A spectator can view a public information page and a leaderboard that updates after a committed evaluation, labels provisional/pending/stale states, applies the published tie rule, and excludes scores from superseded benchmark versions.
- The Mayor, team, evaluator, and spectator views agree on challenge ID, benchmark version, submission receipt, and published score. The projection exposes no local paths, hidden holdout data, or private notes.
- A full scenario test covers two teams, repeated submissions, a benchmark amendment and re-evaluation, a tie, an appeal/correction, service restart, and a stale projection. Browser verification covers the information page and role-specific views.

The `hackethon` branch now has a revisioned JSON ledger, Mayor and participant API actions, a Contest Express information page, rubric review forms, and a five-second polling Champion Wall. Hosted participation uses the existing LunaNexa account identity and limits Mayor actions to platform operators. The server timestamps submissions and evaluations, rejects a reviewer scoring their own team, and removes old benchmark-version scores from the current board. Team joining is open self-enrollment by public team ID; invitation or approval is future work. The current ledger is product state, not yet a MoonBook workspace per team. Artifact URLs are recorded rather than uploaded or executed, and evaluation is a human rubric review rather than an automated benchmark runner. These remaining items are rollout gates for a larger managed competition service; the implemented flow is usable for link-based submissions and online human evaluation.
