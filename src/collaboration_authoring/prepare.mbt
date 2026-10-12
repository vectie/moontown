///|
async fn Store::previous_prepared(
  self : Store,
  saved : @contract.SavedDraft,
) -> @contract.SavedDraft? {
  let mut revision = saved.previous_revision
  let visited : Array[String] = []
  while !revision.is_empty() {
    guard visited.length() < 64 && !visited.contains(revision) else {
      raise CollaborationError("Draft history is too long or invalid")
    }
    visited.push(revision)
    let prior = self.load_revision(saved.draft.draft_id, revision)
    match
      kind(
        self.draft_root(saved.draft.draft_id) +
        "/" +
        revision_prefix(prior) +
        "prepared.json",
      ) {
      Some(Regular) => return Some(prior)
      None => ()
      _ => raise CollaborationError("Unsafe prepared history")
    }
    revision = prior.previous_revision
  }
  None
}

///|
async fn Store::prepare_revision(
  self : Store,
  saved : @contract.SavedDraft,
) -> @contract.Prepared {
  let root = self.draft_root(saved.draft.draft_id)
  let prefix = revision_prefix(saved)
  let packet = source_packet(saved)
  let handoff = civic_handoff(saved)
  let mut bundle = draft_bundle(saved, packet)
  let artifacts : Array[@contract.Artifact] = []
  if self.previous_prepared(saved) is Some(prior) {
    let previous = self.verify_prepared(prior)
    for artifact in previous.artifacts {
      artifacts.push(artifact)
    }
    let prior_prefix = revision_prefix(prior)
    bundle = @review.supersede_review_bundle(
      @utf8.decode(
        read_bytes(root + "/" + prior_prefix + "review-bundle.json", 1048576),
      ),
      previous_bundle_ref=prior_prefix + "review-bundle.json",
      previous_source_bytes=read_bytes(
        root + "/" + prior_prefix + "source-packet.json",
        1048576,
      ),
      next_bundle=bundle,
      next_source_bytes=packet,
    )
  }
  let files : Array[(String, Bytes)] = [
    (prefix + "source-packet.json", packet),
    (
      prefix + "handoff.json",
      @utf8.encode(handoff.to_json().stringify(indent=2)),
    ),
    (
      prefix + "review-bundle.json",
      @utf8.encode(@review.serialize_review_bundle(bundle, digest(packet))),
    ),
  ]
  for p in saved.draft.participants {
    files.push(
      (
        prefix + "briefs/" + p.book_id + ".md",
        @utf8.encode(participant_brief(saved, p)),
      ),
    )
  }
  for s in saved.sources {
    files.push(
      (
        prefix + s.artifact_ref,
        read_bytes(root + "/" + prefix + s.artifact_ref, 1048576),
      ),
    )
  }
  for (path, bytes) in files {
    write_bytes(root + "/" + path, bytes)
    artifacts.push({ path, digest: digest(bytes), size_bytes: bytes.length(), })
  }
  guard artifacts.length() <= 2048 &&
    artifacts.fold(init=0, (total, a) => total + a.size_bytes) <= 33554432 else {
    raise CollaborationError(
      "Portable revision history exceeds 32 MiB; reuse as a new draft",
    )
  }
  let prepared : @contract.Prepared = {
    contract_version: "moontown.collaboration-prepared.v1",
    draft_id: saved.draft.draft_id,
    revision: saved.revision,
    review_status: "pending_review",
    artifacts,
  }
  write_bytes(
    root + "/" + prefix + "prepared.json",
    @utf8.encode(prepared.to_json().stringify(indent=2)),
  )
  prepared
}

///| Every constituent is hashed on prepare retry, reopen, and export. Checking

