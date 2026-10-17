///|
fn collective_fixture() -> (
  @collaboration_contract.SavedDraft,
  @collaboration_contract.OneoffWork,
  Json,
) {
  let (original, work, _) = salon_fixture()
  let saved = {
    ..original,
    draft: {
      ..original.draft,
      reviewer_id: "alex",
      reviewer_name: "Alex",
      objection_reviewer_id: "sam",
      objection_reviewer_name: "Sam",
      participants: ["water", "mobility"].map(id => {
        book_id: id,
        source_paths: ["raw/notes.md"],
        focus_area: id,
        perspective: "Original independent perspective",
        contribution: "Original assignment",
        next_artifact: "Original report",
      }),
    },
  }
  let fields : Json = {
    "review_version": work.review_version,
    "collective_new_id": "combined-pilot",
    "collective_result_digest": work.result_digest,
    "collective_title": "Shared observation pilot",
    "collective_hypothesis": "Joint observations can distinguish cohort and transport effects.",
    "collective_experiment": "Compare matched observations from both domains before any deployment.",
    "collective_falsifier": "No difference remains after matching cohorts.",
    "collective_dissent": "The cohorts may still be incomparable.",
    "collective_assumptions": "Check recruitment and measurement compatibility.",
    "collective_quote_water": "Deterministic local fixture output: water",
    "collective_quote_mobility": "Deterministic local fixture output: mobility",
    "collective_connection_water": "Water supplies one observation domain.",
    "collective_connection_mobility": "Mobility challenges the cohort assumption.",
    "collective_challenge_water": "Check observation comparability.",
    "collective_challenge_mobility": "Find a transport-based counterexample.",
    "output_digest": "browser-forged-output",
  }
  (saved, work, fields)
}

///|
test "collective experiment returns independent challenge assignments with exact cross-book provenance" {
  let (saved, work, fields) = collective_fixture()
  guard @collaboration_contract.collective_followup(saved, work, fields)
    is Ok(next) else {
    fail("Expected connected peer-challenge draft")
  }
  assert_eq(next.draft_id, "combined-pilot")
  assert_eq(next.participants.length(), 2)
  assert_eq(next.reviewer_id, "alex")
  assert_eq(next.objection_reviewer_id, "sam")
  assert_eq(
    next.participants[0].source_paths,
    saved.draft.participants[0].source_paths,
  )
  assert_true(
    next.participants[0].perspective.contains(
      "Check observation comparability.",
    ),
  )
  assert_true(
    next.participants[1].perspective.contains(
      "Find a transport-based counterexample.",
    ),
  )
  assert_true(next.question.contains("sha256:output-water"))
  assert_true(next.question.contains("sha256:output-mobility"))
  assert_true(next.question.contains("sha256:source-water"))
  assert_true(next.question.contains("\"failed_participants\""))
  assert_true(next.question.contains("missing"))
  assert_true(next.question.contains("\"genuine_emergence_verified\": false"))
  assert_true(next.question.contains("\"experiment_executed\": false"))
  assert_true(next.question.contains("captures current files"))
  assert_false(next.question.contains("browser-forged-output"))
  assert_false(next.participants.any(p => p.book_id == "missing"))
  assert_true(next.objection.contains(saved.draft.objection))
  assert_true(next.objection.contains("The cohorts may still be incomparable."))
  assert_true(next.decision_prompt.contains("does not approve or execute"))
  assert_eq(
    @collaboration_contract.collective_followup(saved, work, fields),
    Ok(next),
  )
  assert_eq(saved.draft.draft_id, "salon")
}

///|
test "collective experiment rejects incomplete fabricated stale or single-book proposals" {
  let (saved, work, fields) = collective_fixture()
  for
    (key, value) in [
      ("collective_new_id", "salon"),
      ("collective_new_id", "../unsafe"),
      ("collective_result_digest", "sha256:stale"),
      ("collective_quote_water", "A fabricated finding"),
      ("collective_quote_mobility", ""),
      ("collective_connection_water", "  "),
      ("collective_challenge_mobility", ""),
      ("collective_falsifier", ""),
      ("collective_dissent", ""),
      ("collective_assumptions", ""),
      ("collective_hypothesis", ""),
      ("collective_experiment", ""),
    ] {
    assert_true(
      @collaboration_contract.collective_followup(
        saved,
        work,
        change_salon_field(fields, key, value.to_json()),
      )
      is Err(_),
      msg=key,
    )
  }
  assert_true(
    @collaboration_contract.collective_followup(
      saved,
      { ..work, review_version: 2, },
      fields,
    )
    is Err(_),
  )
  assert_true(
    @collaboration_contract.collective_followup(
      saved,
      { ..work, revision: "other", },
      fields,
    )
    is Err(_),
  )
  assert_true(
    @collaboration_contract.collective_followup(
      saved,
      { ..work, status: "running", },
      fields,
    )
    is Err(_),
  )
  assert_true(
    @collaboration_contract.collective_followup(
      saved,
      { ..work, participants: [work.participants[0]], },
      fields,
    )
    is Err(_),
  )
  assert_true(
    @collaboration_contract.collective_followup(
      saved,
      { ..work, participants: [work.participants[0], work.participants[0]], },
      fields,
    )
    is Err(_),
  )
  assert_true(
    @collaboration_contract.collective_followup(
      { ..saved, sources: [], },
      work,
      fields,
    )
    is Err(_),
  )
  assert_true(
    @collaboration_contract.collective_followup(
      { ..saved, draft: { ..saved.draft, participants: [], }, },
      work,
      fields,
    )
    is Err(_),
  )
}

