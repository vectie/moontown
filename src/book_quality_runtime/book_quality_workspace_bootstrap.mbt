///|
async fn bootstrap_canonical_registered_book_workspaces(
  book_catalog_path : String,
) -> String {
  let operational = bootstrap_default_operational_books(book_catalog_path)
  ignore(@cookbook_runtime.bootstrap_moontown_cookbook(book_catalog_path~))
  ignore(bootstrap_moontown_planbook(book_catalog_path~))
  ignore(bootstrap_wenyu_game_design_course_book(book_catalog_path~))
  ignore(@civic_runtime.bootstrap_wenyu_civic_workspaces(book_catalog_path~))
  "Bootstrapped canonical registered MoonBook workspaces: operational=\{operational}, cookbook=1, planbook=1, course=1, civic=\{@civic.wenyu_civic_services().length()}."
}