///|
/// only the review bundle's main packet would not detect a replaced snapshot.
async fn Store::verify_prepared(
  self : Store,
  saved : @contract.SavedDraft,
) -> @contract.Prepared {
  let root = self.draft_root(saved.draft.draft_id)
  let prefix = revision_prefix(saved)
  let json = @json.parse(
    @utf8.decode(read_bytes(root + "/" + prefix + "prepared.json", 1048576)),
  )
  let prepared : @contract.Prepared = @json.from_json(json)
  guard prepared.to_json() == json &&
    prepared.draft_id == saved.draft.draft_id &&
    prepared.revision == saved.revision &&
    prepared.contract_version == "moontown.collaboration-prepared.v1" &&
    prepared.review_status == "pending_review" else {
    raise CollaborationError("Prepared manifest identity changed")
  }
  let paths : Array[String] = []
  for artifact in prepared.artifacts {
    guard @contract.safe_source_path(artifact.path) &&
      artifact.path.has_prefix("revisions/") &&
      !paths.contains(artifact.path) else {
      raise CollaborationError("Unsafe or duplicate prepared artifact")
    }
    paths.push(artifact.path)
    let path = root + "/" + artifact.path
    directory(path[:path.rev_find("/").unwrap()].to_owned(), false)
    let bytes = read_bytes(path, 1048576)
    guard digest(bytes) == artifact.digest &&
      bytes.length() == artifact.size_bytes else {
      raise CollaborationError("Prepared source or artifact bytes have changed")
    }
  }
  for s in saved.sources {
    guard paths.contains(prefix + s.artifact_ref) else {
      raise CollaborationError("Prepared manifest omits a captured source")
    }
  }
  let packet = read_bytes(root + "/" + prefix + "source-packet.json", 1048576)
  guard packet == source_packet(saved) else {
    raise CollaborationError(
      "Prepared packet does not match its immutable draft",
    )
  }
  let handoff = read_bytes(root + "/" + prefix + "handoff.json", 1048576)
  guard handoff ==
    @utf8.encode(civic_handoff(saved).to_json().stringify(indent=2)) else {
    raise CollaborationError("Prepared handoff changed")
  }
  let bundle = @review.reimport_review_bundle(
    @utf8.decode(
      read_bytes(root + "/" + prefix + "review-bundle.json", 1048576),
    ),
    packet,
  )
  guard bundle.decision_receipts.is_empty() &&
    bundle.source_revision_id == saved.revision else {
    raise CollaborationError("Prepared plan may not acquire decision receipts")
  }
  let mut expected = draft_bundle(saved, packet)
  let mut history_count = 0
  if self.previous_prepared(saved) is Some(prior) {
    let previous = self.verify_prepared(prior)
    history_count = previous.artifacts.length()
    for a in previous.artifacts {
      guard prepared.artifacts.contains(a) else {
        raise CollaborationError("Prepared history changed")
      }
    }
    let prior_prefix = revision_prefix(prior)
    expected = @review.supersede_review_bundle(
      @utf8.decode(
        read_bytes(root + "/" + prior_prefix + "review-bundle.json", 1048576),
      ),
      previous_bundle_ref=prior_prefix + "review-bundle.json",
      previous_source_bytes=read_bytes(
        root + "/" + prior_prefix + "source-packet.json",
        1048576,
      ),
      next_bundle=expected,
      next_source_bytes=packet,
    )
  }
  guard bundle == expected &&
    prepared.artifacts.length() ==
    history_count +
    saved.sources.length() +
    saved.draft.participants.length() +
    3 else {
    raise CollaborationError("Prepared review assignments or manifest changed")
  }
  for required in ["source-packet.json", "handoff.json", "review-bundle.json"] {
    guard paths.contains(prefix + required) else {
      raise CollaborationError("Prepared manifest is incomplete")
    }
  }
  for p in saved.draft.participants {
    let path = prefix + "briefs/" + p.book_id + ".md"
    guard paths.contains(path) &&
      read_bytes(root + "/" + path, 1048576) ==
      @utf8.encode(participant_brief(saved, p)) else {
      raise CollaborationError("Prepared participant brief changed")
    }
  }
  prepared
}

///|
/// This only writes local authoring artifacts; it never invokes civic runtime.
pub async fn Store::prepare(
  self : Store,
  id : String,
  revision : String,
) -> @contract.Prepared {
  self.locked(() => {
    let saved = self.load_revision(id, revision)
    let path = self.draft_root(id) +
      "/" +
      revision_prefix(saved) +
      "prepared.json"
    if kind(path) is None {
      self.prepare_revision(saved)
    } else {
      self.verify_prepared(saved)
    }
  })
}

///|
pub async fn Store::artifact(
  self : Store,
  id : String,
  revision : String,
  path : String,
) -> Bytes {
  self.locked(() => {
    let saved = self.load_revision(id, revision)
    let prepared = self.verify_prepared(saved)
    guard prepared.artifacts.any(a => a.path == path) else {
      raise CollaborationError("Artifact is not in this prepared revision")
    }
    read_bytes(self.draft_root(id) + "/" + path, 1048576)
  })
}
