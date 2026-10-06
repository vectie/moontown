# Local material-change watches

This opt-in policy extends the existing saved standing-goal cycle. It does not
start a new service or choose a desktop/hosted transport. The current Mayor
routing, MoonClaw packet/run lifecycle, Book persistence and owning-Book review
policy still apply.

## Configure one saved watch

1. In the existing watch composer, choose **Local material changes**.
   Ordinary cadence watches remain the default.
2. Choose an existing registered Book and enter the Book-relative UTF-8 files
   to watch, one path per line. Enter the request, acceptance criteria, and next
   owner action. Choose files whose complete contents are decision-relevant.
3. Save Watch validates the selected Book and every source, saves a goal-bound
   plan inside that Book, and verifies it through the same parser used by the
   running cycle. No JSON editing is required. The accepted request retains the
   selected sources and plan text for readback after reload.
4. The usual town cycle establishes the first baseline without worker dispatch.
   Unchanged source bytes and an unchanged plan remain quiet. A changed source
   or changed plan goes through the existing dispatch path and Book review.

The host-neutral `submit_standing_watch` handler accepts `watch_mode` equal to
`local-material`, the existing title/prompt/target Book/cadence/quality fields,
and `material_sources`, `material_acceptance`, and `material_next_action`.
Sources are a newline-delimited string or array of nonempty strings. The prompt
is the saved intent. The handler never creates an unknown Book or invents a
source. It does not invoke Claw, save a baseline, or start a service.

Identical local-material submissions have the same durable goal and request
identity. Retrying after a lost response repairs missing request receipts without
resetting an existing watch's due tick. An explicit `goal_id` may name a distinct
watch; conflicting existing plans or goals are retained and reported as errors.
Legacy cadence mode keeps the configured operator source policy.

Advanced saved-goal configuration is still supported. Its plan schema remains:

```json
{
  "contract": "moontown.material_watch_plan.v1",
  "goal_id": "watch-customer-assumption",
  "book_id": "research-customer",
  "intent": "Keep the customer launch assumption current",
  "acceptance": "Review the exact source change before changing the launch plan",
  "next_action": "Founder: decide whether the launch date should change",
  "sources": ["sources/customer-assumption.txt", "sources/market-assumption.txt"]
}
```

For advanced configuration, bind the saved goal's `source_policy` to
`local-material:plans/customer-watch.json`, retaining its goal/Book identity.

Paths in the plan are relative to the Book workspace. Select small source files
whose complete contents are relevant to the decision. This policy compares exact
UTF-8 bytes; it does not infer whether a rewritten article or timestamp change is
semantically material. Source list order alone does not count as a change.
Both setup and runtime reject duplicate paths, traversal, missing files,
non-lossless UTF-8 and symlinks resolving outside the owning Book.

## Read back and resume

- The watch composer retains the accepted source selection and plan. A saved
  request is initially pending its first baseline; only an actual cycle record
  can show that the baseline has been saved. Due ticks and quiet/change/blocked
  outcomes come from the existing goal and watcher ledger
- The existing task/result summary shows the retained input path and SHA-256,
  each source path/hash, acceptance and next owner action. The input JSON retains
  the saved goal, full plan, and exact before/after source text
- The input is included in the normal Book result artifact list. A successful
  worker result still awaits the normal Book review; no accepted truth is changed
  by the local comparison
- The existing watcher ledger records quiet checks and review decisions. A
  repeated unchanged check creates no new task or review item. Existing review
  debt stays visible in the original execution
- Restart restores a durable result over a stale run-less town checkpoint. A
  pending dispatch keeps the original task and known run. If dispatch may have
  happened but its receipt is missing, the cycle waits for reconciliation rather
  than starting a new task. The existing Mayor scheduler and retry boundary keep
  that dispatch-unconfirmed state after the stale window; a late original
  detached receipt resumes the same run
- Missing sources, invalid plans, damaged journals or unavailable inputs are
  visible blocked/health outcomes. They are never reported as no change. Existing
  input and task/run evidence remain available for repair
- Restore the missing plan/source or reconcile the original Claw receipt, then
  use the existing supervision/resume flow. Do not erase the watch journal to
  retry an uncertain dispatch
- Book acknowledgements arriving while the per-goal journal lock is held are
  retained as typed, immutable receipt files beside the journal. Restart or the
  next locked cycle applies them idempotently. Include this whole directory in a
  future backup/restore qualification, not only `journal.json`
- Late failed/stale observations cannot replace a retained terminal result or
  output waiting for Book persistence. A transient run-less deferred result is
  still unconfirmed and can adopt its original late run receipt

The per-goal lock prevents two competing local supervisors from reserving the
same watch change. Journal replacement is atomic on the local filesystem. This
does not qualify power-loss/fsync, a cross-goal transaction, remote filesystem
locking, an authenticated always-on host, multi-day operation, live providers or
delivery into the MoonProj company queue. Those remain separate acceptance work.
