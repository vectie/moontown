///|
test "retained outcome native browser request envelope decodes nullable optional fields" {
  let raw = "{\"contract_version\":\"moontown.collaboration.request.v1\",\"request_id\":\"native-http\",\"action\":\"outcome-list\",\"draft_id\":\"\",\"revision\":\"\",\"new_draft_id\":\"\",\"artifact_path\":\"\",\"draft\":null,\"payload\":null}"
  let request = decode_request(raw)
  assert_eq(request.action, "outcome-list")
  assert_eq(request.payload, None)
  assert_eq(
    decode_request(request.to_json().stringify()).to_json(),
    request.to_json(),
  )
  let key : @contract.OutcomeKey = {
    draft_id: "draft",
    revision: "r-revision",
    result_digest: "sha256:" + "1".repeat(64),
    review_version: 0,
    review_digest: "sha256:" + "2".repeat(64),
  }
  let browser : Json = {
    "contract_version": "moontown.collaboration.request.v1",
    "request_id": "inspect",
    "action": "outcome-inspect",
    "draft_id": key.draft_id,
    "revision": key.revision,
    "new_draft_id": "",
    "artifact_path": "",
    "draft": Json::null(),
    "payload": key.to_json(),
  }
  assert_eq(outcome_request_key(decode_request(browser.stringify())), key)
}

///|
/// Fixture construction writes historical evidence. The tested library path
/// below never calls a collector or a runtime, even for absent/corrupt results.
async fn retain_outcome_fixture(
  store : Store,
  saved : @contract.SavedDraft,
  partial : Bool,
) -> @contract.OneoffWork {
  let participants : Array[@contract.ParticipantWork] = []
  for p in saved.draft.participants {
    let packet = "town-" +
      digest(@utf8.encode(saved.revision + "/" + p.book_id))[7:].to_owned()
    let failed = partial && p.book_id == "mobility"
    let text = if failed {
      ""
    } else {
      "Exact contribution 水 café 🚲\nSource: raw/nested/source.bin\nNo consensus inferred <script>.\n"
    }
    let participant : @contract.ParticipantWork = {
      book_id: p.book_id,
      packet_id: packet,
      proposal_id: "oneoff-" + packet,
      run_id: "run-oneoff-" + packet,
      status: if failed {
        "failed"
      } else {
        "completed"
      },
      detail: if failed {
        "Attributed fixture failure: incomplete observations"
      } else {
        "Retained local fixture contribution"
      },
      output_ref: if failed {
        ""
      } else {
        revision_prefix(saved) + "oneoff/produced/" + p.book_id + "/report.md"
      },
      output_digest: if failed {
        ""
      } else {
        digest(@utf8.encode(text))
      },
      output_text: text,
    }
    participants.push(participant)
    let root = store.work_root(saved) + "/produced/" + p.book_id
    write_bytes(
      root + "/terminal.json",
      @utf8.encode(participant.to_json().stringify(indent=2)),
    )
    if !failed {
      write_bytes(root + "/report.md", @utf8.encode(text))
    }
  }
  let result = collected_result(
    saved,
    digest(source_packet(saved)),
    participants,
  )
  write_bytes(
    store.work_root(saved) + "/result.json",
    @utf8.encode(result.stringify(indent=2)),
  )
  let work = store.retained_work(saved)
  ignore(store.current_work_review(saved, work))
  work
}

///|
async fn outcome_fixture_decision(
  store : Store,
  saved : @contract.SavedDraft,
  work : @contract.OneoffWork,
  prior : @review.ConversationReviewBundle,
  version : Int,
  decision_id : String,
  decision : String,
) -> @review.ConversationReviewBundle {
  let required = prior.required_decisions
    .iter()
    .find_first(d => d.decision_id == decision_id)
    .unwrap()
  let reviewer = prior.participants
    .iter()
    .find_first(p => p.participant_id == required.reviewer_participant_id)
    .unwrap()
  let receipt : @review.HumanDecisionReceipt = {
    receipt_id: "decision-" + version.to_string(),
    decision_id,
    reviewer_participant_id: reviewer.participant_id,
    reviewer_name: reviewer.display_name,
    decision,
    rationale: "Historical local fixture decision 水; no real-human claim",
    source_digest: work.result_digest,
    decided_at: "2026-10-07T08:00:00Z",
    evidence_refs: [prior.source_artifact_ref],
  }
  let receipts = prior.decision_receipts.filter(r => {
    r.decision_id != decision_id
  })
  receipts.push(receipt)
  let bundle = { ..prior, decision_receipts: receipts, }
  write_bytes(
    store.work_root(saved) + "/review/" + version.to_string() + ".json",
    @utf8.encode(@review.serialize_review_bundle(bundle, work.result_digest)),
  )
  bundle
}

