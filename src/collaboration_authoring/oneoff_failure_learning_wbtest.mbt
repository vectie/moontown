///|
async test "oneoff actual partial-failure account crosses Book without implying successful collaboration" {
  guard @env.get_env_var("MOONTOWN_BOOK_OUTCOME_BIN") is Some(_) else {
    fail("Real local Book receiver required")
  }
  let (store, root, runtime) = oneoff_fixture()
  @fs.write_file(
    root + "/books/mobility/raw/nested/source.bin",
    "FAIL_PARTICIPANT_FIXTURE",
  )
  @fs.mkdir(root + "/books/destination")
  let catalog = @moonbook.load_catalog_file(store.catalog_path).unwrap()
  catalog.push(
    @moonbook.BookCatalogEntry::new(
      id="destination",
      name="Failure learning fixture Book",
      purpose="Retain accurate failure account",
      workspace_root=root + "/books/destination",
    ),
  )
  @fs.write_file(store.catalog_path, catalog.to_json().stringify())
  let saved = store.save(fixture_draft(), "", "2026-10-07T06:00:00Z")
  ignore(store.prepare(saved.draft.draft_id, saved.revision))
  let partial = store.start_oneoff(
    saved.draft.draft_id,
    saved.revision,
    runtime,
  )
  assert_eq(partial.status, "partial")
  assert_true(
    @json.parse(partial.result_text)
    is {
      "all_participants_succeeded": False,
      "successful_participants": 1,
      "failed_participants": 1,
      ..
    },
  )
  fn fields(work : @contract.OneoffWork) -> Json {
    {
      "result_digest": work.result_digest,
      "review_version": work.review_version,
      "book_id": "destination",
      "outcome_summary": "Synthetic local failure account: water returned evidence, mobility failed. This is not a successful collaboration claim.",
      "information_severity": "0",
      "information_summary": "No domain finding is inferred from this transport-only failure fixture.",
      "recognition_severity": "0",
      "recognition_summary": "No recognition improvement is claimed by the synthetic fixture.",
      "decisiveness_severity": "0",
      "decisiveness_summary": "No operational improvement is claimed; the participant failure remains explicit.",
    }
  }
  assert_true(
    try {
      ignore(
        store.submit_oneoff(
          saved.draft.draft_id,
          saved.revision,
          fields(partial),
          1791330000,
        ),
      )
      false
    } catch {
      _ => true
    },
  )
  let rejected = store.decide_oneoff(
    saved.draft.draft_id,
    saved.revision,
    Some("alex"),
    decision_payload(partial, "review-result", "reject"),
    "2026-10-07T06:01:00Z",
  )
  assert_true(
    try {
      ignore(
        store.submit_oneoff(
          saved.draft.draft_id,
          saved.revision,
          fields(rejected),
          1791330000,
        ),
      )
      false
    } catch {
      _ => true
    },
  )
  let reviewed = store.decide_oneoff(
    saved.draft.draft_id,
    saved.revision,
    Some("alex"),
    decision_payload(rejected, "review-result", "approve"),
    "2026-10-07T06:02:00Z",
  )
  let accepted = store.decide_oneoff(
    saved.draft.draft_id,
    saved.revision,
    Some("sam"),
    decision_payload(reviewed, "resolve-objection", "approve"),
    "2026-10-07T06:03:00Z",
  )
  let sent = store.submit_oneoff(
    saved.draft.draft_id,
    saved.revision,
    fields(accepted),
    1791330000,
  )
  assert_eq(sent.status, "partial")
  assert_eq(sent.book_status, "deliverable_review_required")
  let returned = store.refresh_oneoff_book(saved.draft.draft_id, saved.revision)
  assert_eq(returned.result_text, partial.result_text)
  assert_eq(returned.participants[1].status, "failed")
  assert_eq(returned.book_status, "deliverable_review_required")
  let path = store.work_root(saved) +
    "/outcomes/" +
    sent.package_digest[7:].to_owned() +
    "/package.json"
  let package_text = text_bytes(read_bytes(path, 16777216))
  guard @json.parse(package_text) is { "payload_json": String(payload), .. } &&
    @json.parse(payload)
    is { "submission": { "deliverable_summary": String(summary), .. }, .. } else {
    fail("Expected actual Book package")
  }
  assert_true(summary.contains("1 participant(s) succeeded, 1 failed"))
  assert_true(summary.contains("not a claim of successful collaboration"))
  if @env.get_env_var("MOONTOWN_ONEOFF_EVIDENCE") is Some(out) {
    directory(out, true)
    write_bytes(out + "/failure-learning-root.txt", @utf8.encode(root))
    write_bytes(
      out + "/failure-learning-package.json",
      @utf8.encode(package_text),
    )
    write_bytes(
      out + "/failure-learning-return.json",
      @utf8.encode(returned.to_json().stringify(indent=2)),
    )
  }
}
