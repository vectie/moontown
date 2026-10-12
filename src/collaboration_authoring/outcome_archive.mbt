///|
fn outcome_add_file(
  files : Array[(String, Bytes)],
  path : String,
  bytes : Bytes,
) -> Unit raise {
  guard @contract.safe_source_path(path) &&
    !files.any(f => f.0 == path) &&
    files.length() < 2048 &&
    files.fold(init=bytes.length(), (n, f) => n + f.1.length()) <= 33554432 else {
    raise CollaborationError(
      "Retained dossier exceeds the 32 MiB / 2048 file limit or has an invalid path",
    )
  }
  files.push((path, bytes))
}

///|
fn outcome_summary(
  saved : @contract.SavedDraft,
  work : @contract.OneoffWork,
  review_status : String,
) -> String {
  let sections = [
    "# " + saved.draft.title,
    "Question: " + saved.draft.question,
    "Draft: " +
    saved.draft.draft_id +
    "\nRevision: " +
    saved.revision +
    "\nResult: " +
    work.result_digest,
    "Outcome: " +
    work.status +
    "\nSelected review: " +
    work.review_version.to_string() +
    "\nReview status: " +
    review_status,
    "This is an exact retained dossier, not a new execution or consensus. Review decisions concern the recorded account. Downloading does not submit to Book, establish Book acceptance, activate a capability, call a provider, or schedule work.",
    "## Authored objection\n" + saved.draft.objection,
  ]
  for p in work.participants {
    sections.push(
      "## " +
      p.book_id +
      " · " +
      p.status +
      "\nRun: " +
      p.run_id +
      "\n" +
      p.detail +
      "\n\n" +
      p.output_text,
    )
  }
  sections.push("## Selected review history\n" + work.review_history_text)
  for decision in work.decisions {
    sections.push(
      decision.reviewer_name +
      " (" +
      decision.reviewer_id +
      ") · " +
      decision.decision_id +
      "\n" +
      decision.prompt +
      "\n" +
      decision.decision +
      "\n" +
      decision.rationale,
    )
  }
  sections.push(
    "## Captured sources\n" +
    saved.sources
    .map(s => {
      s.book_id +
      "/" +
      s.source_path +
      " · " +
      s.size_bytes.to_string() +
      " bytes · " +
      s.digest
    })
    .join("\n"),
  )
  sections.join("\n\n") + "\n"
}

///|
async fn Store::outcome_snapshot(
  self : Store,
  key : @contract.OutcomeKey,
) -> (@contract.RetainedOutcome, Bytes) {
  let saved = self.load_revision(key.draft_id, key.revision)
  let work = self.retained_work(saved)
  guard work.result_digest == key.result_digest else {
    raise CollaborationError(
      "Selected retained result changed; reload the outcome library",
    )
  }
  guard key.review_version >= 0 && key.review_version <= 100 else {
    raise CollaborationError("Select an explicit retained review version")
  }
  let history = self.outcome_history(saved, work, key.review_version)
  guard history.reviews[key.review_version].digest == key.review_digest else {
    raise CollaborationError(
      "Selected retained review bytes changed; reload the outcome library",
    )
  }
  let work = history.work
  let review_status = outcome_review_status(history.bundle)
  let files : Array[(String, Bytes)] = []
  outcome_add_file(
    files,
    "README.txt",
    @utf8.encode(
      "MoonTown retained collaboration outcome\n\nStart with SUMMARY.md. result.json is the exact collected dossier. draft.json binds the captured source revision. sources/ retains exact original bytes, including binary files. participants/ retains each attributed terminal receipt and successful UTF-8 contribution. review/ contains exact history only through the explicitly selected review version.\n\nVerify each manifest.json artifact's size and SHA-256 against its raw bytes. The download response's X-Artifact-Digest covers this entire deterministic tar, including the manifest. This is a local integrity record, not a signature or proof of human identity.\n\nCompleted means all participant contributions were retained; partial preserves failed participants without inventing contributions. Pending, rejected and deferred review dossiers can be exported for inspection. No export creates new work, grants acceptance, submits to Book, changes a Book or schedules anything. A separate explicit reviewed-outcome submission uses Book's independent acceptance gates. Reusing a question creates fresh work and does not inherit this outcome or its decisions.\n",
    ),
  )
  outcome_add_file(
    files,
    "SUMMARY.md",
    @utf8.encode(outcome_summary(saved, work, review_status)),
  )
  for (path, bytes) in self.outcome_bound_members(saved, work) {
    outcome_add_file(files, path, bytes)
  }
  for (path, bytes) in history.files {
    outcome_add_file(files, path, bytes)
  }
  outcome_add_file(
    files,
    "review/selected-record.json",
    @utf8.encode(
      @review.project_review_record(history.bundle, work.result_digest, [])
      .to_json()
      .stringify(indent=2),
    ),
  )
  let artifacts : Array[@contract.Artifact] = files.map(pair => {
    path: pair.0,
    digest: digest(pair.1),
    size_bytes: pair.1.length(),
  })
  let manifest : Json = {
    "contract_version": "moontown.retained-outcome-manifest.v1",
    "selection": key.to_json(),
    "outcome_status": work.status,
    "review_status": review_status,
    "artifacts": artifacts.to_json(),
    "book_submission_performed": false,
    "execution_performed": false,
    "integrity": "SHA-256 of exact raw bytes; unsigned local retained evidence. The manifest itself is covered by the archive digest, not recursively listed.",
  }
  let output = @buffer.Buffer()
  tar_file(output, "manifest.json", @utf8.encode(manifest.stringify(indent=2)))
  for (path, bytes) in files {
    tar_file(output, path, bytes)
  }
  for _ in 0..<1024 {
    output.write_byte(b'\x00')
  }
  let bytes = output.to_bytes()
  guard bytes.length() <= 41943040 else {
    raise CollaborationError(
      "Retained archive exceeds the 40 MiB download limit",
    )
  }
  (
    {
      contract_version: "moontown.retained-outcome.v1",
      key,
      saved,
      work,
      review_status,
      reviews: history.reviews,
      artifacts,
      archive_digest: digest(bytes),
      archive_size_bytes: bytes.length(),
    },
    bytes,
  )
}

