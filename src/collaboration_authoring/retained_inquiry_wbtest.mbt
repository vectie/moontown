///|
fn retained_inquiry_input(
  outcome : @contract.RetainedOutcome,
  ids : Array[String],
) -> @contract.RetainedInquiry {
  {
    origin: outcome.key,
    draft_id: "research-next",
    title: "Revisit the observation contexts",
    question: "Which retained findings still hold against the new observations?",
    falsifier: "A newly captured observation contradicts the historical account.",
    dissent: "The observation periods may remain incomparable.",
    assumptions: "Dates and collection methods need checking.",
    reviewer_id: "lee",
    reviewer_name: "Lee Reviewer",
    objection_reviewer_id: "ren",
    objection_reviewer_name: "Ren Reviewer",
    contributions: ids.map(book_id => {
      book_id,
      quote: "Exact contribution 水 café 🚲",
      challenge: "Independently check dates and methods for " + book_id,
    }),
  }
}

///|
fn retained_inquiry_request(input : @contract.RetainedInquiry) -> Request {
  {
    contract_version: "moontown.collaboration.request.v1",
    request_id: "inquiry-native",
    action: "retained-inquiry",
    draft_id: input.draft_id,
    revision: "",
    new_draft_id: "",
    artifact_path: "",
    draft: None,
    payload: Some(input.to_json()),
  }
}

///|
async test "retained inquiry saves a historical subset with named failures then edits reopens prepares and exports" {
  let (store, root) = fixture()
  let catalog = @moonbook.load_catalog_file(store.catalog_path).unwrap()
  for id in ["forest", "energy"] {
    let workspace = root + "/books/" + id
    @fs.mkdir(workspace + "/raw/nested", recursive=true)
    @fs.write_file(
      workspace + "/raw/nested/source.bin",
      "Historical " + id,
      create_mode=CreateNew,
    )
    catalog.push(
      @moonbook.BookCatalogEntry::new(
        id~,
        name=id,
        purpose="fixture",
        workspace_root=workspace,
      ),
    )
  }
  @fs.write_file(store.catalog_path, catalog.to_json().stringify())
  let original_draft = fixture_draft()
  let original = store.save(
    {
      ..original_draft,
      participants: original_draft.participants +
      ["forest", "energy"].map(book_id => {
        ..original_draft.participants[0],
        book_id,
        focus_area: book_id,
      }),
    },
    "",
    "2026-10-14T05:00:00Z",
  )
  ignore(retain_outcome_fixture(store, original, true))
  let entry = store.list_outcomes().filter(e => e.revision == original.revision)[0]
  let outcome = store.inspect_outcome(entry.key())
  ignore(
    outcome_fixture_decision(
      store,
      original,
      outcome.work,
      result_bundle(original, outcome.work),
      1,
      "review-result",
      "reject",
    ),
  )
  assert_eq(store.list_outcomes()[0].review_version, 1)
  assert_eq(store.inspect_outcome(outcome.key).review_status, "pending_review")
  let historical = outcome_tree(
    store.draft_root(original.draft.draft_id) +
    "/revisions/" +
    original.revision,
  )
  // New live source bytes and a newer draft pointer do not replace the explicit historical selection.
  @fs.write_file(
    root + "/books/water/raw/nested/source.bin",
    "Current water observations",
  )
  ignore(
    store.save(
      { ..original.draft, question: "A newer ordinary question", },
      original.revision,
      "2026-10-14T05:01:00Z",
    ),
  )
  let input = retained_inquiry_input(outcome, ["water", "forest"])
  let request = retained_inquiry_request(input)
  let reply = store.request(request, "2026-10-14T05:02:00Z")
  assert_true(reply.ok, msg=reply.error)
  let saved = reply.saved.unwrap()
  assert_eq(saved.previous_revision, "")
  assert_eq(saved.draft.participants.map(p => p.book_id), ["water", "forest"])
  assert_true(saved.draft.question.contains("mobility"))
  assert_true(saved.draft.question.contains("energy"))
  assert_true(saved.draft.question.contains("Attributed fixture failure"))
  assert_true(saved.draft.question.contains(original.sources[0].digest))
  assert_true(saved.sources[0].digest != original.sources[0].digest)
  assert_eq(store.request(request, "2026-10-14T05:03:00Z").saved, Some(saved))
  assert_false(@fs.exists(store.work_root(saved)))
  assert_eq(store.load(input.draft_id), saved)
  let edited = store.save(
    { ..saved.draft, title: "Edited retained research inquiry", },
    saved.revision,
    "2026-10-14T05:04:00Z",
  )
  assert_eq(store.load(input.draft_id), edited)
  let prepared = store.prepare(input.draft_id, edited.revision)
  assert_eq(prepared.review_status, "pending_review")
  let brief = text_bytes(
    store.artifact(
      input.draft_id,
      edited.revision,
      revision_prefix(edited) + "briefs/water.md",
    ),
  )
  assert_true(brief.contains("Independently check dates and methods for water"))
  assert_true(brief.contains("moontown.retained-inquiry.v1"))
  let handoff = text_bytes(
    store.artifact(
      input.draft_id,
      edited.revision,
      revision_prefix(edited) + "handoff.json",
    ),
  )
  assert_true(handoff.contains("named-human"))
  assert_eq(
    store.read_oneoff(input.draft_id, edited.revision).status,
    "not_started",
  )
  assert_eq(
    outcome_tree(
      store.draft_root(original.draft.draft_id) +
      "/revisions/" +
      original.revision,
    ),
    historical,
  )
  assert_false(@fs.exists(root + "/books/water/review"))
  assert_false(@fs.exists(store.root + "/schedules"))
  if @env.get_env_var("MOONTOWN_RETAINED_INQUIRY_EVIDENCE") is Some(path) {
    directory(path, true)
    write_bytes(
      path + "/input.json",
      @utf8.encode(input.to_json().stringify(indent=2)),
    )
    write_bytes(
      path + "/request.json",
      @utf8.encode(request.to_json().stringify(indent=2)),
    )
    write_bytes(
      path + "/origin.json",
      @utf8.encode(outcome.to_json().stringify(indent=2)),
    )
    write_bytes(
      path + "/saved.json",
      @utf8.encode(saved.to_json().stringify(indent=2)),
    )
    write_bytes(
      path + "/edited.json",
      @utf8.encode(edited.to_json().stringify(indent=2)),
    )
    write_bytes(
      path + "/prepared.json",
      @utf8.encode(prepared.to_json().stringify(indent=2)),
    )
    write_bytes(
      path + "/inquiry.tar",
      store.export_tar(input.draft_id, edited.revision),
    )
    write_bytes(path + "/store-root.txt", @utf8.encode(store.root + "\n"))
  }
}

