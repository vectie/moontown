///|
async test "source picker public API observes registered relative files without creating state" {
  let root = @fs.realpath(@fs.tmpdir(prefix="town-picker-public-"))
  @fs.mkdir(root + "/book")
  @fs.write_file(root + "/book/source.bin", b"\x00\xff", create_mode=CreateNew)
  let catalog = [
    @moonbook.BookCatalogEntry::new(
      id="book",
      name="Company Book",
      purpose="test",
      workspace_root=root + "/book",
    ),
  ]
  @fs.write_file(
    root + "/catalog.json",
    catalog.to_json().stringify(),
    create_mode=CreateNew,
  )
  let store : @collaboration_authoring.Store = {
    root: root + "/state",
    catalog_path: root + "/catalog.json",
  }
  let result = store.list_sources("book")
  assert_eq(result.book_id, "book")
  assert_eq(result.paths, ["source.bin"])
  assert_false(result.truncated)
  assert_eq(result.unreadable_entries, 0)
  assert_false(@fs.exists(root + "/state"))
  assert_eq(@fs.read_file(root + "/book/source.bin").binary(), b"\x00\xff")
  @fs.rmdir(root, recursive=true)
}