///|
async fn Store::outcome_bound_members(
  self : Store,
  saved : @contract.SavedDraft,
  work : @contract.OneoffWork,
) -> Array[(String, Bytes)] {
  let root = self.draft_root(saved.draft.draft_id)
  let prefix = revision_prefix(saved)
  let files : Array[(String, Bytes)] = []
  // The store lock coordinates Town writers, not arbitrary external file
  // replacements. Validate these exact buffers against the already pinned
  // snapshot before adding them; archive assembly never reopens them again.
  let draft_bytes = outcome_bytes(root, prefix + "draft.json", 524288)
  guard @json.parse(text_bytes(draft_bytes)) == saved.to_json() else {
    raise CollaborationError(
      "Export member draft identity changed after verification",
    )
  }
  outcome_add_file(files, "draft.json", draft_bytes)
  outcome_add_file(files, "result.json", @utf8.encode(work.result_text))
  for source in saved.sources {
    let bytes = outcome_bytes(root, prefix + source.artifact_ref, 1048576)
    guard bytes.length() == source.size_bytes && digest(bytes) == source.digest else {
      raise CollaborationError(
        "Export member captured source changed after verification",
      )
    }
    outcome_add_file(files, source.artifact_ref, bytes)
  }
  for participant in work.participants {
    let local = "produced/" + participant.book_id + "/"
    let output = "participants/" + participant.book_id + "/"
    let terminal = outcome_bytes(
      self.work_root(saved),
      local + "terminal.json",
      2097152,
    )
    guard @json.parse(text_bytes(terminal)) == participant.to_json() else {
      raise CollaborationError(
        "Export member terminal attribution changed after verification",
      )
    }
    outcome_add_file(files, output + "terminal.json", terminal)
    if participant.status == "completed" {
      let report = outcome_bytes(
        self.work_root(saved),
        local + "report.md",
        1048576,
      )
      guard digest(report) == participant.output_digest &&
        report == @utf8.encode(participant.output_text) else {
        raise CollaborationError(
          "Export member contribution changed after verification",
        )
      }
      outcome_add_file(files, output + "report.md", report)
    }
  }
  files
}

///|
pub async fn Store::inspect_outcome(
  self : Store,
  key : @contract.OutcomeKey,
) -> @contract.RetainedOutcome {
  self.read_locked(() => self.outcome_snapshot(key).0)
}

///|
pub async fn Store::export_outcome(
  self : Store,
  key : @contract.OutcomeKey,
) -> Bytes {
  self.read_locked(() => self.outcome_snapshot(key).1)
}
