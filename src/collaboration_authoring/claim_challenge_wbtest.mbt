///|
async fn claim_challenge_fixture() -> (
  Store,
  String,
  @contract.ClaimChallenge,
  String,
) {
  let (store, root) = fixture()
  let table = "claim_id,book_id,topic,context,value,source_path,quote\na,Imported Water,wait,week A,12,export/water.txt,Wait: 12\nb,Imported Travel,wait,week A,18,export/travel.txt,Wait: 18\nc,Imported Water,wait,week B,12,export/water.txt,Wait: 12\n"
  @fs.write_file(root + "/books/water/raw/nested/source.bin", "Wait: 12\n")
  @fs.write_file(root + "/books/mobility/raw/nested/source.bin", "Wait: 18\n")
  let comparison = match
    @claims.report(
      @utf8.encode(table),
      ',',
      { "export/water.txt": b"Wait: 12\n", "export/travel.txt": b"Wait: 18\n" },
      format="json",
    ) {
    Ok(value) => value
    Err(error) => fail(error)
  }
  let input : @contract.ClaimChallenge = {
    comparison,
    group_index: 0,
    draft_id: "source-challenge",
    title: "Check the waiting-time difference",
    question: "Could sampling account for the reported difference?",
    falsifier: "The difference remains after matching the sampled cohorts.",
    reviewer_id: "alex",
    reviewer_name: "Alex",
    objection: "The samples may not describe the same population.",
    objection_reviewer_id: "sam",
    objection_reviewer_name: "Sam",
    mappings: [
      {
        claim_id: "a",
        book_id: "water",
        source_path: "raw/nested/source.bin",
        challenge: "Find a sampling difference that could explain the observation.",
      },
      {
        claim_id: "b",
        book_id: "mobility",
        source_path: "raw/nested/source.bin",
        challenge: "Independently test a transport-delay explanation.",
      },
    ],
  }
  (store, root, input, table)
}

///|
async test "source claim challenge actual report maps Books saves reopens and prepares ordinary pending review" {
  let (store, root, input, table) = claim_challenge_fixture()
  let catalog = @fs.read_file(root + "/catalog.json").binary()
  let first = store.save_claim_challenge(input, "2026-10-14T00:00:00Z")
  assert_eq(first.draft.participants.map(p => p.book_id), ["water", "mobility"])
  assert_true(first.draft.question.contains("Imported Water"))
  assert_true(first.draft.question.contains("Wait: 18"))
  assert_true(first.draft.question.contains("not semantic contradictions"))
  assert_false(first.draft.question.contains("week B"))
  assert_eq(store.save_claim_challenge(input, "later retry"), first)
  assert_eq(store.load(input.draft_id), first)
  assert_eq(store.list(), [first])
  let prepared = store.prepare(input.draft_id, first.revision)
  assert_eq(prepared.review_status, "pending_review")
  let prefix = revision_prefix(first)
  let handoff : @civic.CivicCommunicationScenarioHandoff = @json.from_json(
    @json.parse(
      @utf8.decode(
        store.artifact(input.draft_id, first.revision, prefix + "handoff.json"),
      ),
    ),
  )
  assert_eq(handoff.scenario.ideas.length(), 0)
  assert_eq(handoff.scenario.participants.length(), 2)
  let bundle = @review.reimport_review_bundle(
    @utf8.decode(
      store.artifact(
        input.draft_id,
        first.revision,
        prefix + "review-bundle.json",
      ),
    ),
    store.artifact(
      input.draft_id,
      first.revision,
      prefix + "source-packet.json",
    ),
  )
  assert_true(bundle.decision_receipts.is_empty())
  assert_eq(bundle.required_decisions.length(), 2)
  assert_eq(
    store.artifact(
      input.draft_id,
      first.revision,
      prefix + "sources/water/raw/nested/source.bin",
    ),
    b"Wait: 12\n",
  )
  assert_eq(@fs.read_file(root + "/catalog.json").binary(), catalog)
  assert_false(@fs.exists(root + "/books/water/review"))
  assert_false(@fs.exists(root + "/state/schedules"))
  assert_false(@fs.exists(store.work_root(first)))
  assert_eq(
    @fs.read_file(root + "/books/water/raw/nested/source.bin").binary(),
    b"Wait: 12\n",
  )
  assert_eq(
    @fs.read_file(root + "/books/mobility/raw/nested/source.bin").binary(),
    b"Wait: 18\n",
  )
  if @env.get_env_var("MOONTOWN_CLAIM_CHALLENGE_FIXTURE_OUTPUT") is Some(output) {
    directory(output, true)
    write_bytes(output + "/claims.csv", @utf8.encode(table))
    write_bytes(output + "/export/water.txt", b"Wait: 12\n")
    write_bytes(output + "/export/travel.txt", b"Wait: 18\n")
    write_bytes(output + "/comparison.json", @utf8.encode(input.comparison))
    write_bytes(
      output + "/challenge-input.json",
      @utf8.encode(input.to_json().stringify(indent=2)),
    )
    write_bytes(
      output + "/saved.json",
      @utf8.encode(first.to_json().stringify(indent=2)),
    )
    write_bytes(
      output + "/prepared.json",
      @utf8.encode(prepared.to_json().stringify(indent=2)),
    )
    write_bytes(
      output + "/challenge.tar",
      store.export_tar(input.draft_id, first.revision),
    )
  }
  @fs.write_file(
    root + "/books/water/raw/nested/source.bin",
    "Live source changed after saving",
  )
  assert_eq(store.load(input.draft_id), first)
  assert_eq(store.prepare(input.draft_id, first.revision), prepared)
  let edited = store.save(
    { ..first.draft, title: "An ordinary edit", },
    first.revision,
    "2026-10-14T00:01:00Z",
  )
  assert_true(edited.revision != first.revision)
  assert_eq(store.load(input.draft_id), edited)
}

