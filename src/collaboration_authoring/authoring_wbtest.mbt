///|
async fn fixture() -> (Store, String) {
  let root = @fs.realpath(@fs.tmpdir(prefix="town-collaboration-"))
  let catalog : Array[@moonbook.BookCatalogEntry] = []
  for id in ["water", "mobility"] {
    let book = root + "/books/" + id
    @fs.mkdir(book + "/raw/nested", recursive=true)
    @fs.write_file(
      book + "/raw/nested/source.bin",
      b"exact\x00source\xff\n",
      create_mode=CreateNew,
    )
    catalog.push(
      @moonbook.BookCatalogEntry::new(
        id~,
        name=id + " Book",
        purpose="fixture",
        workspace_root=book,
      ),
    )
  }
  @fs.write_file(
    root + "/catalog.json",
    catalog.to_json().stringify(),
    create_mode=CreateNew,
  )
  ({ root: root + "/state", catalog_path: root + "/catalog.json", }, root)
}

///|
fn fixture_draft() -> @contract.Draft {
  {
    draft_id: "river-question",
    title: "Cross-Book planning",
    question: "Which evidence should the two teams compare?",
    reviewer_id: "alex",
    reviewer_name: "Alex Reviewer",
    decision_prompt: "Are the source selections and assignments ready for a one-off collaboration?",
    objection: "Are the observed periods comparable?",
    objection_reviewer_id: "sam",
    objection_reviewer_name: "Sam Reviewer",
    participants: ["water", "mobility"].map(id => {
      book_id: id,
      source_paths: ["raw/nested/source.bin"],
      focus_area: id + " evidence",
      perspective: "Identify assumptions in this Book's evidence",
      contribution: "Cite the captured observations and their limits",
      next_artifact: "A reviewed comparison note",
    }),
  }
}

///|
async test "collaboration saves reopens exact nested binary snapshots and existing civic v1" {
  let (store, root) = fixture()
  let before = @fs.read_file(root + "/catalog.json").binary()
  let draft = fixture_draft()
  let saved = store.save(draft, "", "2026-10-06T16:00:00Z")
  assert_eq(store.load(draft.draft_id), saved)
  let prepared = store.prepare(draft.draft_id, saved.revision)
  assert_eq(store.prepare(draft.draft_id, saved.revision), prepared)
  let prefix = revision_prefix(saved)
  let bytes = store.artifact(
    draft.draft_id,
    saved.revision,
    prefix + "handoff.json",
  )
  let handoff : @civic.CivicCommunicationScenarioHandoff = @json.from_json(
    @json.parse(@utf8.decode(bytes)),
  )
  assert_true(@civic.validate_civic_communication_handoff(handoff).is_empty())
  assert_eq(handoff.scenario.ideas.length(), 0)
  assert_eq(handoff.scenario.participants.length(), 2)
  assert_eq(handoff.scenario.interval_ms, None)
  assert_eq(handoff.scenario.review_gate, "named-human")
  let source = store.artifact(
    draft.draft_id,
    saved.revision,
    prefix + "sources/water/raw/nested/source.bin",
  )
  assert_eq(source, b"exact\x00source\xff\n")
  assert_eq(@fs.read_file(root + "/catalog.json").binary(), before)
  assert_false(@fs.exists(root + "/books/water/review"))
  assert_false(@fs.exists(root + "/state/schedules"))
  assert_eq(
    store.export_tar(draft.draft_id, saved.revision),
    store.export_tar(draft.draft_id, saved.revision),
  )
  assert_false(@utf8.decode(bytes).contains(root))
  @fs.write_file(
    root + "/books/water/raw/nested/source.bin",
    "live file changed",
  )
  assert_eq(store.load(draft.draft_id), saved)
  assert_eq(
    store.artifact(
      draft.draft_id,
      saved.revision,
      prefix + "sources/water/raw/nested/source.bin",
    ),
    source,
  )
}

///|
async test "collaboration incomplete drafts save but preparation validates real sources and assignments" {
  let (store, _) = fixture()
  let incomplete = store.save(
    @contract.empty_draft("unfinished"),
    "",
    "2026-10-06T16:00:00Z",
  )
  let blocked = try {
    ignore(store.prepare("unfinished", incomplete.revision))
    false
  } catch {
    CollaborationError(_) => true
    error => raise error
  }
  assert_true(blocked)
  let draft = fixture_draft()
  let p = { ..draft.participants[0], source_paths: [], }
  let saved = store.save(
    { ..draft, participants: [p, draft.participants[1]], },
    "",
    "2026-10-06T16:00:00Z",
  )
  assert_false(@contract.preparation_issues(saved).is_empty())
}

