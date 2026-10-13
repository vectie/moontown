# Running a Contest Express competition

Contest Express extends the existing civic challenge ledger. The Mayor publishes the event and manages its lifecycle. Residents form teams by invitation consent. Assigned evaluators review immutable submissions. The Champion Wall derives results from approved current-benchmark receipts.

## Mayor journey

Open Contest Express from MoonTown and enter the Mayor desk. Create a competition draft with its brief, registration/submission/review calendar, team size and daily quota, evaluator accounts, and tracks. Each track uses either the existing human rubric or measured metrics with baselines, weights and qualification gates. Required material kinds are enforced on submission. Add prizes, partners and FAQ entries, inspect the public preview and saved checklist, then publish.

Registration and submission follow their stored timestamps. The organizer time zone is descriptive; date controls and the public calendar use the viewer's device time zone. Daily submission quotas reset at 00:00 UTC. Changing the competition after teams register preserves their track, scope, size and quota contracts; closing times can extend. Published amendments and lifecycle reasons appear in the update timeline. Benchmark changes archive the old inputs and remove earlier-version scores until re-evaluation. Pending benchmark work must finish or be rejected before its inputs change.

The Mayor can pause participation, enter the evaluation period after submission closes, resolve appeals, and finalize after the review deadline once every team's latest accepted package has a decision and no active work or appeals remain. Finalization freezes competitive records. Announcements and champion stories can still be published afterward.

## Teams and reviewers

The captain registers an event track and affiliation, then sends invitations to account IDs. Each invited resident accepts or declines. One account can belong to one team per event. A captain can remove members before the team's first submission while registration remains open.

Submit an artifact link, first person solution, and the material kinds required by the selected track. Every material needs its actual SHA-256 checksum. The submission receives a server timestamp, version, and benchmark snapshot. It remains an immutable receipt; a later submission creates a new version. Artifacts are external links rather than hosted binary uploads.

Reviewers must appear in the event evaluator roster, including a Mayor who intends to judge. Team members cannot review their own work. Human review requires points and evidence for every rubric criterion. Metric review queues the registered worker, inspects measured evidence and hashes, and requires human approval before ranking. A failed worker never becomes a zero score. Retries create new receipts; the Mayor can record interruption of abandoned work and then a reviewer retries it. Teams can inspect their own status and feedback and raise an appeal against a completed review.

## Registering real benchmark workers

Set `MOONTOWN_CONTEST_RUNNERS` to a private JSON registry. A track's runner key selects one entry:

```json
[
  {
    "key": "ascend-rtf",
    "program": "/opt/contest/run-benchmark",
    "args": ["--official-environment"],
    "cwd": "/opt/contest",
    "timeout_ms": 3600000
  }
]
```

Install the trusted runner and its datasets/hardware environment before using the track. Town executes the literal program and arguments without a shell, with an empty inherited environment and `CONTEST_EXPRESS_REQUEST` pointing to a private versioned request JSON. The runner reads the request and writes JSON to stdout:

```json
{
  "metrics": [
    {"metric_id": "rtf", "value": 0.35},
    {"metric_id": "accuracy", "value": 84.2}
  ],
  "evidence": ["https://evidence.example.org/retained-run-123"]
}
```

The worker validates every configured metric, captures SHA-256 input/output hashes and private receipts, limits each stream to 1 MiB and each process to at most one hour, and returns the run for reviewer approval. Participant URLs and supplied scripts are never executed by Town. Remote hardware dispatch, environment/image installation, and artifact retrieval belong inside the operator's trusted runner. Deploy the service on the environment authorized to access those resources.

Metric scores are the weighted mean of baseline ratios times 100: lower-is-better uses baseline/value and higher-is-better uses value/baseline. Qualification gates must pass before ranking. The highest eligible reviewed submission per team ranks; ties favor earlier review completion then team ID. Raw metric columns remain visible so the composite score can be understood. Rubric tracks use their points total.

## MoonBook and MoonClaw

Every ledger commit attempts to materialize a private event book and a separate private team book alongside the ledger (`hackathons.json.books`). The companion `hackathons.json.moonbooks.json` catalog uses the existing MoonBook catalog contract. Brief and program history, submissions, evaluations, appeals, and executable receipt events remain recoverable there. Team research pages are retained rather than overwritten. The Mayor sees a revisioned synchronization status and can retry reconstruction without duplicating the committed ledger action.

Event books include the existing civic contest coaching skill identity, a Contest Express MoonClaw review profile, and the `wiki/reviews/contest-submissions.md` queue. These support coaching and evidence recommendations. Official process measurements use the registered Town background worker, and official scores remain subject to evaluator approval. The workspace scaffold does not claim that a MoonClaw agent has completed a review or that the full external MoonBook rendering engine has run.

## Browser acceptance fixture

`scripts/contest-express-ui-fixture.mbtx` provides a loopback-only synthetic identity service on port 17864 for browser acceptance testing. It defines fake Mayor, Alice, Bob, and reviewer accounts with a documented test-only password. Use disposable suite state, two Town origins (`localhost` and `127.0.0.1`) for separate cookie sessions, and a synthetic registered runner. The fixture verifies role-aware application behavior; it does not test a production LunaNexa deployment or actual Ascend hardware.