///|
test "collective notes survive retries while independent salon and new result invalidation stay bounded" {
  let (saved, work, fields) = collective_fixture()
  let initial : @collaboration_contract.Client = {
    ..@collaboration_contract.Client::new(),
    draft: saved.draft,
    revision: saved.revision,
    sources: saved.sources,
    work: Some(work),
    dirty: false,
  }
  let form = initial
    .edit("work_salon_mode", "compare")
    .edit("work_salon_dissent", "Earlier comparison note")
    .edit("work_collective_mode", "compose")
    .edit("work_collective_new_id", "combined-pilot")
    .edit("work_collective_hypothesis", "Shared pilot")
    .edit("work_rationale", "Prior decision rationale")
    .edit("work_outcome_summary", "Prior outcome interpretation")
  assert_eq(
    form.edit("work_collective_mode", "compose").work_fields,
    form.work_fields,
  )
  assert_eq(
    form.work_fields.get("work_collective_result_digest"),
    Some(work.result_digest),
  )
  let pending = form.begin("oneoff-followup", saved.draft.draft_id)
  assert_eq(
    pending.edit("work_collective_mode", "off").work_fields,
    form.work_fields,
  )
  let interrupted = pending.settle(
    pending.generation,
    "oneoff-followup",
    "interrupted",
  )
  assert_eq(interrupted.work_fields, form.work_fields)
  let discarded = form.edit("work_collective_mode", "off")
  assert_eq(discarded.work_fields.get("work_collective_hypothesis"), None)
  assert_eq(
    discarded.work_fields.get("work_salon_dissent"),
    Some("Earlier comparison note"),
  )
  assert_eq(
    form.edit("work_salon_mode", "off").work_fields.get(
      "work_collective_hypothesis",
    ),
    Some("Shared pilot"),
  )
  assert_eq(
    form.edit("question", "New question").work_fields.get(
      "work_collective_mode",
    ),
    None,
  )
  assert_eq(
    form.edit_participant("water", "source_paths", "raw/new.md").work_fields.get(
      "work_collective_mode",
    ),
    None,
  )
  let collecting = form.begin("oneoff-read", saved.draft.draft_id)
  let same = collecting.settle(
    collecting.generation,
    "oneoff-read",
    salon_reply(collecting, work),
  )
  assert_eq(same.work_fields, form.work_fields)
  let changed = collecting.settle(
    collecting.generation,
    "oneoff-read",
    salon_reply(collecting, { ..work, result_digest: "sha256:new", }),
  )
  assert_eq(changed.work_fields.get("work_collective_hypothesis"), None)
  guard @collaboration_contract.collective_followup(saved, work, fields)
    is Ok(next) else {
    fail("fixture")
  }
  let reply : @collaboration_contract.Reply = {
    contract_version: "moontown.collaboration.reply.v1",
    request_id: pending.generation.to_string(),
    action: "oneoff-followup",
    ok: true,
    error: "",
    books: [],
    drafts: [],
    prepared: None,
    work: None,
    outcomes: [],
    outcome: None,
    source_listing: None,
    saved: Some({
      ..saved,
      draft: next,
      revision: "r-next",
      previous_revision: "",
    }),
  }
  let settled = pending.settle(
    pending.generation,
    "oneoff-followup",
    reply.to_json().stringify(),
  )
  assert_eq(settled.draft.draft_id, "combined-pilot")
  assert_eq(settled.revision, "r-next")
  assert_true(settled.work is None)
  assert_true(settled.prepared is None)
  assert_false(settled.dirty)
  assert_eq(settled.work_fields.get("work_collective_hypothesis"), None)
  assert_eq(settled.work_fields.get("work_rationale"), None)
  assert_eq(settled.work_fields.get("work_outcome_summary"), None)
  assert_true(settled.notice.contains("No work has run"))
  assert_eq(
    pending
    .dismiss()
    .settle(pending.generation, "oneoff-followup", reply.to_json().stringify()).draft,
    saved.draft,
  )
}

///|
test "collective source picker invalidates notes without silently preserving another input set" {
  let (saved, work, _) = collective_fixture()
  let initial : @collaboration_contract.Client = {
    ..@collaboration_contract.Client::new(),
    draft: saved.draft,
    revision: saved.revision,
    sources: saved.sources,
    work: Some(work),
    dirty: false,
    source_book: "water",
    source_listing: Some({
      book_id: "water",
      paths: ["raw/notes.md", "raw/new.md"],
      scanned_entries: 2,
      excluded_entries: 0,
      unreadable_entries: 0,
      truncated: false,
      detail: "fixture",
    }),
  }
  let changed = initial
    .edit("work_collective_mode", "compose")
    .edit("work_collective_hypothesis", "Old inputs")
    .toggle_source("raw/new.md")
  assert_true(changed.dirty)
  assert_true(changed.work is None)
  assert_eq(changed.work_fields.get("work_collective_hypothesis"), None)
  assert_true(changed.draft.participants[0].source_paths.contains("raw/new.md"))
}
