///|
test "context preserves exact windows and feeds passage selection" {
  let text = "before\r\nmatch here\r\nafter\r\nlast"
  let page : MaterialPage = {
    book_id: "a",
    book_title: "A",
    source_path: "raw/a.md",
    digest: "sha256:" + "0".repeat(64),
    size_bytes: @utf8.encode(text).length(),
    text,
  }
  let notebook = empty_material_notebook("inquiry", [page])
  let result = notebook.find_context("match", 1)
  assert_eq(result.search.matched_lines, 1)
  let window = result.windows[0]
  assert_eq(window.first_line, 1)
  assert_eq(window.last_line, 3)
  assert_eq(window.text, "before\r\nmatch here\r\nafter\r")
  assert_eq(window.match_line.digest, page.digest)
  let selected = notebook.select_lines(
    "a",
    "raw/a.md",
    window.first_line,
    window.last_line,
    "Observe",
    "Challenge",
  )
  assert_eq(selected.excerpts[0].quote, window.text)
  assert_true(notebook.excerpts.is_empty())
  assert_eq(notebook.find_context("before", 10).windows[0].last_line, 4)
  assert_eq(notebook.find_context("last", 0).windows[0].text, "last")
  assert_true(notebook.find_context("MATCH", 1).windows.is_empty())
}

///|
test "context shares search truncation and validates neighbor count" {
  let text = "match\n".repeat(105)
  let page : MaterialPage = {
    book_id: "a",
    book_title: "A",
    source_path: "raw/a.md",
    digest: "sha256:" + "0".repeat(64),
    size_bytes: @utf8.encode(text).length(),
    text,
  }
  let notebook = empty_material_notebook("inquiry", [page])
  let result = notebook.find_context("match", 0)
  assert_eq(result.search.matched_lines, 105)
  assert_eq(result.windows.length(), 100)
  assert_true(result.search.truncated)
  for neighbors in [-1, 11] {
    try notebook.find_context("match", neighbors) catch {
      _ => ()
    } noraise {
      _ => fail("invalid neighbor count accepted")
    }
  }
}
