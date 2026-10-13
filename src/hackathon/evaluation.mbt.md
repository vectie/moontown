# Contest Express measured review

The Mayor names evaluators in the competition program. A reviewer queues a
benchmark against a submission package. The worker records measured evidence,
then the assigned reviewer approves or rejects the result. Only approved,
qualified results for the current benchmark version enter the Champion Wall.
Scores are `100 × weighted mean(baseline / value)` for minimizing metrics and
`100 × weighted mean(value / baseline)` for maximizing metrics. Qualification
gates must all pass. Rubric tracks retain their existing human review scores.

```mbt check
///|
test {
  let state = @hackathon.empty_hackathon_state()
  assert_eq(
    @hackathon.competition_leaderboard(state, "unknown", "unknown").length(),
    0,
  )
  assert_true(!@hackathon.competition_finalization_ready(state, "unknown"))
}
```

The operator installs a private runner registry at
`MOONTOWN_CONTEST_RUNNERS`, or the Contest Express product state directory's
`runners.json`. The JSON file is an array of records with `key`, `program`,
`args`, `cwd`, and `timeout_ms`. `program` and `cwd` must be absolute paths;
arguments are passed literally without a shell. The worker receives an
immutable request JSON file through the `CONTEST_EXPRESS_REQUEST` environment
variable. No participant command, artifact URL, or source file is executed by
Contest Express. The registered worker is responsible for verifying material
hashes, acquiring its benchmark hardware, and running its trusted evaluation
procedure against the package.

The process must emit one JSON document on stdout:

```json
{
  "metrics": [ { "metric_id": "latency", "value": 50.0 } ],
  "evidence": [ "worker receipt identifying hardware, dataset, and procedure" ]
}
```

Each stdout/stderr stream is limited to 1 MiB and the configured timeout is
limited to one hour. Nonzero exits, malformed results, missing evidence,
unavailable registries, and timeouts produce failed receipts. Hardware such as
a GPU must be made available by the operator's registered worker; Contest
Express does not provision it. Request, output, and receipt files are private
and bound by SHA-256 hashes. A retry gets a fresh run identity and retains the
failed attempt. Benchmark amendments allow accepted packages to be rerun with
the new benchmark while retaining their original submission snapshot.

Appeals belong to the submission's team. Open appeals and undecided current
results prevent finalization. The final program freezes decisions and boards.
