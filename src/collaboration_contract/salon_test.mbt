///|
fn salon_fixture() -> (
  @collaboration_contract.SavedDraft,
  @collaboration_contract.OneoffWork,
  Json,
) {
  let saved : @collaboration_contract.SavedDraft = {
    contract_version: "moontown.collaboration.saved.v1",
    draft: {
      ..@collaboration_contract.empty_draft("salon"),
      question: "Which pilot should we try?",
      objection: "Do the cohorts match?",
    },
    revision: "r-one",
    previous_revision: "",
    recorded_at: "2026-10-12T09:00:00Z",
    sources: ["water", "mobility"].map(id => {
      book_id: id,
      book_title: id,
      source_path: "raw/notes.md",
      artifact_ref: "sources/" + id,
      digest: "sha256:source-" + id,
      size_bytes: 10,
    }),
  }
  let contributions : Array[@collaboration_contract.ParticipantWork] = [
    "water", "mobility",
  ].map(id => {
    book_id: id,
    packet_id: "packet-" + id,
    proposal_id: "proposal-" + id,
    run_id: "run-" + id,
    status: "completed",
    detail: "fixture rehearsal",
    output_ref: "outputs/" + id,
    output_digest: "sha256:output-" + id,
    output_text: "Deterministic local fixture output: " + id,
  })
  contributions.push({
    ..contributions[0],
    book_id: "missing",
    status: "failed",
    output_text: "",
    output_ref: "",
    output_digest: "",
  })
  let work = {
    ..@collaboration_contract.empty_work("salon", "r-one"),
    status: "partial",
    result_digest: "sha256:result",
    participants: contributions,
  }
  let fields : Json = {
    "salon_mode": "compare",
    "salon_result_digest": work.result_digest,
    "salon_selected_book": "water",
    "salon_basis": "Testability with current evidence",
    "salon_assessment_water": "Water suggests a bounded pilot with cited observations.",
    "salon_assessment_mobility": "Mobility needs another cohort before its larger pilot.",
    "salon_rationale": "Try the smaller pilot first.",
    "salon_alternatives": "Keep mobility's larger pilot as an alternative.",
    "salon_dissent": "The original cohort objection remains unresolved.",
    "salon_assumptions": "Recruitment feasibility needs checking.",
    "output_digest": "browser-forgery-must-not-bind",
  }
  (saved, work, fields)
}

///|
fn change_salon_field(fields : Json, key : String, value : Json) -> Json {
  guard fields is Object(values) else { abort("fixture") }
  let changed = values.copy()
  changed[key] = value
  Json::object(changed)
}

///|
test "salon selection compares every retained contribution and preserves dissent without claiming emergence" {
  let (saved, work, fields) = salon_fixture()
  guard @collaboration_contract.salon_selection(saved, work, fields)
    is Ok(Some(selection)) else {
    fail("Expected selection")
  }
  guard selection
    is {
      "selected_book_id": "water",
      "genuine_emergence_verified": False,
      "comparisons": Array(comparisons),
      "failed_book_ids": ["missing"],
      "dissent": "The original cohort objection remains unresolved.",
      "authored_objection": "Do the cohorts match?",
      ..
    } else {
    fail("Expected bounded comparison")
  }
  assert_eq(comparisons.length(), 2)
  assert_true(
    comparisons[0]
    is {
      "book_id": "water",
      "selected": True,
      "run_id": "run-water",
      "output_digest": "sha256:output-water",
      "source_snapshots": Array(_),
      ..
    },
  )
  assert_true(
    comparisons[1] is { "book_id": "mobility", "selected": False, .. },
  )
  assert_false(selection.stringify().contains("browser-forgery"))
  assert_eq(
    @collaboration_contract.salon_selection(saved, work, fields),
    Ok(Some(selection)),
  )
}

