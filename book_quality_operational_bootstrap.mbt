///|
async fn bootstrap_default_operational_books(book_catalog_path : String) -> Int {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let mut count = 0
  for entry in catalog {
    match entry.id {
      "coding" => {
        write_default_operational_book_workspace(
          entry,
          "Coding Harness Book",
          "This MoonBook stores coding harness memory, review policy, repo-quality notes, and execution boundaries. It is an operational planning/memory book, not a generic research book.",
          ["repo-quality", "review", "implementation memory"],
        )
        count += 1
      }
      "finance" => {
        write_default_operational_book_workspace(
          entry,
          "Finance Operations Book",
          "This MoonBook stores private finance workflow memory, ledger procedures, review gates, and daily operating notes. It contains no seeded personal financial data.",
          ["ledger hygiene", "planning", "private review"],
        )
        count += 1
      }
      _ => ()
    }
  }
  count
}
