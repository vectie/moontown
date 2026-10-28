///|
fn imported_table_fixture(
  content : String,
  filename~ : String = "data.csv",
) -> ImportedOutputsState raise {
  let selection : @imported_output_contract.Selection = {
    book_handle: "book-" + "1".repeat(64),
    package_sha256: imported_fixture_digest("c"),
    manifest_sha256: imported_fixture_digest("d"),
    artifact_id: "result",
    path: "portable/outputs/result/" + filename,
    digest: "sha256:" + table_test_digest(content),
    size_bytes: @utf8.encode(content).length(),
  }
  let base = imported_download_pending_from_catalog(
      imported_download_synthetic_catalog(selection),
      selection,
    ).imported_outputs
  imported_outputs_transition(
    base,
    ImportedTextLoaded(
      base.generation,
      selection,
      imported_fixture_reply(selection, content),
    ),
  ).0
}

///|
extern "js" fn table_test_digest(value : String) -> String =
  #| value => require("node:crypto").createHash("sha256").update(value, "utf8").digest("hex")

///|
test "table workflow renders quoted CSV pages searches exports all matches and keeps raw download" {
  let lines : Array[String] = []
  for index in 0..<60 {
    lines.push("Town " + index.to_string() + ",\"river, study\",001\r\n")
  }
  let content = "place,note,count\r\n" + lines.join("")
  let state = imported_table_fixture(content)
  assert_true(state.table is Some(Ok(_)))
  let html = imported_fixture_render(state)
  assert_true(html.contains("Explore table"))
  assert_true(html.contains("60 of 60 data rows"))
  assert_true(html.contains("Town 24"))
  assert_false(html.contains("Town 25"))
  assert_true(html.contains("Download exact file"))
  let (page, _) = imported_outputs_transition(state, PageImportedTable(1))
  assert_true(imported_fixture_render(page).contains("Town 25"))
  assert_false(imported_fixture_render(page).contains(">Town 0<"))
  let (search, _) = imported_outputs_transition(
    page,
    SearchImportedTable("Town 5"),
  )
  assert_eq(search.table_page, 0)
  assert_true(imported_fixture_render(search).contains("11 of 60 data rows"))
  guard imported_outputs_transition(search, DownloadFilteredTable).1
    is Some(SaveFilteredTable(csv, filename)) else {
    fail("export")
  }
  assert_eq(filename, "table-view.csv")
  guard @imported_output_contract.parse_data_table(csv, ',') is Ok(table) else {
    fail("CSV")
  }
  assert_eq(table.rows.length(), 11)
  assert_eq(table.rows[0][0], "6")
  assert_eq(table.rows[0][1], "Town 5")
  assert_eq(table.rows[10][1], "Town 59")
  guard imported_outputs_transition(state, DownloadFilteredTable).1
    is Some(SaveFilteredTable(all, _)) else {
    fail("all export")
  }
  guard @imported_output_contract.parse_data_table(all, ',') is Ok(all_table) else {
    fail("all CSV")
  }
  assert_eq(all_table.rows.length(), 60)
  let (raw, _) = imported_outputs_transition(search, ShowImportedTable(false))
  assert_true(imported_fixture_render(raw).contains("Verified full text"))
  assert_eq(raw.text, state.text)
  assert_eq(
    imported_outputs_transition(search, PageImportedTable(99)).0,
    search,
  )
}

///|
test "table cells are inert and malformed table offers exact raw fallback" {
  let state = imported_table_fixture(
    "name,note\n<script>,\"<img onerror='x'>\"\n",
  )
  let html = imported_fixture_render(state)
  assert_true(html.contains("&lt;script&gt;"))
  assert_false(html.contains("<script>"))
  assert_false(html.contains("<img onerror"))
  let malformed = imported_table_fixture("a,b\n1\n")
  assert_true(malformed.table is Some(Err(_)))
  assert_true(imported_fixture_render(malformed).contains("Record 2"))
  assert_true(imported_fixture_render(malformed).contains("Verified full text"))
  assert_eq(
    imported_outputs_transition(malformed, DownloadFilteredTable).1,
    None,
  )
  let empty = imported_outputs_transition(
      state,
      SearchImportedTable("no match"),
    ).0
  assert_true(imported_fixture_render(empty).contains("No rows match"))
  let closed = imported_outputs_transition(state, CloseImportedOutputs).0
  assert_eq(closed.table, None)
  assert_eq(imported_outputs_transition(closed, DownloadFilteredTable).1, None)
  assert_eq(
    imported_outputs_transition(closed, SearchImportedTable("x")).0,
    closed,
  )
}

///|
test "TSV preview and source changes reset table state without network writes" {
  let state = imported_table_fixture(
    "id\tnote\n007\t\"hello\tworld\"\n",
    filename="input.tsv",
  )
  guard state.table is Some(Ok(table)) else { fail("TSV table") }
  assert_eq(table.rows, [["007", "hello\tworld"]])
  let filtered = imported_outputs_transition(
      state,
      SearchImportedTable("hello"),
    ).0
  let refreshed = imported_outputs_transition(filtered, RefreshImportedOutputs).0
  assert_eq(refreshed.table, None)
  assert_eq(refreshed.table_query, "")
  assert_eq(refreshed.table_page, 0)
  let selected = imported_outputs_transition(
      filtered,
      ChooseImportedFile(state.selection.unwrap().path),
    ).0
  assert_eq(selected.table, None)
  assert_eq(selected.table_query, "")
}
