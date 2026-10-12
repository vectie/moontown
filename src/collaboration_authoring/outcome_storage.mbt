///|
/// Same cross-process lock as writers, opened without creating anything.
async fn[T] Store::read_locked(self : Store, operation : async () -> T) -> T {
  mutex.acquire()
  defer mutex.release()
  directory(self.root, false)
  let path = self.root + "/authoring.lock"
  guard kind(path) is Some(Regular) else {
    raise CollaborationError("Existing collaboration lock is unavailable")
  }
  let lock = @fs.open(path, mode=ReadOnly)
  defer lock.close()
  lock.lock(Exclusive)
  defer lock.unlock()
  operation()
}

///|
/// Bound enumeration before allocation; never follow a directory symlink.
async fn outcome_children(path : String, limit : Int) -> Array[String] {
  directory(path, false)
  let dir = @fs.opendir(path)
  defer dir.close()
  let names : Array[String] = []
  while dir.next(include_hidden=true) is Some(entry) {
    guard names.length() < limit else {
      raise CollaborationError(
        "Retained outcome index limit exceeded; narrow the local store before browsing",
      )
    }
    names.push(entry.name)
  }
  names.sort()
  names
}

///|
async fn outcome_bytes(root : String, path : String, limit : Int) -> Bytes {
  guard @contract.safe_source_path(path) else {
    raise CollaborationError("Unsafe retained outcome path")
  }
  let absolute = root + "/" + path
  directory(absolute[:absolute.rev_find("/").unwrap()].to_owned(), false)
  read_bytes(absolute, limit)
}

///|
/// This deliberately never calls read_oneoff, collect_work, current_work_review,
/// project_book_readback, any runtime adapter, or any writer.
async fn Store::retained_work(
  self : Store,
  saved : @contract.SavedDraft,
) -> @contract.OneoffWork {
  let root = self.work_root(saved)
  let bytes = outcome_bytes(root, "result.json", 16777216)
  let result = @json.parse(text_bytes(bytes))
  guard result is { "participants": Array(values), .. } else {
    raise CollaborationError("Retained result has no attributed participants")
  }
  let participants : Array[@contract.ParticipantWork] = @json.from_json(
    values.to_json(),
  )
  guard participants.length() == saved.draft.participants.length() &&
    participants.length() >= 2 else {
    raise CollaborationError("Retained result participant set changed")
  }
  for i in 0..<participants.length() {
    let p = participants[i]
    let packet_id = "town-" +
      digest(@utf8.encode(saved.revision + "/" + p.book_id))[7:].to_owned()
    guard p.book_id == saved.draft.participants[i].book_id &&
      p.packet_id == packet_id &&
      p.proposal_id == "oneoff-" + packet_id &&
      p.run_id == "run-oneoff-" + packet_id &&
      ["completed", "failed"].contains(p.status) else {
      raise CollaborationError(
        "Retained participant identity or terminal status changed",
      )
    }
    let terminal = @json.parse(
      text_bytes(
        outcome_bytes(root, "produced/" + p.book_id + "/terminal.json", 2097152),
      ),
    )
    guard terminal == p.to_json() else {
      raise CollaborationError(
        "Retained participant receipt differs from the collected result",
      )
    }
    if p.status == "completed" {
      let expected_ref = revision_prefix(saved) +
        "oneoff/produced/" +
        p.book_id +
        "/report.md"
      let report = outcome_bytes(
        root,
        "produced/" + p.book_id + "/report.md",
        1048576,
      )
      guard p.output_ref == expected_ref &&
        digest(report) == p.output_digest &&
        text_bytes(report) == p.output_text &&
        !p.output_text.trim().is_empty() else {
        raise CollaborationError(
          "Retained contribution bytes or attribution changed",
        )
      }
    } else {
      guard p.output_ref.is_empty() &&
        p.output_digest.is_empty() &&
        p.output_text.is_empty() else {
        raise CollaborationError(
          "Failed participant must not claim a successful contribution",
        )
      }
    }
  }
  let expected = collected_result(
    saved,
    digest(source_packet(saved)),
    participants,
  )
  guard result == expected &&
    bytes == @utf8.encode(expected.stringify(indent=2)) else {
    raise CollaborationError(
      "Retained result bytes do not match this captured revision",
    )
  }
  {
    ..@contract.empty_work(saved.draft.draft_id, saved.revision),
    status: if participants.all(p => p.status == "completed") {
      "completed"
    } else {
      "partial"
    },
    detail: "Read-only historical dossier. Contributions and failures are retained exactly. Inspecting or downloading does not run work or submit to Book.",
    participants,
    result_digest: digest(bytes),
    result_text: text_bytes(bytes),
    review_status: "pending_review",
  }
}

///|
async fn Store::retained_review(
  self : Store,
  saved : @contract.SavedDraft,
  work : @contract.OneoffWork,
  version : Int,
) -> (@review.ConversationReviewBundle, Bytes) {
  guard version >= 0 && version <= 100 else {
    raise CollaborationError("Select a retained review version from 0 to 100")
  }
  let bytes = outcome_bytes(
    self.work_root(saved),
    "review/" + version.to_string() + ".json",
    2097152,
  )
  let bundle = @review.reimport_review_bundle(
    text_bytes(bytes),
    @utf8.encode(work.result_text),
  )
  let initial = result_bundle(saved, work)
  guard { ..bundle, decision_receipts: [], } == initial &&
    bytes ==
    @utf8.encode(@review.serialize_review_bundle(bundle, work.result_digest)) else {
    raise CollaborationError("Retained review assignments changed")
  }
  if version == 0 {
    guard bundle == initial else {
      raise CollaborationError("Initial retained review changed")
    }
  }
  (bundle, bytes)
}

///|
async fn Store::retained_review_versions(
  self : Store,
  saved : @contract.SavedDraft,
) -> Array[Int] {
  let names = outcome_children(self.work_root(saved) + "/review", 303)
  let versions : Array[Int] = []
  for version in 0..<=100 {
    let name = version.to_string() + ".json"
    if names.contains(name) {
      guard versions.length() == version else {
        raise CollaborationError(
          "Retained review history has a missing version",
        )
      }
      versions.push(version)
    }
  }
  guard !versions.is_empty() else {
    raise CollaborationError("Retained result review history is missing")
  }
  for name in names {
    guard versions.any(v => {
      name == v.to_string() + ".json" ||
      (
        v > 0 &&
        (
          name == v.to_string() + "-events.json" ||
          name == v.to_string() + "-record.json"
        )
      )
    }) else {
      raise CollaborationError("Unexpected retained review entry")
    }
  }
  versions
}

///|
fn outcome_review_status(bundle : @review.ConversationReviewBundle) -> String {
  if bundle.decision_receipts.any(r => r.decision == "defer") {
    "deferred"
  } else {
    @review.review_status(bundle)
  }
}

///|
pub fn outcome_request_key(request : Request) -> @contract.OutcomeKey raise {
  let key : @contract.OutcomeKey = @json.from_json(
    request.payload.unwrap_or(Json::null()),
  )
  guard key.draft_id == request.draft_id &&
    key.revision == request.revision &&
    @contract.safe_id(key.draft_id) &&
    @contract.safe_id(key.revision) &&
    key.review_version >= 0 &&
    key.review_version <= 100 &&
    key.result_digest.length() == 71 &&
    key.result_digest.has_prefix("sha256:") &&
    key.review_digest.length() == 71 &&
    key.review_digest.has_prefix("sha256:") else {
    raise CollaborationError(
      "Choose the exact retained result and review version before exporting",
    )
  }
  key
}
