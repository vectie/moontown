///|
fn archive_pdf_evidence_watch_catalog_entry(
  catalog : Array[@moonbook.BookCatalogEntry],
  book_id : String,
  reason : String,
) -> Array[@moonbook.BookCatalogEntry] {
  let updated : Array[@moonbook.BookCatalogEntry] = []
  for entry in catalog {
    if entry.id == book_id {
      updated.push(
        @moonbook.BookCatalogEntry::new(
          id=entry.id,
          name=entry.name,
          purpose="\{entry.purpose}\n\nArchived: \{reason}",
          workspace_root=entry.workspace_root,
          memory_scope=entry.memory_scope,
          tags=ensure_pdf_evidence_watch_archive_tags(entry.tags),
          skills=entry.skills,
        ),
      )
    } else {
      updated.push(entry)
    }
  }
  updated
}

///|
fn ensure_pdf_evidence_watch_archive_tags(
  tags : Array[String],
) -> Array[String] {
  let updated : Array[String] = []
  for tag in tags {
    if !updated.contains(tag) {
      updated.push(tag)
    }
  }
  for tag in ["archived", "hidden", "internal"] {
    if !updated.contains(tag) {
      updated.push(tag)
    }
  }
  updated
}
