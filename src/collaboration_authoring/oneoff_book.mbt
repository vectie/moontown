///|
fn required_text(value : Json, key : String) -> String raise {
  guard value is Object(fields) &&
    fields.get(key) is Some(String(text)) &&
    !text.trim().is_empty() &&
    text.length() <= 4000 else {
    raise CollaborationError("Enter " + key + " (up to 4000 characters)")
  }
  text
}

///|
fn outcome_gap(
  fields : Json,
  name : String,
  evidence : Array[String],
) -> Json raise {
  let raw = required_text(fields, name + "_severity")
  let severity = match raw {
    "0" => 0
    "1" => 1
    "2" => 2
    "3" => 3
    "4" => 4
    "5" => 5
    _ =>
      raise CollaborationError("Choose " + name + " gap severity from 0 to 5")
  }
  {
    "present": severity > 0,
    "severity": severity,
    "summary": required_text(fields, name + "_summary"),
    "evidence_refs": evidence.to_json(),
  }
}

///|
fn retained_text_artifact(
  id : String,
  text : String,
  provenance : String,
) -> Json {
  {
    "reference": {
      "reference_id": id,
      "reference_version": "1",
      "digest": digest(@utf8.encode(text)),
      "provenance_ref": provenance,
    },
    "text": text,
    "media_type": "application/json",
  }
}

///|
async fn Store::make_work_package(
  self : Store,
  saved : @contract.SavedDraft,
  work : @contract.OneoffWork,
  fields : Json,
  observed_at : Int,
) -> Json {
  guard ["completed", "partial"].contains(work.status) &&
    work.review_status == "accepted" else {
    raise CollaborationError(
      "Only a fully terminal result with all named-owner decisions approving its accurate account can enter this handoff. Running, unknown, unreviewed, rejected and deferred results remain inspectable",
    )
  }
  guard fields
    is {
      "result_digest": String(expected),
      "review_version": Number(version),
      ..
    } &&
    expected == work.result_digest &&
    version == work.review_version.to_double() else {
    raise CollaborationError(
      "Result or review changed; refresh before exporting this outcome",
    )
  }
  let book_id = required_text(fields, "book_id")
  let summary = required_text(fields, "outcome_summary")
  let source_files : Array[Json] = []
  for source in saved.sources {
    let bytes = read_bytes(
      self.draft_root(saved.draft.draft_id) +
      "/" +
      revision_prefix(saved) +
      source.artifact_ref,
      1048576,
    )
    source_files.push({
      "snapshot": source.to_json(),
      "encoding": "hex",
      "bytes_hex": @crypto.bytes_to_hex_string(bytes),
    })
  }
  let source_text = (
    {
      "contract_version": "moontown.retained-collaboration-source.v1",
      "saved_draft": saved.to_json(),
      "files": source_files.to_json(),
      "note": "Exact original input bytes retained as hex, including binary sources; source digests refer to decoded original bytes.",
    } : Json).stringify(indent=2)
  let (bundle, _) = self.current_work_review(saved, work)
  let history : Array[Json] = []
  for version in 0..<=work.review_version {
    history.push(
      @json.parse(
        text_bytes(
          read_bytes(
            self.work_root(saved) + "/review/" + version.to_string() + ".json",
            2097152,
          ),
        ),
      ),
    )
  }
  let review_text = (
    {
      "record": @review.project_review_record(bundle, work.result_digest, []).to_json(),
      "history": history.to_json(),
      "authority": "Existing host operator identity matched to each named decision owner. This is not Book acceptance.",
    } : Json).stringify(indent=2)
  let prefix = "moontown-" + saved.draft.draft_id + "-" + saved.revision
  let evidence_ids = [
    prefix + "-sources",
    prefix + "-result",
    prefix + "-review",
    prefix + "-interpretation",
  ]
  let information = outcome_gap(fields, "information", evidence_ids)
  let recognition = outcome_gap(fields, "recognition", evidence_ids)
  let decisiveness = outcome_gap(fields, "decisiveness", evidence_ids)
  let statement_fields : Map[String, Json] = {
    "contract_version": "moontown.collaboration-outcome-statement.v1".to_json(),
    "draft_id": saved.draft.draft_id.to_json(),
    "revision": saved.revision.to_json(),
    "result_digest": work.result_digest.to_json(),
    "review_digest": digest(@utf8.encode(review_text)).to_json(),
    "book_id": book_id.to_json(),
    "outcome_summary": summary.to_json(),
    "observed_at": observed_at.to_json(),
    "information_gap": information,
    "recognition_gap": recognition,
    "decisiveness_gap": decisiveness,
  }
  let gaps_present = [information, recognition, decisiveness].any(g => {
    g is { "present": True, .. }
  })
  if gaps_present {
    statement_fields["capability_id"] = required_text(fields, "capability_id").to_json()
    statement_fields["capability_version"] = required_text(
      fields, "capability_version",
    ).to_json()
    statement_fields["capability_summary"] = required_text(
      fields, "capability_summary",
    ).to_json()
    statement_fields["capability_change_digest"] = digest(
      @utf8.encode(required_text(fields, "capability_summary")),
    ).to_json()
  }
  let statement = Json::object(statement_fields)
  let statement_text = statement.stringify(indent=2)
  let identity = digest(@utf8.encode(statement_text))
  let route = "moontown://collaboration/" +
    saved.draft.draft_id +
    "/" +
    saved.revision
  let artifacts = [
    retained_text_artifact(evidence_ids[0], source_text, route + "/sources"),
    retained_text_artifact(evidence_ids[1], work.result_text, route + "/result"),
    retained_text_artifact(evidence_ids[2], review_text, route + "/review"),
    retained_text_artifact(
      evidence_ids[3],
      statement_text,
      route + "/interpretation",
    ),
  ]
  let references = artifacts.map(a => {
    match a {
      { "reference": reference, .. } => reference
      _ => Json::null()
    }
  })
  let submission : Json = {
    "contract_version": "moonbook.bookkeeper.product_outcome_submission.v1",
    "submission": {
      "record_id": prefix + "-outcome-" + identity[7:].to_owned(),
      "record_version": "1",
      "record_digest": identity,
    },
    "source_product": "moontown",
    "deliverable_title": saved.draft.title,
    "deliverable_summary": "Reviewed terminal one-off outcome: " +
    work.participants.filter(p => p.status == "completed").length().to_string() +
    " participant(s) succeeded, " +
    work.participants.filter(p => p.status == "failed").length().to_string() +
    " failed. Exact inputs, outputs and failures are retained. Approval covers the account, not a claim of successful collaboration. Book makes its own independent decision.",
    "outcome_summary": summary,
    "owner_route": route,
    "evidence_refs": references.to_json(),
    "decision_evidence_id": evidence_ids[2],
    "observed_at": observed_at,
    "recorded_at": observed_at,
    "information_gap": information,
    "recognition_gap": recognition,
    "decisiveness_gap": decisiveness,
  }
  if submission is Object(target) {
    for
      key in [
        "capability_id", "capability_version", "capability_summary", "capability_change_digest",
      ] {
      if statement_fields.get(key) is Some(value) {
        target[key] = value
      }
    }
  }
  let payload = (
    { "submission": submission, "artifacts": artifacts.to_json() } : Json).stringify(
    indent=2,
  )
  guard @utf8.encode(payload).length() <= 8388608 else {
    raise CollaborationError(
      "Exact retained outcome exceeds Book's 8 MiB text package limit; nothing was omitted or sent",
    )
  }
  {
    "contract_version": "moonbook.product-outcome-package.v1",
    "package_digest": digest(@utf8.encode(payload)),
    "payload_json": payload,
  }
}