///|
async test "collaboration save retries are deterministic while stale writes cannot replace a newer revision" {
  let (store, _) = fixture()
  let draft = fixture_draft()
  let first = store.save(draft, "", "2026-10-06T16:00:00Z")
  assert_eq(store.save(draft, "", "2026-10-06T16:00:01Z"), first)
  let next_draft = { ..draft, question: "A revised authored question?", }
  let next = store.save(next_draft, first.revision, "2026-10-06T16:00:02Z")
  assert_true(next.revision != first.revision)
  let blocked = try {
    ignore(store.save(draft, first.revision, "2026-10-06T16:00:03Z"))
    false
  } catch {
    CollaborationError(_) => true
    error => raise error
  }
  assert_true(blocked)
  assert_eq(store.load(draft.draft_id), next)
  assert_eq(store.load(draft.draft_id, revision=first.revision), first)
}

///|
async test "collaboration source-bound review supersedes with no decisions and portable prior evidence" {
  let (store, _) = fixture()
  let draft = fixture_draft()
  let first = store.save(draft, "", "2026-10-06T16:00:00Z")
  ignore(store.prepare(draft.draft_id, first.revision))
  let next = store.save(
    { ..draft, question: "Which gaps remain?", },
    first.revision,
    "2026-10-06T16:01:00Z",
  )
  let prepared = store.prepare(draft.draft_id, next.revision)
  let prefix = revision_prefix(next)
  let packet = store.artifact(
    draft.draft_id,
    next.revision,
    prefix + "source-packet.json",
  )
  let bundle = @review.reimport_review_bundle(
    @utf8.decode(
      store.artifact(
        draft.draft_id,
        next.revision,
        prefix + "review-bundle.json",
      ),
    ),
    packet,
  )
  assert_true(@review.bundle_issues(bundle, digest(packet)).is_empty())
  assert_eq(@review.review_status(bundle), "pending_review")
  assert_eq(bundle.decision_receipts.length(), 0)
  assert_eq(bundle.required_decisions.length(), 2)
  assert_eq(
    bundle.previous_bundle_ref,
    revision_prefix(first) + "review-bundle.json",
  )
  assert_true(
    prepared.artifacts.any(a => {
      a.path == revision_prefix(first) + "sources/water/raw/nested/source.bin"
    }),
  )
  let reused = store.reuse(
    draft.draft_id,
    next.revision,
    "new-collaboration",
    "2026-10-06T16:02:00Z",
  )
  assert_eq(reused.previous_revision, "")
  ignore(store.prepare(reused.draft.draft_id, reused.revision))
  let reused_bundle = @review.reimport_review_bundle(
    @utf8.decode(
      store.artifact(
        reused.draft.draft_id,
        reused.revision,
        revision_prefix(reused) + "review-bundle.json",
      ),
    ),
    store.artifact(
      reused.draft.draft_id,
      reused.revision,
      revision_prefix(reused) + "source-packet.json",
    ),
  )
  assert_eq(reused_bundle.previous_bundle_ref, "")
  assert_true(reused_bundle.decision_receipts.is_empty())
}

///|
async test "collaboration refuses captured-byte tampering and source traversal" {
  let (store, _) = fixture()
  let draft = fixture_draft()
  let saved = store.save(draft, "", "2026-10-06T16:00:00Z")
  ignore(store.prepare(draft.draft_id, saved.revision))
  let path = store.root +
    "/drafts/" +
    draft.draft_id +
    "/" +
    revision_prefix(saved) +
    "sources/water/raw/nested/source.bin"
  @fs.write_file(path, "replaced under same filename")
  assert_true(
    try {
      ignore(store.load(draft.draft_id))
      false
    } catch {
      CollaborationError(_) => true
      error => raise error
    },
  )
  assert_true(
    try {
      ignore(store.export_tar(draft.draft_id, saved.revision))
      false
    } catch {
      CollaborationError(_) => true
      error => raise error
    },
  )
  assert_false(@contract.safe_source_path("../outside"))
  assert_false(@contract.safe_source_path(".env"))
  assert_false(@contract.safe_source_path("/tmp/source"))
}

///|
/// Optional retained producer fixture for the real MoonChat adapter proof.
async test "collaboration retained portable producer fixture" {
  let (store, _) = fixture()
  let first = store.save(fixture_draft(), "", "2026-10-06T16:00:00Z")
  ignore(store.prepare(first.draft.draft_id, first.revision))
  let saved = store.save(
    {
      ..fixture_draft(),
      question: "Which observed gaps should the two Books compare next?",
    },
    first.revision,
    "2026-10-06T16:01:00Z",
  )
  let prepared = store.prepare(saved.draft.draft_id, saved.revision)
  if @env.get_env_var("MOONTOWN_COLLABORATION_FIXTURE_OUTPUT") is Some(output) {
    directory(output, true)
    for artifact in prepared.artifacts {
      write_bytes(
        output + "/" + artifact.path,
        store.artifact(saved.draft.draft_id, saved.revision, artifact.path),
      )
    }
    write_bytes(
      output + "/manifest.json",
      @utf8.encode(prepared.to_json().stringify(indent=2)),
    )
    write_bytes(
      output + "/collaboration.tar",
      store.export_tar(saved.draft.draft_id, saved.revision),
    )
    write_bytes(
      output + "/fixture.json",
      @utf8.encode(saved.to_json().stringify(indent=2)),
    )
  }
}

