///|
pub fn domain_for_book(entry : @moonbook.BookCatalogEntry) -> @core.WorkDomain {
  match entry.id {
    "finance" => @core.WorkDomain::Finance
    "coding" => @core.WorkDomain::Coding
    _ => @core.WorkDomain::Operations
  }
}

///|
pub fn domain_for_provider_overview(book : @core.BookRef) -> @core.WorkDomain {
  match book.id {
    "finance" => @core.WorkDomain::Finance
    _ => @core.WorkDomain::Coding
  }
}

///|
pub fn domain_for_book_task(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
) -> @core.WorkDomain {
  match task.kind {
    "standing-watch" => @core.WorkDomain::Research
    "civic-service-workflow" => @core.WorkDomain::SocialExperiment
    "code-patch" | "test-fix" | "projection-schema" => @core.WorkDomain::Coding
    "image-asset" => @core.WorkDomain::Coding
    "implementation-backlog" => @core.WorkDomain::Operations
    _ => domain_for_book(entry)
  }
}
