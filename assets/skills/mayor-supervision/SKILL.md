# Mayor Supervision

Use this skill when the Mayor claw supervises persisted town executions and must decide recovery actions.

## Responsibility

- inspect persisted execution status
- detect stale runs, retryable failures, persistence backlog, and review backlog
- decide whether to retry, persist, review-sync, or escalate
- keep recovery bounded and idempotent

## Hard Rules

- A stale run is not success.
- Do not retry forever.
- Preserve the book boundary when retrying.
- Persist completed work before calling the lane healthy.
- Review backlog should remain visible to the town, but routine review-gated
  artifacts do not block the live watch loop unless they contain an unresolved
  failure, stale worker, safety gate, or PlanBook gap.
- Operational activity is not growth. Separate retries, logs, and site rebuilds
  from domain knowledge, civic exchange, or implementation progress.
- Civic progress requires protocol evidence: inbox, contribution, reduction,
  outbox, review, or return-home records.
- PlanBook progress requires plan/backlog/evidence updates, validation results,
  code/test changes, or an explicit no-change completion record.
- If a validated source patch changed MoonTown code used by the live daemon,
  require a daemon reload request before accepting live proof:
  `moon run cmd/main -- daemon restart "validated source patch"`.
  Treat packets emitted before that reload as stale-process evidence.
- Do not let a temporary MoonClaw worker own durable memory; route memory
  decisions back to the target MoonBook bookkeeper.

## Output Contract

Return `mayor.supervision.packet.v1`:

```json
{
  "tick": 12,
  "summary": "Mayor produced 2 supervision directives.",
  "directives": [
    {
      "kind": "mark-stale-retry",
      "task_id": "goal-research-moontown-analysis",
      "execution_status": "Stale",
      "detail": "Execution missed its heartbeat window and needs mayor recovery.",
      "next_retry_tick": 15
    }
  ]
}
```

## Examples

### Example: stale run becomes retryable

Input situation:

- status: `Running`
- heartbeat expired
- attempt: `1`

Output:

```json
{
  "tick": 9,
  "summary": "Mayor produced 1 supervision directives.",
  "directives": [
    {
      "kind": "mark-stale-retry",
      "task_id": "goal-research-moonbook-analysis",
      "execution_status": "Stale",
      "detail": "Execution goal-research-moonbook-analysis missed its heartbeat window and needs mayor recovery.",
      "next_retry_tick": 10
    }
  ]
}
```

### Example: civic protocol growth

Input situation:

- building: `social-square`
- schedule due: true
- latest round wrote reduction and return-home ledgers

Output:

```json
{
  "tick": 31,
  "summary": "Mayor produced 1 supervision directives.",
  "directives": [
    {
      "kind": "record-civic-growth",
      "task_id": "civic-social-square-round-31",
      "execution_status": "Completed",
      "detail": "Social Square produced reviewable reduction outputs and returned them to participating MoonBooks.",
      "next_retry_tick": null
    }
  ]
}
```

### Example: persistence backlog

Input situation:

- status: `AwaitingPersistence`

Output:

```json
{
  "tick": 14,
  "summary": "Mayor produced 1 supervision directives.",
  "directives": [
    {
      "kind": "persist-result",
      "task_id": "goal-research-moonclaw-synthesis",
      "execution_status": "AwaitingPersistence",
      "detail": "Execution goal-research-moonclaw-synthesis should be persisted into MoonBook.",
      "next_retry_tick": null
    }
  ]
}
```