///|
async test "retained inquiry rejects changed evidence current sources identity collisions and untrusted payload fields" {
  let (store, root) = fixture()
  let original = store.save(fixture_draft(), "", "2026-10-14T05:00:00Z")
  ignore(retain_outcome_fixture(store, original, false))
  let outcome = store.inspect_outcome(store.list_outcomes()[0].key())
  let input = retained_inquiry_input(outcome, ["water", "mobility"])
  let request = retained_inquiry_request(input)
  let before = outcome_tree(store.root)
  for
    invalid in [
      { ..request, revision: original.revision, },
      { ..request, draft_id: "different", },
      retained_inquiry_request({
        ..input,
        origin: { ..input.origin, review_digest: "sha256:changed", },
      }),
      retained_inquiry_request({
        ..input,
        contributions: [
          { ..input.contributions[0], quote: "Invented consensus", },
          input.contributions[1],
        ],
      }),
    ] {
    assert_false(store.request(invalid, "2026-10-14T05:01:00Z").ok)
  }
  let fields = match input.to_json() {
    Object(f) => f
    _ => abort("object")
  }
  fields["output_digest"] = "forged".to_json()
  assert_false(
    store.request(
      { ..request, payload: Some(Json::object(fields)), },
      "2026-10-14T05:01:00Z",
    ).ok,
  )
  assert_eq(outcome_tree(store.root), before)
  let saved = store.save_retained_inquiry(input, "2026-10-14T05:02:00Z")
  @fs.write_file(
    root + "/books/water/raw/nested/source.bin",
    "Changed after save",
  )
  assert_false(store.request(request, "2026-10-14T05:03:00Z").ok)
  assert_eq(store.load(input.draft_id), saved)
  @fs.remove(root + "/books/mobility/raw/nested/source.bin")
  assert_false(
    store.request(
      retained_inquiry_request({ ..input, draft_id: "missing-current", }),
      "2026-10-14T05:03:00Z",
    ).ok,
  )
  assert_eq(store.current_revision("missing-current"), "")
  @fs.write_file(
    store.work_root(original) + "/produced/water/report.md",
    "Tampered retained output",
  )
  assert_false(
    store.request(
      retained_inquiry_request({ ..input, draft_id: "tampered-origin", }),
      "2026-10-14T05:04:00Z",
    ).ok,
  )
  assert_eq(store.current_revision("tampered-origin"), "")
}
