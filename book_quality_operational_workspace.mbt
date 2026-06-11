///|
async fn write_default_operational_book_workspace(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  summary : String,
  focus : Array[String],
) -> Unit {
  let root = @moonbook.workspace_root(entry)
  write_text_file(
    @book_quality.workspace_path(root, @book_quality.wiki_index_path()),
    @book_quality.operational_index(entry.id, root, title, summary, focus),
  )
  write_text_file(
    @book_quality.workspace_path(
      root, "raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md",
    ),
    @book_quality.operational_contract(title),
  )
  write_text_file(
    @book_quality.workspace_path(root, "wiki/operations/review-policy.md"),
    @book_quality.operational_review_policy(title),
  )
  write_text_file(
    @book_quality.workspace_path(root, "wiki/history/journey.md"),
    @book_quality.operational_journey(title),
  )
  write_text_file(
    @book_quality.workspace_path(root, "skills/operational-keeper/SKILL.md"),
    @book_quality.operational_skill(
      title,
      @skill_quality.exploration_quality_contract_section(),
    ),
  )
  write_text_file(
    @book_quality.workspace_path(root, @book_quality.projection_state_path()),
    @book_quality.operational_ui_state(entry.id, title, summary),
  )
  let html = @book_quality.operational_site(root, title, summary)
  write_text_file(@book_quality.workspace_path(root, "book/Home.html"), html)
  write_text_file(
    @book_quality.workspace_path(root, @book_quality.generated_site_path()),
    html,
  )
}
