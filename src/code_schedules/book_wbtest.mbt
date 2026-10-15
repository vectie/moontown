///|
test "desktop schedules resolve the book workspace id without changing existing ids" {
  let book = @moonbook.BookCatalogEntry::new(
    id="coding",
    name="Coding",
    purpose="Development",
    workspace_root="/Users/test/workspace/books/coding",
  )
  assert_eq(
    find_code_schedule_book([book], "book-coding").unwrap().workspace_root,
    book.workspace_root,
  )
  assert_eq(find_code_schedule_book([book], "coding").unwrap().id, "coding")
  assert_true(find_code_schedule_book([book], "book-unknown") is None)
  let exact = @moonbook.BookCatalogEntry::new(
    id="book-coding",
    name="Other book",
    purpose="Existing catalog entry",
    workspace_root="/Users/test/workspace/books/book-coding",
  )
  assert_eq(
    find_code_schedule_book([book, exact], "book-coding").unwrap().workspace_root,
    exact.workspace_root,
  )
}
