///|
pub fn domain_for_book(entry : @moonbook.BookCatalogEntry) -> @core.WorkDomain {
  match entry.id {
    "finance" => Finance
    "coding" => Coding
    _ => Operations
  }
}

///|
pub fn domain_for_provider_overview(book : @core.BookRef) -> @core.WorkDomain {
  match book.id {
    "finance" => Finance
    _ => Coding
  }
}

///|
pub fn domain_for_book_task(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
) -> @core.WorkDomain {
  match task.kind {
    "standing-watch" => Research
    "civic-service-workflow" => SocialExperiment
    "code-patch" | "test-fix" | "projection-schema" => Coding
    "image-asset" => Coding
    "implementation-backlog" => Operations
    _ => domain_for_book(entry)
  }
}
