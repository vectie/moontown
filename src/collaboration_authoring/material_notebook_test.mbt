///|
async test "public material import returns editable source data without writing town state" {
  let root = @fs.realpath(@fs.tmpdir(prefix="town-material-public-"))
  @fs.mkdir(root + "/book")
  @fs.write_file(
    root + "/book/notes.md",
    "A café observation.\n",
    create_mode=CreateNew,
  )
  let catalog = [
    @moonbook.BookCatalogEntry::new(
      id="field",
      name="Field Book",
      purpose="fixture",
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
  let notebook = store.import_material("field-question", [
    { book_id: "field", source_paths: ["notes.md"], },
  ])
  assert_eq(notebook.pages[0].text, "A café observation.\n")
  assert_eq(notebook.pages[0].size_bytes, 21)
  assert_eq(notebook.find("café").matched_lines, 1)
  assert_true(notebook.excerpts.is_empty())
  assert_false(@fs.exists(store.root))
}