///|
async test "source claim challenge stale exact bytes missing quote wrong mapping and unknown Book refuse before revision" {
  let (store, root, input, _) = claim_challenge_fixture()
  @fs.write_file(
    root + "/books/water/raw/nested/source.bin",
    "Wait: 12\nExtra context changed",
  )
  try store.save_claim_challenge(input, "now") catch {
    CollaborationError(error) => assert_true(error.contains("bytes differ"))
    error => raise error
  } noraise {
    _ => fail("Expected stale source refusal")
  }
  assert_false(@fs.exists(store.root + "/drafts/source-challenge/current"))
  @fs.write_file(root + "/books/water/raw/nested/source.bin", "Wait: 12\n")
  let report = @contract.decode_claim_comparison(input.comparison).unwrap()
  let group = report.groups[0]
  let changed = {
    ..report,
    groups: [
      {
        ..group,
        claims: [
          { ..group.claims[0], quote: "invented quote", },
          group.claims[1],
        ],
      },
      report.groups[1],
    ],
  }
  try
    store.save_claim_challenge(
      { ..input, comparison: changed.to_json().stringify(), },
      "now",
    )
  catch {
    CollaborationError(error) => assert_true(error.contains("quote is absent"))
    error => raise error
  } noraise {
    _ => fail("Expected absent quote refusal")
  }
  for
    mapping in [
      { ..input.mappings[0], book_id: "unregistered", },
      { ..input.mappings[0], source_path: "../outside", },
      { ..input.mappings[0], source_path: "raw/missing.txt", },
    ] {
    try
      store.save_claim_challenge(
        { ..input, mappings: [mapping, input.mappings[1]], },
        "now",
      )
    catch {
      _ => ()
    } noraise {
      _ => fail("Expected mapping refusal")
    }
  }
  assert_false(@fs.exists(store.root + "/drafts/source-challenge/current"))
}

///|
async test "source claim challenge API uses new ordinary identity and protects existing edits" {
  let (store, _, input, _) = claim_challenge_fixture()
  let request : Request = {
    contract_version: "moontown.collaboration.request.v1",
    request_id: "1",
    action: "claim-challenge",
    draft_id: input.draft_id,
    revision: "",
    new_draft_id: "",
    artifact_path: "",
    draft: None,
    payload: Some(input.to_json()),
  }
  let reply = store.request(
    decode_request(request.to_json().stringify()),
    "2026-10-14T00:00:00Z",
  )
  assert_true(reply.ok)
  let saved = reply.saved.unwrap()
  let next = store.save(
    { ..saved.draft, title: "Newer ordinary edit", },
    saved.revision,
    "2026-10-14T00:02:00Z",
  )
  assert_false(store.request(request, "later").ok)
  assert_eq(store.load(input.draft_id), next)
  assert_false(store.request({ ..request, draft_id: "other", }, "later").ok)
}