///|
async fn outcome_tree(path : String) -> Array[String] {
  let result : Array[String] = []
  for name in outcome_children(path, 4096) {
    let full = path + "/" + name
    match kind(full) {
      Some(Directory) => {
        result.push(full + "/")
        for entry in outcome_tree(full) {
          result.push(entry)
        }
      }
      Some(Regular) =>
        result.push(full + " " + digest(read_bytes(full, 33554432)))
      _ => result.push(full + " special")
    }
  }
  result
}

///|
/// Independent tar reader checks every header checksum and raw member length.
fn outcome_tar_files(bytes : Bytes) -> Map[String, Bytes] raise {
  let files : Map[String, Bytes] = Map([])
  let mut offset = 0
  while offset + 512 <= bytes.length() && bytes[offset] != b'\x00' {
    let header = bytes[offset:offset + 512].to_owned()
    let text = @utf8.decode(header)
    let name = text[:100].split("\u0000").next().unwrap().to_owned()
    let mut size = 0
    for b in header[124:136] {
      if b >= b'0' && b <= b'7' {
        size = size * 8 + b.to_int() - 48
      }
    }
    let mut checksum = 0
    for b in header[148:156] {
      if b >= b'0' && b <= b'7' {
        checksum = checksum * 8 + b.to_int() - 48
      }
    }
    let mut actual = 0
    for i in 0..<512 {
      actual += if i >= 148 && i < 156 { 32 } else { header[i].to_int() }
    }
    assert_eq(actual, checksum)
    assert_false(files.contains(name))
    assert_true(offset + 512 + size <= bytes.length())
    files[name] = bytes[offset + 512:offset + 512 + size].to_owned()
    offset += 512 + (size + 511) / 512 * 512
  }
  assert_eq(bytes.length() - offset, 1024)
  files
}

