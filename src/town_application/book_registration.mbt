///| Register an existing MoonBook in MoonTown's catalog. The owner service

///|
/// validates the local book root and remains the only catalog writer.
pub async fn RequestApplication::register_existing_book(
  self : RequestApplication,
  body : String,
) -> Json {
  ignore(self)
  let parsed = @json.parse(body)
  let fields = match parsed {
    Object(fields) => fields
    _ => fail("request body must be a JSON object")
  }
  let requested_id = json_string_field(fields, "book_id")
  let book_id = safe_slug(requested_id)
  let title = json_string_field(fields, "title")
  let purpose = json_string_field(fields, "purpose")
  let requested_root = json_string_field(fields, "workspace_root")
  if requested_id == "" ||
    book_id != requested_id ||
    title == "" ||
    purpose == "" ||
    requested_root == "" {
    fail("book_id, title, purpose, and workspace_root are required")
  }
  let workspace_root = @fs.realpath(requested_root) catch {
    _ => fail("workspace_root must resolve to an existing local directory")
  }
  if !workspace_root.has_suffix("/" + book_id) ||
    !@fs.exists(workspace_root + "/book.json") {
    fail("workspace_root must be the matching MoonBook directory")
  }
  let entry = @moonbook.BookCatalogEntry::new(
    id=book_id,
    name=title,
    purpose~,
    workspace_root~,
    tags=json_string_list_field(fields, "tags"),
    skills=json_string_list_field(fields, "skills"),
  )
  let catalog_path = @moonbook.default_catalog_path()
  let catalog = @moonbook.load_or_create_catalog(path=catalog_path).filter(existing => {
    existing.id != book_id
  })
  catalog.push(entry)
  @moonbook.save_catalog_file(catalog_path, catalog)
  {
    "ok": true,
    "status": "registered",
    "book_id": book_id,
    "catalog_path": catalog_path,
    "workspace_root": workspace_root,
  }
}
