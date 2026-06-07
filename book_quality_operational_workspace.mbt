///|
async fn write_default_operational_book_workspace(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  summary : String,
  focus : Array[String],
) -> Unit {
  let root = @moonbook.workspace_root(entry)
  write_text_file(
    book_quality_workspace_path(root, book_quality_wiki_index_path()),
    default_operational_index(entry, title, summary, focus),
  )
  write_text_file(
    book_quality_workspace_path(
      root, "raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md",
    ),
    default_operational_contract(title),
  )
  write_text_file(
    book_quality_workspace_path(root, "wiki/operations/review-policy.md"),
    default_operational_review_policy(title),
  )
  write_text_file(
    book_quality_workspace_path(root, "wiki/history/journey.md"),
    default_operational_journey(title),
  )
  write_text_file(
    book_quality_workspace_path(root, "skills/operational-keeper/SKILL.md"),
    default_operational_skill(title),
  )
  write_text_file(
    book_quality_workspace_path(root, book_quality_projection_state_path()),
    default_operational_ui_state(entry, title, summary),
  )
  let html = default_operational_site(entry, title, summary)
  write_text_file(book_quality_workspace_path(root, "book/Home.html"), html)
  write_text_file(
    book_quality_workspace_path(root, book_quality_generated_site_path()),
    html,
  )
}
