///|
/// Read selected registered Book text without creating any draft or Book state.
/// Full files are imported, at most 64 KiB each and 256 KiB total, with exact
/// byte identities. The notebook starts with no excerpts or proposed question.
pub async fn Store::import_material(
  self : Store,
  draft_id : String,
  selections : Array[@contract.MaterialSelection],
) -> @contract.MaterialNotebook {
  let count = selections.fold(init=0, (n, s) => n + s.source_paths.length())
  guard selections.length() > 0 &&
    selections.length() <= 16 &&
    count > 0 &&
    count <= 16 &&
    selections.all(s => !s.source_paths.is_empty()) else {
    raise CollaborationError("Choose 1–16 source files from registered Books")
  }
  let draft = {
    ..@contract.empty_draft(draft_id),
    participants: selections.map(s => {
      book_id: s.book_id,
      source_paths: s.source_paths,
      focus_area: "",
      perspective: "",
      contribution: "",
      next_artifact: "",
    }),
  }
  let captured = self.capture(draft)
  let pages : Array[@contract.MaterialPage] = []
  let mut total = 0
  for (snapshot, bytes) in captured {
    total += bytes.length()
    guard bytes.length() <= 65536 && total <= 262144 else {
      raise CollaborationError(
        "Import text files up to 64 KiB each and 256 KiB total",
      )
    }
    let text = @utf8.decode(bytes) catch {
      _ => raise CollaborationError("Material notebook accepts UTF-8 text only")
    }
    guard !text.contains("\u0000") else {
      raise CollaborationError(
        "Material notebook cannot import NUL-containing binary files",
      )
    }
    pages.push({
      book_id: snapshot.book_id,
      book_title: snapshot.book_title,
      source_path: snapshot.source_path,
      digest: snapshot.digest,
      size_bytes: bytes.length(),
      text,
    })
  }
  let notebook = @contract.empty_material_notebook(draft_id, pages)
  notebook.validate_pages()
  notebook
}

///|
/// Verify the exact buffers persisted by save_internal, without a second read.
/// Unselected imported pages are not evidence and do not block this draft.
fn verify_material_capture(
  notebook : @contract.MaterialNotebook,
  captured : Array[(@contract.SourceSnapshot, Bytes)],
) -> Unit raise {
  for (snapshot, bytes) in captured {
    let pages = notebook.pages.filter(p => {
      p.book_id == snapshot.book_id && p.source_path == snapshot.source_path
    })
    guard pages.length() == 1 &&
      pages[0].digest == snapshot.digest &&
      pages[0].size_bytes == bytes.length() &&
      @utf8.encode(pages[0].text) == bytes else {
      raise CollaborationError(
        "Selected material changed or was edited: " +
        snapshot.book_id +
        "/" +
        snapshot.source_path +
        ". Import again and review the current passages before saving",
      )
    }
  }
}

///|
/// Save a new unrun inquiry through the ordinary immutable revision store.
/// Exact retries reuse the existing revision. New notebook edits require a new
/// draft ID; edit an already saved draft through the ordinary composer instead.
pub async fn Store::save_material_notebook(
  self : Store,
  notebook : @contract.MaterialNotebook,
  recorded_at : String,
) -> @contract.SavedDraft {
  let draft = notebook.draft()
  self.save_internal(draft, "", recorded_at, material_notebook=notebook)
}