///|
async test "retained outcome library indexes multiple drafts revisions and exact pinned review archives without mutation" {
  let (store, root) = fixture()
  let first = store.save(fixture_draft(), "", "2026-10-07T07:00:00Z")
  ignore(store.prepare(first.draft.draft_id, first.revision))
  let work = retain_outcome_fixture(store, first, false)
  let initial = result_bundle(first, work)
  let entry0 = store.list_outcomes()[0]
  let snapshot0 = store.inspect_outcome(entry0.key())
  let archive0 = store.export_outcome(entry0.key())
  assert_eq(snapshot0.review_status, "pending_review")
  let rejected = outcome_fixture_decision(
    store, first, work, initial, 1, "review-result", "reject",
  )
  let rejected = outcome_fixture_decision(
    store, first, work, rejected, 2, "resolve-objection", "approve",
  )
  let key2 = store.list_outcomes()[0].key()
  assert_eq(store.inspect_outcome(key2).review_status, "rejected")
  let rejected_archive = store.export_outcome(key2)
  let deferred = outcome_fixture_decision(
    store, first, work, rejected, 3, "review-result", "defer",
  )
  assert_eq(store.list_outcomes()[0].review_status, "deferred")
  let key3 = store.list_outcomes()[0].key()
  let deferred_archive = store.export_outcome(key3)
  ignore(
    outcome_fixture_decision(
      store, first, work, deferred, 4, "review-result", "approve",
    ),
  )
  let key4 = store.list_outcomes()[0].key()
  assert_eq(store.inspect_outcome(key4).review_status, "accepted")
  assert_eq(store.export_outcome(entry0.key()), archive0)
  assert_eq(store.export_outcome(key2), rejected_archive)
  let second = store.save(
    { ..first.draft, question: "Revised question", },
    first.revision,
    "2026-10-07T07:01:00Z",
  )
  ignore(retain_outcome_fixture(store, second, true))
  let third = store.save(
    { ..fixture_draft(), draft_id: "another-question", },
    "",
    "2026-10-07T07:02:00Z",
  )
  ignore(retain_outcome_fixture(store, third, false))
  let fresh = store.reuse(
    first.draft.draft_id,
    first.revision,
    "fresh-question",
    "2026-10-07T07:03:00Z",
  )
  let before = outcome_tree(root)
  let entries = store.list_outcomes()
  assert_eq(entries.length(), 4)
  assert_eq(@contract.filter_outcomes(entries, "completed", "").length(), 2)
  assert_eq(
    @contract.filter_outcomes(entries, "partial", "pending_review").length(),
    1,
  )
  assert_eq(@contract.filter_outcomes(entries, "", "accepted").length(), 1)
  let reused = entries
    .iter()
    .find_first(e => e.draft_id == fresh.draft.draft_id)
    .unwrap()
  assert_eq(reused.outcome_status, "not_retained")
  assert_eq(reused.review_status, "not_ready")
  let partial = entries
    .iter()
    .find_first(e => e.revision == second.revision)
    .unwrap()
  let dossier = store.inspect_outcome(partial.key())
  assert_eq(dossier.work.participants[1].status, "failed")
  assert_true(dossier.work.participants[1].detail.contains("Attributed"))
  let archive = store.export_outcome(partial.key())
  assert_eq(digest(archive), dossier.archive_digest)
  assert_eq(archive.length(), dossier.archive_size_bytes)
  assert_eq(store.export_outcome(partial.key()), archive)
  let files = outcome_tar_files(archive)
  let manifest = @json.parse(text_bytes(files["manifest.json"]))
  guard manifest is { "artifacts": Array(items), "selection": selection, .. } else {
    fail("manifest")
  }
  assert_eq(selection, partial.key().to_json())
  assert_eq(items.length(), files.length() - 1)
  for value in items {
    let artifact : @contract.Artifact = @json.from_json(value)
    assert_eq(files[artifact.path].length(), artifact.size_bytes)
    assert_eq(digest(files[artifact.path]), artifact.digest)
  }
  assert_eq(
    files["sources/water/raw/nested/source.bin"],
    b"exact\x00source\xff\n",
  )
  assert_true(
    text_bytes(files["participants/water/report.md"]).contains("水 café 🚲"),
  )
  assert_false(files.contains("participants/mobility/report.md"))
  assert_true(
    text_bytes(files["SUMMARY.md"]).contains("Attributed fixture failure"),
  )
  assert_eq(files["result.json"], @utf8.encode(dossier.work.result_text))
  let first_files = outcome_tar_files(archive0)
  assert_true(first_files.contains("review/0.json"))
  assert_false(first_files.contains("review/1.json"))
  assert_eq(outcome_tree(root), before)
  assert_true(
    try {
      ignore(store.export_outcome({ ..partial.key(), review_version: 99, }))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(
        store.export_outcome({ ..partial.key(), result_digest: "sha256:wrong", }),
      )
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(
        store.export_outcome({ ..partial.key(), review_digest: "sha256:wrong", }),
      )
      false
    } catch {
      _ => true
    },
  )
  if @env.get_env_var("MOONTOWN_OUTCOME_EVIDENCE") is Some(path) {
    directory(path, true)
    write_bytes(path + "/root.txt", @utf8.encode(root))
    write_bytes(
      path + "/partial-outcome.json",
      @utf8.encode(dossier.to_json().stringify(indent=2)),
    )
    write_bytes(path + "/partial.tar", archive)
    write_bytes(path + "/pending.tar", archive0)
    write_bytes(path + "/rejected.tar", rejected_archive)
    write_bytes(path + "/deferred.tar", deferred_archive)
    write_bytes(
      path + "/plan.tar",
      store.export_tar(first.draft.draft_id, first.revision),
    )
    write_bytes(
      path + "/pending-key.json",
      @utf8.encode(entry0.key().to_json().stringify()),
    )
    write_bytes(
      path + "/rejected-key.json",
      @utf8.encode(key2.to_json().stringify()),
    )
    write_bytes(
      path + "/deferred-key.json",
      @utf8.encode(key3.to_json().stringify()),
    )
    write_bytes(
      path + "/index.json",
      @utf8.encode(entries.to_json().stringify(indent=2)),
    )
    write_bytes(
      path + "/before.json",
      @utf8.encode(before.to_json().stringify(indent=2)),
    )
    write_bytes(
      path + "/after.json",
      @utf8.encode(outcome_tree(root).to_json().stringify(indent=2)),
    )
  }
}

