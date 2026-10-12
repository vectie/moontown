///|
test "retained outcome rendered library has distinct plan dossier history and failure controls" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let entry : @collaboration.OutcomeEntry = {
    draft_id: "historic",
    revision: "r-first",
    title: "Retained river result",
    recorded_at: "2026-10-07",
    outcome_status: "partial",
    review_status: "deferred",
    review_version: 2,
    result_digest: "sha256:result",
    review_digest: "sha256:review",
    error: "",
  }
  let work = {
    ..@collaboration.empty_work(entry.draft_id, entry.revision),
    status: "partial",
    result_digest: entry.result_digest,
    review_version: 2,
    review_history_text: "Review 1: reject\nReview 2: defer",
    participants: [
      {
        book_id: "water",
        packet_id: "p",
        proposal_id: "proposal",
        run_id: "run",
        status: "completed",
        detail: "Observed source",
        output_ref: "report.md",
        output_digest: "sha256:output",
        output_text: "水 café <unsafe>",
      },
      {
        book_id: "mobility",
        packet_id: "p2",
        proposal_id: "proposal2",
        run_id: "run2",
        status: "failed",
        detail: "Attributed retained failure",
        output_ref: "",
        output_digest: "",
        output_text: "",
      },
    ],
  }
  let outcome : @collaboration.RetainedOutcome = {
    contract_version: "moontown.retained-outcome.v1",
    key: entry.key(),
    saved: {
      contract_version: "moontown.collaboration-draft.v1",
      draft: {
        ..@collaboration.empty_draft("historic"),
        title: entry.title,
        question: "Which observations?",
        objection: "Different periods",
      },
      revision: entry.revision,
      previous_revision: "",
      recorded_at: entry.recorded_at,
      sources: [],
    },
    work,
    review_status: "deferred",
    reviews: [
      { version: 0, digest: "sha256:zero", },
      { version: 2, digest: entry.review_digest, },
    ],
    artifacts: [],
    archive_digest: "sha256:archive",
    archive_size_bytes: 4096,
  }
  let state = {
    ..collaboration_test_state(),
    outcomes: [entry],
    outcome_key: Some(entry.key()),
    outcome: Some(outcome),
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_collaboration_outcomes(dispatch, state)),
  )
  for
    expected in [
      "Retained outcome library", "Load / reload retained outcomes", "Cancel pending inspection or download",
      "Filter outcome", "Filter review", "Inspect review 0", "Inspect review 2",
      "partial", "deferred", "Attributed retained failure", "水 café &lt;unsafe&gt;",
      "Download exact retained dossier (.tar)", "sha256:archive", "Different periods",
      "download never submits to Book",
    ] {
    assert_true(html.contains(expected), msg=expected)
  }
  assert_false(html.contains("Run participants once"))
  assert_false(html.contains("Send retained outcome to chosen Book"))
  let payload = @json.parse(
    collaboration_payload(state, "outcome-export", "historic", "r-first", ""),
  )
  assert_eq(
    payload,
    (
      {
        "contract_version": "moontown.collaboration.request.v1",
        "request_id": state.generation.to_string(),
        "action": "outcome-export",
        "draft_id": "historic",
        "revision": "r-first",
        "new_draft_id": "",
        "artifact_path": "",
        "payload": entry.key().to_json(),
        "draft": Json::null(),
      } : Json),
  )
}