///|
test "salon rejects stale selection missing comparison and erased dissent" {
  let (saved, work, fields) = salon_fixture()
  for
    (key, value) in [
      ("salon_result_digest", "sha256:old"),
      ("salon_selected_book", "missing"),
      ("salon_selected_book", "unknown"),
      ("salon_assessment_mobility", ""),
      ("salon_dissent", "  "),
      ("salon_alternatives", ""),
      ("salon_assumptions", ""),
      ("salon_basis", ""),
      ("salon_mode", "autonomous"),
    ] {
    assert_true(
      @collaboration_contract.salon_selection(
        saved,
        work,
        change_salon_field(fields, key, value.to_json()),
      )
      is Err(_),
    )
  }
  assert_true(
    @collaboration_contract.salon_selection(
      saved,
      { ..work, revision: "other", },
      fields,
    )
    is Err(_),
  )
  assert_true(
    @collaboration_contract.salon_selection(
      { ..saved, sources: [], },
      work,
      fields,
    )
    is Err(_),
  )
  assert_true(
    @collaboration_contract.salon_selection(
      saved,
      { ..work, status: "running", },
      fields,
    )
    is Err(_),
  )
  assert_true(
    @collaboration_contract.salon_selection(
      saved,
      { ..work, participants: [work.participants[0]], },
      fields,
    )
    is Err(_),
  )
  assert_true(
    @collaboration_contract.salon_selection(
      saved,
      { ..work, participants: [work.participants[0], work.participants[0]], },
      fields,
    )
    is Err(_),
  )
  assert_false(
    @collaboration_contract.salon_ready({
      ..work,
      participants: [
        ..work.participants,
        { ..work.participants[0], book_id: "corrupt", output_digest: "", },
      ],
    }),
  )
  assert_eq(
    @collaboration_contract.salon_selection(saved, work, Json::null()),
    Ok(None),
  )
  assert_eq(
    @collaboration_contract.salon_selection(
      saved,
      work,
      change_salon_field(fields, "salon_mode", "off"),
    ),
    Ok(None),
  )
}

///|
fn salon_reply(
  client : @collaboration_contract.Client,
  work : @collaboration_contract.OneoffWork,
) -> String {
  let reply : @collaboration_contract.Reply = {
    contract_version: "moontown.collaboration.reply.v1",
    request_id: client.generation.to_string(),
    action: "oneoff-read",
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
  reply.to_json().stringify()
}

///|
test "salon worksheet survives interrupted collection and clears when result question or source changes" {
  let (saved, work, _) = salon_fixture()
  let state : @collaboration_contract.Client = {
    ..@collaboration_contract.Client::new(),
    draft: saved.draft,
    revision: saved.revision,
    work: Some(work),
    dirty: false,
  }
  let form = state
    .edit("work_salon_mode", "compare")
    .edit("work_salon_selected_book", "water")
    .edit("work_salon_dissent", "Preserve cohort objection")
    .edit("work_outcome_summary", "Independent interpretation")
  assert_eq(
    form.work_fields.get("work_salon_result_digest"),
    Some(work.result_digest),
  )
  assert_eq(
    form.edit("work_salon_mode", "compare").work_fields,
    form.work_fields,
  )
  let pending = form.begin("oneoff-read", saved.draft.draft_id)
  assert_eq(
    pending.edit("work_salon_mode", "off").work_fields,
    form.work_fields,
  )
  let interrupted = pending.settle(
    pending.generation,
    "oneoff-read",
    "interrupted",
  )
  assert_eq(interrupted.work_fields, form.work_fields)
  let same = pending.settle(
    pending.generation,
    "oneoff-read",
    salon_reply(pending, work),
  )
  assert_eq(same.work_fields, form.work_fields)
  let changed = pending.settle(
    pending.generation,
    "oneoff-read",
    salon_reply(pending, { ..work, result_digest: "sha256:new", }),
  )
  assert_eq(changed.work_fields.get("work_salon_selected_book"), None)
  assert_eq(
    changed.work_fields.get("work_outcome_summary"),
    Some("Independent interpretation"),
  )
  let edited = form.edit("question", "Different question")
  assert_eq(edited.work_fields.get("work_salon_mode"), None)
  let edited_source = form.edit_participant(
    "water", "source_paths", "raw/new.md",
  )
  assert_eq(edited_source.work_fields.get("work_salon_mode"), None)
  let discarded = form.edit("work_salon_mode", "off")
  assert_eq(discarded.work_fields.get("work_salon_dissent"), None)
  assert_eq(
    discarded.work_fields.get("work_outcome_summary"),
    Some("Independent interpretation"),
  )
  assert_eq(
    pending
    .dismiss()
    .settle(pending.generation, "oneoff-read", salon_reply(pending, work)).work_fields,
    form.work_fields,
  )
}
