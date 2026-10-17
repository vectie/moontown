///|
/// Select inclusive, one-based lines from an imported page without retyping a
/// quote. Newline bytes are preserved. This edits a notebook, not a saved draft.
///
/// ```mbt check
/// test {
///   let page : MaterialPage = {
///     book_id: "a",
///     book_title: "A",
///     source_path: "raw/a.md",
///     digest: "sha256:0000000000000000000000000000000000000000000000000000000000000000",
///     size_bytes: 6,
///     text: "first\n",
///   }
///   let notebook = empty_material_notebook("inquiry", [page])
///   let selected = notebook.select_lines(
///     "a", "raw/a.md", 1, 1, "Observed", "Recheck",
///   )
///   assert_eq(selected.excerpts[0].quote, "first")
///   assert_true(selected.remove_excerpt(1).excerpts.is_empty())
/// }
/// ```
pub fn MaterialNotebook::select_lines(
  self : MaterialNotebook,
  book_id : String,
  source_path : String,
  first : Int,
  last : Int,
  observation : String,
  challenge : String,
) -> MaterialNotebook raise {
  self.validate_pages()
  let pages = self.pages.filter(p => {
    p.book_id == book_id && p.source_path == source_path
  })
  guard pages.length() == 1 else {
    fail("Select an imported Book and source path")
  }
  let lines = pages[0].text.split("\n").to_array()
  guard first >= 1 && last >= first && last <= lines.length() else {
    fail("Use an inclusive one-based line range within the imported page")
  }
  let quote = lines[first - 1:last].map(line => line.to_owned()).join("\n")
  guard !quote.trim().is_empty() && quote.length() <= 2000 else {
    fail("Select a nonblank passage of at most 2000 characters")
  }
  guard !observation.trim().is_empty() &&
    !challenge.trim().is_empty() &&
    observation.length() <= 4000 &&
    challenge.length() <= 4000 else {
    fail("Write an observation and challenge, at most 4000 characters each")
  }
  guard self.excerpts.length() < 16 else {
    fail("Keep at most 16 excerpts; remove one first")
  }
  guard !self.excerpts.any(e => {
    e.book_id == book_id && e.source_path == source_path && e.quote == quote
  }) else {
    fail("This exact passage is already selected")
  }
  {
    ..self,
    excerpts: self.excerpts +
    [{ book_id, source_path, quote, observation, challenge, }],
  }
}

///|
/// Remove one selected passage by its displayed one-based position. Imported
/// pages and all other authored fields remain unchanged.
pub fn MaterialNotebook::remove_excerpt(
  self : MaterialNotebook,
  position : Int,
) -> MaterialNotebook raise {
  self.validate_pages()
  guard position >= 1 && position <= self.excerpts.length() else {
    fail("Select an existing one-based excerpt position")
  }
  let excerpts : Array[MaterialExcerpt] = []
  for index, excerpt in self.excerpts {
    if index != position - 1 {
      excerpts.push(excerpt)
    }
  }
  { ..self, excerpts, }
}
