///|
async test "oneoff completed production participant result crosses real Book intake and exact readback" {
  guard @env.get_env_var("MOONTOWN_BOOK_OUTCOME_BIN") is Some(_) else {
    fail(
      "This crossing requires the real built MoonBook cmd/outcome_lessons executable",
    )
  }
  let (store, root, runtime) = oneoff_fixture()
  @fs.mkdir(root + "/books/destination")
  let catalog = @moonbook.load_catalog_file(store.catalog_path).unwrap()
  catalog.push(
    @moonbook.BookCatalogEntry::new(
      id="destination",
      name="Destination fixture Book",
      purpose="local fixture receiver",
      workspace_root=root + "/books/destination",
    ),
  )
  @fs.write_file(store.catalog_path, catalog.to_json().stringify())
  let saved = store.save(fixture_draft(), "", "2026-10-07T03:00:00Z")
  ignore(store.prepare(saved.draft.draft_id, saved.revision))
  let work = store.start_oneoff(saved.draft.draft_id, saved.revision, runtime)
  assert_eq(work.status, "completed")
  let review = store.decide_oneoff(
    saved.draft.draft_id,
    saved.revision,
    Some("alex"),
    decision_payload(work, "review-result", "approve"),
    "2026-10-07T03:01:00Z",
  )
  let accepted = store.decide_oneoff(
    saved.draft.draft_id,
    saved.revision,
    Some("sam"),
    decision_payload(review, "resolve-objection", "approve"),
    "2026-10-07T03:02:00Z",
  )
  let fields : Json = {
    "result_digest": accepted.result_digest,
    "review_version": accepted.review_version,
    "book_id": "destination",
    "salon_mode": "compare",
    "salon_result_digest": accepted.result_digest,
    "salon_selected_book": "water",
    "salon_basis": "Which fixture contribution supplies a bounded comparison?",
    "salon_assessment_water": "Water fixture returns its captured evidence.",
    "salon_assessment_mobility": "Mobility fixture supplies the alternative perspective.",
    "salon_rationale": "Choose water to rehearse the Book routing contract.",
    "salon_alternatives": "Keep mobility as the alternative; no quality ranking is claimed.",
    "salon_dissent": "The original observed-period objection remains in evidence.",
    "salon_assumptions": "Real provider quality and human acceptance remain unqualified.",
    "outcome_summary": "Synthetic local one-off output demonstrates source retention and protocol crossing only. It does not establish real provider quality or human acceptance.",
    "information_severity": "0",
    "information_summary": "No information gap is claimed in this bounded transport-only fixture.",
    "recognition_severity": "0",
    "recognition_summary": "No recognition finding is claimed by this transport-only fixture.",
    "decisiveness_severity": "0",
    "decisiveness_summary": "No operational decisiveness finding is claimed in this synthetic fixture.",
  }
  let submitted = store.submit_oneoff(
    saved.draft.draft_id,
    saved.revision,
    fields,
    1791330000,
  )
  assert_eq(submitted.book_status, "deliverable_review_required")
  assert_false(submitted.package_digest.is_empty())
  let repeated = store.submit_oneoff(
    saved.draft.draft_id,
    saved.revision,
    fields,
    1791339999,
  )
  assert_eq(repeated.package_digest, submitted.package_digest)
  assert_eq(repeated.book_status, "deliverable_review_required")
  let reopened = store.refresh_oneoff_book(saved.draft.draft_id, saved.revision)
  assert_eq(reopened.result_digest, work.result_digest)
  assert_eq(reopened.package_digest, submitted.package_digest)
  assert_eq(reopened.participants, work.participants)
  assert_eq(reopened.book_status, "deliverable_review_required")
  let outcome_root = store.work_root(saved) +
    "/outcomes/" +
    submitted.package_digest[7:].to_owned()
  let package = @json.parse(
    text_bytes(read_bytes(outcome_root + "/package.json", 16777216)),
  )
  guard package is { "payload_json": String(payload), .. } else {
    fail("Expected actual outcome package")
  }
  guard @json.parse(payload) is { "artifacts": Array(artifacts), .. } else {
    fail("Expected actual retained evidence")
  }
  assert_eq(artifacts.length(), 4)
  guard artifacts[3] is { "text": String(statement_text), .. } else {
    fail("Expected interpretation")
  }
  assert_true(
    @json.parse(statement_text)
    is {
      "salon_selection": {
        "selected_book_id": "water",
        "genuine_emergence_verified": False,
        "comparisons": Array(comparisons),
        ..
      },
      ..
    } &&
    comparisons.length() == 2,
  )
  assert_true(
    @json.parse(payload)
    is { "submission": { "outcome_summary": String(summary), .. }, .. } &&
    summary.has_prefix("Idea salon selected water for independent Book review."),
  )
  assert_true(payload.contains("bytes_hex"))
  assert_true(payload.contains("Deterministic local fixture output"))
  assert_true(
    try {
      ignore(
        checked_work_readback(package, {
          "contract_version": "moonbook.product-outcome-readback.v1",
          "package_digest": "wrong",
        }),
      )
      false
    } catch {
      _ => true
    },
  )
  if @env.get_env_var("MOONTOWN_ONEOFF_EVIDENCE") is Some(path) {
    directory(path, true)
    write_bytes(path + "/book-root.txt", @utf8.encode(root))
    write_bytes(
      path + "/book-work.json",
      @utf8.encode(reopened.to_json().stringify(indent=2)),
    )
    write_bytes(
      path + "/town-outcome-package.json",
      @utf8.encode(package.stringify(indent=2)),
    )
  }
}