///|
fn checked_work_readback(package : Json, wrapper : Json) -> Json raise {
  let receipt = match wrapper {
    { "result": result, .. } => result
    _ => wrapper
  }
  guard package
    is {
      "package_digest": String(expected),
      "payload_json": String(payload),
      ..
    } &&
    receipt
    is {
      "contract_version": "moonbook.product-outcome-readback.v1",
      "package_digest": String(actual),
      "package": returned,
      "progress": { "submission": reference, "state": String(state), .. },
      "reviews": Array(_),
      "activation_authorized": False,
      "external_side_effects_applied": False,
      ..
    } &&
    actual == expected &&
    returned == package &&
    digest(@utf8.encode(payload)) == expected &&
    @json.parse(payload) is { "submission": { "submission": original, .. }, .. } &&
    reference == original &&
    [
      "deliverable_review_required", "deliverable_rejected", "continue_required",
      "assessment_review_required", "assessment_rejected", "reviewed_source_available",
    ].contains(state) else {
    raise CollaborationError(
      "Book disposition does not match the exact retained Town outcome package",
    )
  }
  receipt
}

///|
/// Returned Book observations cannot replace the Town source/result/review.
/// Revalidate every retained constituent against the owning revision on reopen.
async fn Store::verify_work_package(
  self : Store,
  saved : @contract.SavedDraft,
  work : @contract.OneoffWork,
  package : Json,
) -> Unit {
  guard package
    is {
      "payload_json": String(payload),
      "package_digest": String(package_digest),
      ..
    } &&
    digest(@utf8.encode(payload)) == package_digest &&
    @json.parse(payload)
    is {
      "submission": { "source_product": "moontown", .. },
      "artifacts": Array(artifacts),
      ..
    } &&
    artifacts.length() == 4 else {
    raise CollaborationError("Retained Town outcome package is invalid")
  }
  let texts : Array[String] = []
  for artifact in artifacts {
    guard artifact
      is {
        "reference": { "digest": String(expected), .. },
        "text": String(text),
        ..
      } &&
      digest(@utf8.encode(text)) == expected else {
      raise CollaborationError("Retained Book evidence bytes changed")
    }
    texts.push(text)
  }
  guard texts[1] == work.result_text &&
    @json.parse(texts[0])
    is { "saved_draft": captured, "files": Array(files), .. } &&
    captured == saved.to_json() &&
    files.length() == saved.sources.length() &&
    @json.parse(texts[3])
    is {
      "draft_id": String(id),
      "revision": String(revision),
      "result_digest": String(result_digest),
      "review_digest": String(review_digest),
      ..
    } &&
    id == saved.draft.draft_id &&
    revision == saved.revision &&
    result_digest == work.result_digest &&
    review_digest == digest(@utf8.encode(texts[2])) else {
    raise CollaborationError(
      "Book package belongs to a different captured Town result",
    )
  }
  for i in 0..<saved.sources.length() {
    let source = saved.sources[i]
    let bytes = read_bytes(
      self.draft_root(saved.draft.draft_id) +
      "/" +
      revision_prefix(saved) +
      source.artifact_ref,
      1048576,
    )
    guard files[i]
      is {
        "snapshot": snapshot,
        "encoding": "hex",
        "bytes_hex": String(hex),
        ..
      } &&
      snapshot == source.to_json() &&
      hex == @crypto.bytes_to_hex_string(bytes) else {
      raise CollaborationError(
        "Book package original source bytes do not match this collaboration",
      )
    }
  }
  guard @json.parse(texts[2])
    is { "record": record, "history": Array(history), .. } &&
    !history.is_empty() &&
    history.length() <= work.review_version + 1 else {
    raise CollaborationError("Book package review history is not retained here")
  }
  for i in 0..<history.length() {
    guard history[i] ==
      @json.parse(
        text_bytes(
          read_bytes(
            self.work_root(saved) + "/review/" + i.to_string() + ".json",
            2097152,
          ),
        ),
      ) else {
      raise CollaborationError(
        "Book package changed an earlier named-owner decision",
      )
    }
  }
  let reviewed = @review.reimport_review_bundle(
    history[history.length() - 1].stringify(),
    @utf8.encode(work.result_text),
  )
  guard @review.project_review_record(reviewed, work.result_digest, []).to_json() ==
    record &&
    @review.review_status(reviewed) == "accepted" else {
    raise CollaborationError(
      "Book package is not bound to the retained accepted Chat result",
    )
  }
}

