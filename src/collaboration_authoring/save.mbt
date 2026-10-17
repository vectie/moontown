///|
async fn Store::capture(
  self : Store,
  draft : @contract.Draft,
) -> Array[(@contract.SourceSnapshot, Bytes)] {
  guard @contract.safe_id(draft.draft_id) &&
    draft.participants.length() <= 16 &&
    @utf8.encode(draft.to_json().stringify()).length() <= 65536 else {
    raise CollaborationError("Draft exceeds identity or size limits")
  }
  let catalog = if draft.participants.is_empty() {
    []
  } else {
    @moonbook.load_catalog_file(self.catalog_path).unwrap_or([])
  }
  let result : Array[(@contract.SourceSnapshot, Bytes)] = []
  let ids : Array[String] = []
  let mut total = 0
  for participant in draft.participants {
    guard @contract.safe_id(participant.book_id) &&
      !ids.contains(participant.book_id) else {
      raise CollaborationError("Duplicate or invalid Book ID")
    }
    ids.push(participant.book_id)
    guard @moonbook.find_catalog_entry(catalog, participant.book_id)
      is Some(book) else {
      raise CollaborationError("Selected Book is not in the existing catalog")
    }
    guard participant.source_paths.length() <= 16 else {
      raise CollaborationError("Choose at most 16 files per Book")
    }
    let selected : Array[String] = []
    for path in participant.source_paths {
      guard @contract.safe_source_path(path) && !selected.contains(path) else {
        raise CollaborationError(
          "Source paths must be unique, relative, and non-hidden",
        )
      }
      selected.push(path)
      directory(book.workspace_root, false)
      let full = book.workspace_root + "/" + path
      directory(full[:full.rev_find("/").unwrap()].to_owned(), false)
      let bytes = read_bytes(full, 1048576)
      total += bytes.length()
      guard total <= 8388608 else {
        raise CollaborationError("Selected sources exceed 8 MiB")
      }
      result.push(
        (
          {
            book_id: book.id,
            book_title: book.name,
            source_path: path,
            artifact_ref: "sources/" + book.id + "/" + path,
            digest: digest(bytes),
            size_bytes: bytes.length(),
          },
          bytes,
        ),
      )
    }
  }
  result
}

///| Optimistic revision guard makes retries safe without overwriting newer edits.

///|
/// Incomplete assignments can be saved; selected source files must exist.
pub async fn Store::save(
  self : Store,
  draft : @contract.Draft,
  expected_revision : String,
  recorded_at : String,
) -> @contract.SavedDraft {
  self.save_internal(draft, expected_revision, recorded_at)
}

///|
async fn Store::save_internal(
  self : Store,
  draft : @contract.Draft,
  expected_revision : String,
  recorded_at : String,
  claim_challenge? : @contract.ClaimChallenge,
  material_notebook? : @contract.MaterialNotebook,
) -> @contract.SavedDraft {
  self.locked(() => {
    let current = self.current_revision(draft.draft_id)
    let captured = self.capture(draft)
    if claim_challenge is Some(input) {
      verify_claim_capture(input, captured)
    }
    if material_notebook is Some(input) {
      verify_material_capture(input, captured)
    }
    let sources = captured.map(pair => pair.0)
    if !current.is_empty() {
      let old = self.load_revision(draft.draft_id, current)
      // Includes a lost-response retry. Only exact bytes and authored fields match.
      if old.draft == draft &&
        old.sources == sources &&
        (
          expected_revision == current ||
          expected_revision == old.previous_revision
        ) {
        return old
      }
    }
    guard current == expected_revision else {
      raise CollaborationError(
        "This draft changed elsewhere. Reopen it before saving",
      )
    }
    let partial : @contract.SavedDraft = {
      contract_version: "moontown.collaboration-draft.v1",
      draft,
      revision: "",
      previous_revision: current,
      recorded_at,
      sources,
    }
    let saved = { ..partial, revision: revision_for(partial), }
    let root = self.draft_root(draft.draft_id)
    let revision_root = root + "/revisions/" + saved.revision
    directory(revision_root, true)
    for (source, bytes) in captured {
      write_bytes(revision_root + "/" + source.artifact_ref, bytes)
    }
    write_bytes(
      revision_root + "/draft.json",
      @utf8.encode(saved.to_json().stringify(indent=2)),
    )
    let temporary = root + "/current.next"
    match kind(temporary) {
      Some(Regular) => @fs.remove(temporary)
      None => ()
      _ => raise CollaborationError("Unsafe draft pointer")
    }
    @fs.write_file(
      temporary,
      saved.revision,
      create_mode=CreateNew,
      permission=0o600,
      sync=Full,
    )
    @fs.rename(temporary, root + "/current", replace=true)
    saved
  })
}

///| Reuse copies only authored fields into a fresh ID. No artifact, review,

///|
/// decision, or schedule state is copied, and save recaptures current sources.
pub async fn Store::reuse(
  self : Store,
  from_id : String,
  source_revision : String,
  new_id : String,
  recorded_at : String,
) -> @contract.SavedDraft {
  guard @contract.safe_id(source_revision) else {
    raise CollaborationError("Reuse requires the exact saved revision")
  }
  let source = self.load(from_id, revision=source_revision)
  guard new_id != from_id else {
    raise CollaborationError("Reuse requires a new draft ID")
  }
  self.save({ ..source.draft, draft_id: new_id, }, "", recorded_at)
}