///|
async test "collaboration API stores incomplete drafts and returns retryable failures without side effects" {
  let (store, root) = fixture()
  let before = @fs.read_file(root + "/catalog.json").binary()
  let request : Request = {
    contract_version: "moontown.collaboration.request.v1",
    request_id: "7",
    action: "save",
    draft_id: "incomplete",
    revision: "",
    new_draft_id: "",
    artifact_path: "",
    payload: None,
    draft: Some(@contract.empty_draft("incomplete")),
  }
  let saved = store.request(
    decode_request(request.to_json().stringify()),
    "2026-10-06T16:00:00Z",
  )
  assert_true(saved.ok)
  assert_eq(saved.request_id, "7")
  let blocked = store.request(
    {
      ..request,
      action: "prepare",
      draft: None,
      revision: saved.saved.unwrap().revision,
    },
    "2026-10-06T16:00:00Z",
  )
  assert_false(blocked.ok)
  assert_true(blocked.error.contains("at least two"))
  let list = store.request(
    { ..request, action: "list", draft: None, },
    "2026-10-06T16:00:00Z",
  )
  assert_eq(list.drafts.length(), 1)
  assert_eq(list.books.length(), 2)
  let unknown = store.request(
    { ..request, action: "start", },
    "2026-10-06T16:00:00Z",
  )
  assert_false(unknown.ok)
  assert_eq(@fs.read_file(root + "/catalog.json").binary(), before)
  assert_false(@fs.exists(root + "/state/schedules"))
  assert_false(@fs.exists(root + "/books/water/review"))
}

///|
async test "collaboration rejects source symlinks missing Books oversized files and reserved reviewers" {
  let (store, root) = fixture()
  let draft = fixture_draft()
  @fs.symlink(
    target=root + "/books/mobility/raw/nested/source.bin",
    root + "/books/water/raw/link.bin",
  )
  let bad = {
    ..draft,
    participants: [
      { ..draft.participants[0], source_paths: ["raw/link.bin"], },
      draft.participants[1],
    ],
  }
  assert_true(
    try {
      ignore(store.save(bad, "", "2026-10-06T16:00:00Z"))
      false
    } catch {
      CollaborationError(_) => true
      error => raise error
    },
  )
  assert_true(
    try {
      ignore(
        store.save(
          {
            ..draft,
            participants: [{ ..draft.participants[0], book_id: "missing", }],
          },
          "",
          "2026-10-06T16:00:00Z",
        ),
      )
      false
    } catch {
      CollaborationError(_) => true
      error => raise error
    },
  )
  @fs.write_file(
    root + "/books/water/raw/large.txt",
    "x".repeat(1048577),
    create_mode=CreateNew,
  )
  assert_true(
    try {
      ignore(
        store.save(
          {
            ..draft,
            participants: [
              { ..draft.participants[0], source_paths: ["raw/large.txt"], },
              draft.participants[1],
            ],
          },
          "",
          "2026-10-06T16:00:00Z",
        ),
      )
      false
    } catch {
      CollaborationError(_) => true
      error => raise error
    },
  )
  let saved = store.save(
    { ..draft, reviewer_id: "town-composer", },
    "",
    "2026-10-06T16:00:00Z",
  )
  assert_true(
    @contract.preparation_issues(saved).any(issue => issue.contains("own IDs")),
  )
}

///|
async test "collaboration prepared review and brief tampering cannot be hidden by editing manifest" {
  let (store, _) = fixture()
  let saved = store.save(fixture_draft(), "", "2026-10-06T16:00:00Z")
  let prepared = store.prepare(saved.draft.draft_id, saved.revision)
  let root = store.draft_root(saved.draft.draft_id)
  let path = revision_prefix(saved) + "briefs/water.md"
  let changed = b"Changed assignment"
  @fs.write_file(root + "/" + path, changed)
  let tampered = {
    ..prepared,
    artifacts: prepared.artifacts.map(a => {
      if a.path == path {
        { ..a, digest: digest(changed), size_bytes: changed.length(), }
      } else {
        a
      }
    }),
  }
  @fs.write_file(
    root + "/" + revision_prefix(saved) + "prepared.json",
    tampered.to_json().stringify(indent=2),
  )
  assert_true(
    try {
      ignore(store.export_tar(saved.draft.draft_id, saved.revision))
      false
    } catch {
      CollaborationError(_) => true
      error => raise error
    },
  )
}

///|
async test "collaboration incomplete atomic write retries recover without replacing committed artifacts" {
  let (store, _) = fixture()
  let saved = store.save(fixture_draft(), "", "2026-10-06T16:00:00Z")
  let root = store.draft_root(saved.draft.draft_id) +
    "/" +
    revision_prefix(saved)
  @fs.write_file(
    root + ".collaboration-next",
    "interrupted staging bytes",
    create_mode=CreateNew,
  )
  let prepared = store.prepare(saved.draft.draft_id, saved.revision)
  assert_eq(store.prepare(saved.draft.draft_id, saved.revision), prepared)
  assert_false(@fs.exists(root + ".collaboration-next"))
}