///|
async fn replace_work_pointer(path : String, text : String) -> Unit {
  guard kind(path) is (None | Some(Regular)) else {
    raise CollaborationError("Unsafe work pointer")
  }
  let temporary = path + ".next"
  if kind(temporary) is Some(Regular) {
    @fs.remove(temporary)
  }
  @fs.write_file(temporary, text, create_mode=CreateNew, sync=Full)
  @fs.rename(temporary, path, replace=true)
}

///|
pub async fn Store::submit_oneoff(
  self : Store,
  id : String,
  revision : String,
  fields : Json,
  observed_at : Int,
) -> @contract.OneoffWork {
  self.locked(() => {
    let saved = self.load_revision(id, revision)
    ignore(self.verify_prepared(saved))
    let work = self.collect_work(saved, self.work_intent(saved))
    let book_id = required_text(fields, "book_id")
    let catalog = @moonbook.load_catalog_file(self.catalog_path).unwrap_or([])
    guard catalog.iter().find_first(entry => entry.id == book_id) is Some(entry) else {
      raise CollaborationError("Choose a currently registered destination Book")
    }
    guard ["completed", "partial"].contains(work.status) &&
      work.review_status == "accepted" &&
      fields
      is {
        "result_digest": String(expected),
        "review_version": Number(version),
        ..
      } &&
      expected == work.result_digest &&
      version == work.review_version.to_double() else {
      raise CollaborationError(
        "Refresh the exact terminal result and its approved account before submitting an outcome",
      )
    }
    let request_key = digest(@utf8.encode(fields.stringify()))[7:].to_owned()
    let request_path = self.work_root(saved) +
      "/outcome-requests/" +
      request_key +
      ".json"
    let package = if kind(request_path) is Some(Regular) {
      @json.parse(text_bytes(read_bytes(request_path, 16777216)))
    } else {
      let package = self.make_work_package(saved, work, fields, observed_at)
      write_bytes(request_path, @utf8.encode(package.stringify(indent=2)))
      package
    }
    guard package is { "package_digest": String(package_digest), .. } else {
      abort("constructed package")
    }
    let root = self.work_root(saved) +
      "/outcomes/" +
      package_digest[7:].to_owned()
    let path = root + "/package.json"
    write_bytes(path, @utf8.encode(package.stringify(indent=2)))
    write_bytes(
      root + "/destination.json",
      @utf8.encode(
        ({ "book_id": book_id, "workspace_root": entry.workspace_root } : Json).stringify(),
      ),
    )
    // Book idempotently imports the exact source package; import never advances
    // Book's own review gates. A lost reply is recoverable with the same bytes.
    let receipt = checked_work_readback(
      package,
      @moonbook.product_outcome_operation(entry, "product-import", path),
    )
    self.retain_work_readback(saved, package_digest, receipt)
    self.project_book_readback(saved, work)
  })
}

