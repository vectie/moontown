# Contest Express competition extension contract

Implementation coordination for the Ascend comparison. Extend the existing `src/hackathon` ledger and `/api/contest-express/hackathons` actions. A Challenge remains the event brief. A Program keyed by `challenge_id` adds tracks, calendar, policies, editorial content, and lifecycle. Preserve existing v1 records through defaulted decoding; legacy actions still work for events without a Program.

## Ownership and records

- Mayor: draft, preview, publish, amend, pause, enter review, finalize, publish announcements, resolve appeals.
- Contest Express: program, tracks, registrations, invitation consent, submission windows, evaluation queue, published board.
- MoonBook: materialize versioned briefs and private team receipts through existing workspace contracts; source ledger remains authoritative.
- MoonClaw/worker: execute a registered benchmark runner and return measured evidence; a reviewer approves publication.
- Rabbita: public event tabs, team workbench, review desk, Mayor desk.

Keep old Challenge, Team, Submission, Evaluation structs stable. Add typed arrays to HackathonState: `programs`, `team_profiles`, `invitations`, `submission_packages`, `benchmark_runs`, `appeals`, `program_history`. Agent implementing program model owns these state fields and migration. Agents own separate extension model files for their records.

## Program records (program agent)

`CompetitionProgram`: challenge_id String, state String (draft/open/paused/evaluating/final), organizer String, timezone String, registration_open_ms UInt64, registration_close_ms UInt64, submission_open_ms UInt64, review_close_ms UInt64, max_team_size Int, daily_submission_limit Int, contact_url String, tracks Array[CompetitionTrack], prizes Array[CompetitionPrize], partners Array[CompetitionPartner], faq Array[CompetitionFAQ], announcements Array[CompetitionAnnouncement], evaluator_ids Array[String].

`CompetitionTrack`: id/name/description/scoring_mode/runner_key String, required_materials Array[String], metrics Array[MetricRule], gates Array[QualificationRule]. scoring_mode is rubric or metric; runner_key selects an operator-configured runner, never participant code.
`MetricRule`: id/label/unit/direction String (min/max), baseline Double, weight Double.
`QualificationRule`: id/label/metric_id/comparison String (gte/lte), threshold Double.
`CompetitionPrize`: track_id/place/description String.
`CompetitionPartner`: name/url String.
`CompetitionFAQ`: category/question/answer String.
`CompetitionAnnouncement`: id/title/body String, published_ms UInt64 (server supplied).

Actions: save-program {program, brief: Challenge} (draft or amendment; publication guarded), publish-program {challenge_id}, transition-program {challenge_id,state,reason}, announce {challenge_id,id,title,body}. Existing revise-benchmark still creates a benchmark version. Program operations use `now_ms` and validate windows, tracks, evaluator policy, and finalization readiness.

## Participation (participation agent)

`TeamProfile`: team_id/captain_id/affiliation/track_id String.
`TeamInvitation`: id/team_id/inviter_id/invitee_id/state String (pending/accepted/declined), created_ms UInt64.
`SubmissionMaterial`: kind/url/sha256 String.
`SubmissionPackage`: submission_id/track_id String, materials Array[SubmissionMaterial], benchmark_version Int.
Actions: register-competition-team {team: Team,profile: TeamProfile}; invite-member {id,team_id,inviter_id,invitee_id}; respond-invitation {invitation_id,member_id,accept:Bool}; remove-member {team_id,captain_id,member_id}; submit-package {submission:Submission,package:SubmissionPackage}. Bind actors at hosted adapter. Enforce event windows, team size, one team/event, track selection, required materials, quota, and snapshot benchmark version. Program events use invitations rather than open join-team.

## Evaluation operations (evaluation agent)

`MetricValue`: metric_id String, value Double.
`BenchmarkRun`: id/submission_id/reviewer_id/worker_run_id/state/reason/input_hash/output_hash String, benchmark_version Int, metrics Array[MetricValue], evidence Array[String], queued_ms/finished_ms UInt64. states queued/running/failed/review/approved/rejected. Record trusted measured results; failures never rank. Human approval is required.
`CompetitionAppeal`: id/submission_id/member_id/reason/state/resolution String, created_ms/resolved_ms UInt64.
Actions: queue-benchmark {id,submission_id,reviewer_id}; record-benchmark-result {run_id,worker_run_id,metrics,evidence,input_hash,output_hash,success:Bool,reason}; approve-benchmark {run_id,reviewer_id}; retry-benchmark {run_id}; open-appeal {id,submission_id,member_id,reason}; resolve-appeal {appeal_id,resolution}. Server timestamps all receipts. Evaluation agent exports program-aware `competition_leaderboard(state,challenge_id,track_id)` and readiness helpers. Metric boards use weighted baseline ratios and direction, enforce qualification gates; rubric tracks reuse human reviews. Final board is frozen by final lifecycle and blocks further changes.

## Transport/UI (API and UI agents)

Keep the existing endpoint and backward-compatible actions. GET returns state plus `viewer`, per-challenge legacy `leaderboards`, and `competition_boards` keyed by `challenge_id:track_id`. Board entries: rank, team_id/team_name/submission_id String, score Double, metrics Array[MetricValue], reviewed_ms UInt64, status String. Anonymous GET serves published briefs/program content/boards only; no roster IDs, invitations, private artifacts, evaluation guidance, raw runs or private appeals. Authenticated teams receive own packages, run status and feedback, invites relevant to them. Evaluator roster grants review capability without platform administrator rights. Mutations remain same-origin and role checked; recheck domain invariants under the store lock.

Public tabs: Overview, Tracks & rules, Champion Wall, Stories & updates, FAQ. Participant tab: My team & submissions. Reviewer tab: Review desk. Mayor tab: Mayor desk. Setup collects brief, program/calendar, tracks/scoring/materials, policies/editorial content, then draft preview and publish. Provide readable forms and structured editors; raw JSON is advanced only. Show pending/failed/provisional/final states, receipts, update freshness, and version amendments. All forms use the action names above.

Each agent adds meaningful tests in its owned files. Root integrates dispatch, documentation, MoonBook/MoonClaw boundaries, full checks, and browser workflows. Agents must not overwrite another agent's files or run repo-wide formatting until coordinated.
