///|
test "executable book event contract keeps stable json shape" {
  let event = ExecutableBookEvent::new(
    id="book-event-research-tools-EV-tool",
    book_id="research-tools",
    result_id="result-code-tool",
    run_id=Some("run-1"),
    summary="Accepted a book-owned miniapp implementation.",
    artifacts=["tools/summarize/main.mbt", "wiki/reviews/approved.md"],
    notify_town=true,
    evidence_id=Some("EV-tool"),
  )
  assert_eq(event.protocol, "moonbook.executable_event.v1")
  assert_true(event.should_notify_town())
  let text = event.to_json().stringify()
  for field in executable_book_event_core_fields() {
    assert_true(text.contains("\"\{field}\""))
  }
  assert_true(text.contains("\"run_id\":\"run-1\""))
  assert_true(text.contains("\"evidence_id\":\"EV-tool\""))
  assert_true(!text.contains("\"review_path\""))
  assert_true(executable_book_event_optional_fields().contains("review_path"))
  assert_true(
    executable_book_event_optional_fields().contains("lifecycle_proof"),
  )
}

///|
test "executable book event projects to town event without ui coupling" {
  let event = ExecutableBookEvent::new(
    id="book-event-research-tools-EV-review",
    book_id="research-tools",
    result_id="result-review",
    summary="Needs Bookkeeper review.",
    event_type="review_required",
    accepted=false,
    requires_review=true,
    evidence_id=Some("EV-review"),
    review_path=Some("wiki/reviews/pending.md"),
  )
  let town_event = event.to_town_event(3, proposal_id=Some("proposal-1"))
  assert_eq(town_event.kind, "book.review_required")
  assert_true(town_event.related_book_id is Some("research-tools"))
  assert_true(town_event.related_task_id is Some("result-review"))
  assert_true(town_event.related_proposal_id is Some("proposal-1"))
  assert_true(town_event.detail.contains("evidence=EV-review"))
  assert_true(town_event.detail.contains("lifecycle=unknown"))
}

///|
test "blocked executable lifecycle routes as town signal" {
  let proof : ExecutableBookLifecycleProof = {
    contract_id: "mooncode-executable-book-lifecycle.v1",
    owner: "moonclaw",
    session_id: "mooncode-session",
    book_root: "/tmp/research-tools",
    ready: false,
    status: "blocked",
    completed_step_count: 7,
    step_count: 9,
    blocked_step_count: 2,
    first_blocker_id: "package_output",
    first_blocker_label: "Package output",
    first_blocker_evidence: "package results 0, package events 0",
  }
  let event = ExecutableBookEvent::new(
    id="book-event-research-tools-EV-blocked",
    book_id="research-tools",
    result_id="result-blocked",
    summary="Runtime generated code but packaging did not finish.",
    event_type="result",
    accepted=false,
    requires_review=false,
    notify_town=false,
    lifecycle_proof=Some(proof),
  )
  assert_true(event.should_notify_town())
  assert_eq(event.town_event_kind(), "book.lifecycle_blocked")
  assert_eq(event.route_reason(), "lifecycle_blocked")
  let route = event.route_to_town(9)
  assert_true(route.notify_operator)
  assert_true(!route.lifecycle_ready)
  assert_eq(route.lifecycle_status, "blocked")
  assert_eq(route.first_blocker_id, "package_output")
  assert_eq(route.town_event.kind, "book.lifecycle_blocked")
  assert_true(route.town_event.detail.contains("blocker=package_output"))
}

///|
test "complete executable lifecycle keeps accepted knowledge route" {
  let proof : ExecutableBookLifecycleProof = {
    contract_id: "mooncode-executable-book-lifecycle.v1",
    owner: "moonclaw",
    session_id: "mooncode-session",
    book_root: "/tmp/research-tools",
    ready: true,
    status: "complete",
    completed_step_count: 9,
    step_count: 9,
    blocked_step_count: 0,
    first_blocker_id: "",
    first_blocker_label: "",
    first_blocker_evidence: "",
  }
  let event = ExecutableBookEvent::new(
    id="book-event-research-tools-EV-accepted",
    book_id="research-tools",
    result_id="result-accepted",
    summary="Accepted executable artifact.",
    accepted=true,
    notify_town=false,
    lifecycle_proof=Some(proof),
  )
  let route = event.route_to_town(10)
  assert_eq(route.town_event.kind, "book.knowledge_accepted")
  assert_eq(route.lifecycle_status, "complete")
  assert_true(route.lifecycle_ready)
  assert_eq(route.route_reason, "knowledge_accepted")
  assert_true(route.town_event.detail.contains("lifecycle=complete"))
}