///|
async fn Store::retain_work_readback(
  self : Store,
  saved : @contract.SavedDraft,
  package_digest : String,
  receipt : Json,
) -> Unit {
  let root = self.work_root(saved)
  let bytes = @utf8.encode(receipt.stringify(indent=2))
  let name = digest(bytes)[7:].to_owned()
  write_bytes(
    root +
    "/outcomes/" +
    package_digest[7:].to_owned() +
    "/receipts/" +
    name +
    ".json",
    bytes,
  )
  replace_work_pointer(
    root + "/book-current.json",
    ({ "package_digest": package_digest, "receipt_id": name } : Json).stringify(),
  )
}

///|
async fn Store::project_book_readback(
  self : Store,
  saved : @contract.SavedDraft,
  work : @contract.OneoffWork,
) -> @contract.OneoffWork {
  let root = self.work_root(saved)
  if kind(root + "/book-current.json") is None {
    return work
  }
  guard @json.parse(text_bytes(read_bytes(root + "/book-current.json", 1024)))
    is {
      "package_digest": String(package_digest),
      "receipt_id": String(name),
      ..
    } &&
    package_digest.has_prefix("sha256:") &&
    @contract.safe_id(package_digest[7:].to_owned()) &&
    @contract.safe_id(name) else {
    raise CollaborationError("Invalid Book receipt pointer")
  }
  let outcome_root = root + "/outcomes/" + package_digest[7:].to_owned()
  let package = @json.parse(
    text_bytes(read_bytes(outcome_root + "/package.json", 16777216)),
  )
  self.verify_work_package(saved, work, package)
  let receipt = checked_work_readback(
    package,
    @json.parse(
      text_bytes(
        read_bytes(outcome_root + "/receipts/" + name + ".json", 16777216),
      ),
    ),
  )
  let state = match receipt {
    { "progress": { "state": String(state), .. }, .. } => state
    _ => "unavailable"
  }
  {
    ..work,
    package_digest,
    book_status: state,
    detail: work.detail +
    " Book: " +
    state +
    ". This is an unsigned historical local observation. Refresh Book for its current decision; no activation is authorized.",
  }
}

///|
pub async fn Store::refresh_oneoff_book(
  self : Store,
  id : String,
  revision : String,
) -> @contract.OneoffWork {
  self.locked(() => {
    let saved = self.load_revision(id, revision)
    let work = self.collect_work(saved, self.work_intent(saved))
    let current = self.project_book_readback(saved, work)
    guard !current.package_digest.is_empty() else {
      raise CollaborationError("Send a settled outcome to Book first")
    }
    let root = self.work_root(saved) +
      "/outcomes/" +
      current.package_digest[7:].to_owned()
    let package = @json.parse(
      text_bytes(read_bytes(root + "/package.json", 16777216)),
    )
    guard package is { "payload_json": String(payload), .. } &&
      @json.parse(payload)
      is { "submission": { "submission": reference, .. }, .. } &&
      @json.parse(text_bytes(read_bytes(root + "/destination.json", 4096)))
      is { "book_id": String(book_id), "workspace_root": String(workspace), .. } else {
      raise CollaborationError("Retained Book destination is unavailable")
    }
    let catalog = @moonbook.load_catalog_file(self.catalog_path).unwrap_or([])
    guard catalog
      .iter()
      .find_first(entry => {
        entry.id == book_id && entry.workspace_root == workspace
      })
      is Some(entry) else {
      raise CollaborationError(
        "Destination Book registration changed. Retained historical disposition remains available",
      )
    }
    let path = root + "/read-request.json"
    write_bytes(
      path,
      @utf8.encode(({ "submission": reference } : Json).stringify()),
    )
    self.retain_work_readback(
      saved,
      current.package_digest,
      checked_work_readback(
        package,
        @moonbook.product_outcome_operation(entry, "product-read", path),
      ),
    )
    self.project_book_readback(saved, work)
  })
}
