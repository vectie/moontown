///|
test "oneoff client keeps forms and retained result across interruption but rejects stale result identity" {
  let state : @collaboration_contract.Client = {
    ..@collaboration_contract.Client::new(),
    dirty: false,
    revision: "r-source",
  }
  let pending = state.begin("oneoff-start", state.draft.draft_id)
  assert_eq(
    pending.begin("oneoff-start", state.draft.draft_id).generation,
    pending.generation,
  )
  let work = {
    ..@collaboration_contract.empty_work(state.draft.draft_id, state.revision),
    status: "completed",
    result_digest: "sha256:fixture",
  }
  let reply : @collaboration_contract.Reply = {
    contract_version: "moontown.collaboration.reply.v1",
    request_id: pending.generation.to_string(),
    action: "oneoff-start",
    ok: true,
    error: "",
    books: [],
    drafts: [],
    saved: None,
    prepared: None,
    work: Some(work),
    outcomes: [],
    outcome: None,
    source_listing: None,
  }
  let ready = pending.settle(
    pending.generation,
    "oneoff-start",
    reply.to_json().stringify(),
  )
  assert_eq(ready.work, Some(work))
  let form = ready.edit("work_rationale", "Retain the uncertainty")
  assert_false(form.dirty)
  assert_eq(form.work, ready.work)
  let refresh = form.begin("oneoff-read", form.draft.draft_id)
  let interrupted = refresh.settle(
    refresh.generation,
    "oneoff-read",
    "broken response",
  )
  assert_eq(interrupted.work, ready.work)
  assert_eq(
    interrupted.work_fields.get("work_rationale"),
    Some("Retain the uncertainty"),
  )
  let stale = pending.settle(
    pending.generation,
    "oneoff-start",
    { ..reply, work: Some({ ..work, revision: "r-other", }), }
    .to_json()
    .stringify(),
  )
  assert_eq(stale.work, None)
  assert_true(stale.notice.contains("another"))
  let edit = ready.edit("question", "A changed question")
  assert_true(edit.work is None)
  assert_false(edit.begin("oneoff-start", edit.draft.draft_id).busy())
}
