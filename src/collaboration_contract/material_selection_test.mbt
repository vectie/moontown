///|
test "select inclusive lines preserves exact text and notebook fields" {
  let original = notebook_fixture()
  let notebook = { ..original, excerpts: [], }
  let selected = notebook.select_lines(
    "water", "raw/notes.md", 1, 2, "Possible exposure", "Measure rainfall",
  )
  assert_eq(selected.excerpts[0].quote, "# Observation\nDry soil.")
  assert_eq(selected.pages, notebook.pages)
  assert_eq(selected.question, notebook.question)
  assert_eq(notebook.excerpts.length(), 0)
  let selected = selected.select_lines(
    "forest", "raw/notes.md", 2, 2, "Compare dry ground", "Check irrigation",
  )
  assert_eq(selected.draft().participants.length(), 2)
  let removed = selected.remove_excerpt(1)
  assert_eq(removed.excerpts.length(), 1)
  assert_eq(removed.excerpts[0].book_id, "forest")
  assert_eq(selected.excerpts.length(), 2)
}

///|
test "line selection bounds duplicate and blank notes refuse without mutation" {
  let notebook = { ..notebook_fixture(), excerpts: [], }
  for (first, last) in [(0, 1), (2, 1), (1, 99), (3, 3)] {
    try
      notebook.select_lines(
        "water", "raw/notes.md", first, last, "Observe", "Challenge",
      )
    catch {
      _ => ()
    } noraise {
      _ => fail("range should be rejected")
    }
  }
  try
    notebook.select_lines("water", "raw/notes.md", 2, 2, "", "Challenge")
  catch {
    _ => ()
  } noraise {
    _ => fail("empty note should fail")
  }
  let selected = notebook.select_lines(
    "water", "raw/notes.md", 2, 2, "Observe", "Challenge",
  )
  try
    selected.select_lines("water", "raw/notes.md", 2, 2, "Other", "Other")
  catch {
    _ => ()
  } noraise {
    _ => fail("duplicate should fail")
  }
  for position in [0, 2] {
    try selected.remove_excerpt(position) catch {
      _ => ()
    } noraise {
      _ => fail("invalid position")
    }
  }
  assert_eq(notebook.excerpts.length(), 0)
}

///|
test "line selection preserves CRLF and Unicode" {
  let text = "測定\r\n東京,水\r\n"
  let notebook = notebook_fixture()
  let page = {
    ..notebook.pages[0],
    text,
    size_bytes: @utf8.encode(text).length(),
  }
  let notebook = { ..notebook, pages: [page], excerpts: [], }
  let selected = notebook.select_lines(
    "water", "raw/notes.md", 1, 2, "Observe", "Challenge",
  )
  assert_eq(selected.excerpts[0].quote, "測定\r\n東京,水\r")
}
