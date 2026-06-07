///|
async fn build_book_quality_audit(
  book_catalog_path : String,
  snapshot_path : String,
) -> BookQualityAudit {
  let catalog = quality_catalog_with_runtime_books(
    @moonbook.load_or_create_catalog(path=book_catalog_path),
    snapshot_path,
  )
  let scores : Array[BookQualityScore] = []
  let review_result_dir = book_quality_review_result_dir_for_snapshot(
    snapshot_path,
  )
  for entry in catalog {
    scores.push(score_book(entry, review_result_dir))
  }
  book_quality_audit_from_scores(book_catalog_path, scores)
}

///|
fn book_quality_audit_from_scores(
  book_catalog_path : String,
  scores : Array[BookQualityScore],
) -> BookQualityAudit {
  let weakest = weakest_score(scores)
  {
    generated_at: "runtime",
    catalog_path: book_catalog_path,
    total: scores.length(),
    world_class_count: scores.filter(fn(item) { item.score >= 90 }).length(),
    ready_count: scores.filter(fn(item) { item.ready }).length(),
    weakest_book_id: match weakest {
      Some(score) => score.book_id
      None => ""
    },
    weakest_score: match weakest {
      Some(score) => score.score
      None => 0
    },
    scores,
  }
}

///|
async fn quality_catalog_with_runtime_books(
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
) -> Array[@moonbook.BookCatalogEntry] {
  let merged : Array[@moonbook.BookCatalogEntry] = []
  let ignored_ids : Array[String] = []
  for entry in catalog {
    if book_quality_active_catalog_entry(entry) {
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
        if book_quality_active_catalog_entry(entry) &&
          !merged.any(fn(item) { item.id == entry.id }) {
          merged.push(entry)
        }
      }
    None => ()
  }
  merged
}

///|
fn book_quality_catalog_entry_from_runtime_book(
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
