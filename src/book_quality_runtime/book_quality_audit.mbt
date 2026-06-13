///|
async fn build_book_quality_audit(
  book_catalog_path : String,
  snapshot_path : String,
) -> @book_quality.BookQualityAudit {
  let catalog = quality_catalog_with_runtime_books(
    @moonbook.load_or_create_catalog(path=book_catalog_path),
    snapshot_path,
  )
  let scores : Array[@book_quality.BookQualityScore] = []
  let review_result_dir = @book_quality.review_result_dir_for_snapshot(
    snapshot_path,
  )
  for entry in catalog {
    scores.push(@book_quality.score_book(entry, review_result_dir))
  }
  @book_quality.audit_from_scores(book_catalog_path, scores)
}

///|
async fn quality_catalog_with_runtime_books(
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
) -> Array[@moonbook.BookCatalogEntry] {
  let merged : Array[@moonbook.BookCatalogEntry] = []
  let ignored_ids : Array[String] = []
  for entry in catalog {
    if @policy.catalog_entry_active(
        entry.id,
        entry.name,
        entry.purpose,
        entry.tags,
      ) {
      merged.push(entry)
    } else {
      ignored_ids.push(entry.id)
    }
  }
  match @storage.load_snapshot_file(snapshot_path) {
    Some(snapshot) =>
      for book in snapshot.town.books {
        if ignored_ids.contains(book.id) {
          continue
        }
        let entry = book_quality_catalog_entry_from_runtime_book(book)
        if @policy.catalog_entry_active(
            entry.id,
            entry.name,
            entry.purpose,
            entry.tags,
          ) &&
          !merged.any(fn(item) { item.id == entry.id }) {
          merged.push(entry)
        }
      }
    None => ()
  }
  merged
}

///|
pub fn book_quality_catalog_entry_from_runtime_book(
  book : @core.BookRef,
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id=book.id,
    name=book.name,
    purpose=book.purpose,
    workspace_root=book.workspace_root,
    memory_scope=book.memory_scope,
    tags=book.tags,
    skills=[],
  )
}