///|
async test "retained outcome corruption missing files and symlink traversal stay unavailable without repairs" {
  for
    corruption in [
      "source", "result", "contribution", "terminal", "review", "missing-review",
      "missing-result", "symlink",
    ] {
    let (store, root) = fixture()
    let saved = store.save(fixture_draft(), "", "2026-10-07T07:00:00Z")
    ignore(retain_outcome_fixture(store, saved, false))
    let key = store.list_outcomes()[0].key()
    let work_root = store.work_root(saved)
    let path = match corruption {
      "source" =>
        store.draft_root(saved.draft.draft_id) +
        "/" +
        revision_prefix(saved) +
        "sources/water/raw/nested/source.bin"
      "result" | "missing-result" => work_root + "/result.json"
      "terminal" => work_root + "/produced/water/terminal.json"
      "review" | "missing-review" => work_root + "/review/0.json"
      _ => work_root + "/produced/water/report.md"
    }
    if corruption.has_prefix("missing") {
      @fs.remove(path)
    } else if corruption == "symlink" {
      @fs.remove(path)
      @fs.symlink(target=root + "/books/water/raw/nested/source.bin", path)
    } else {
      @fs.write_file(path, "substituted bytes")
    }
    let before = outcome_tree(root)
    let entry = store.list_outcomes()[0]
    assert_eq(entry.outcome_status, "unavailable", msg=corruption)
    assert_false(entry.error.is_empty())
    assert_true(
      try {
        ignore(store.inspect_outcome(key))
        false
      } catch {
        _ => true
      },
      msg=corruption,
    )
    assert_true(
      try {
        ignore(store.export_outcome(key))
        false
      } catch {
        _ => true
      },
      msg=corruption,
    )
    assert_eq(outcome_tree(root), before)
  }
}

///|
async test "retained outcome empty store and bounded enumeration do not create or silently omit data" {
  let root = @fs.realpath(@fs.tmpdir(prefix="town-empty-library-"))
  let store : Store = {
    root: root + "/absent",
    catalog_path: root + "/absent-catalog",
  }
  assert_eq(store.list_outcomes(), [])
  assert_false(@fs.exists(store.root))
  let (store, _) = fixture()
  let saved = store.save(fixture_draft(), "", "2026-10-07T07:00:00Z")
  for i in 0..<65 {
    directory(
      store.draft_root(saved.draft.draft_id) +
      "/revisions/extra-" +
      i.to_string(),
      true,
    )
  }
  let entries = store.list_outcomes()
  assert_eq(entries.length(), 1)
  assert_eq(entries[0].outcome_status, "unavailable")
  assert_true(entries[0].error.contains("limit"))
}

///|
async test "retained outcome selected history remains deterministic when a later review is corrupt" {
  let (store, _) = fixture()
  let saved = store.save(fixture_draft(), "", "2026-10-07T07:00:00Z")
  let work = retain_outcome_fixture(store, saved, false)
  let key = store.list_outcomes()[0].key()
  let before = store.export_outcome(key)
  ignore(
    outcome_fixture_decision(
      store,
      saved,
      work,
      result_bundle(saved, work),
      1,
      "review-result",
      "defer",
    ),
  )
  @fs.write_file(
    store.work_root(saved) + "/review/1.json",
    "corrupt later review",
  )
  assert_eq(store.list_outcomes()[0].outcome_status, "unavailable")
  assert_eq(store.export_outcome(key), before)
  assert_eq(store.inspect_outcome(key).work.review_version, 0)
}

///|
async test "retained outcome coherent snapshot holds the same authoring writer lock" {
  let (store, _) = fixture()
  let saved = store.save(fixture_draft(), "", "2026-10-07T07:00:00Z")
  let work = retain_outcome_fixture(store, saved, false)
  let key = store.list_outcomes()[0].key()
  let before = store.export_outcome(key)
  let held = @async.Semaphore(1, initial_value=0)
  let release = @async.Semaphore(1, initial_value=0)
  let wrote = [false]
  @async.with_task_group(group => {
    let reader = group.spawn(() => {
      store.read_locked(() => {
        held.release()
        release.acquire()
        assert_false(wrote[0])
        store.outcome_snapshot(key).1
      })
    })
    held.acquire()
    let writer = group.spawn(() => {
      store.locked(() => {
        wrote[0] = true
        ignore(
          outcome_fixture_decision(
            store,
            saved,
            work,
            result_bundle(saved, work),
            1,
            "review-result",
            "defer",
          ),
        )
      })
    })
    @async.sleep(10)
    assert_false(wrote[0])
    release.release()
    assert_eq(reader.wait(), before)
    writer.wait()
  })
  assert_true(wrote[0])
  assert_eq(store.list_outcomes()[0].review_version, 1)
  assert_eq(store.export_outcome(key), before)
}
