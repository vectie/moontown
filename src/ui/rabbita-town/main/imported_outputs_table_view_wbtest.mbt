///|
test "column table journey filters sorts projects and exports actual source rows" {
  let state = imported_table_fixture(
    "name,status,note\nZulu,open,closed\nalpha,closed,open\nBeta,open,001\nbeta,OPEN,002\nempty,,none\n",
  )
  let filtered = imported_outputs_transition(
      state,
      TableViewEvent(FilterColumn("1")),
    ).0
  let filtered = imported_outputs_transition(
      filtered,
      SearchImportedTable("open"),
    ).0
  let filtered = imported_outputs_transition(
      filtered,
      TableViewEvent(MatchMode(true)),
    ).0
  let sorted = imported_outputs_transition(
      filtered,
      TableViewEvent(SortColumn("0")),
    ).0
  let projected = imported_outputs_transition(
      sorted,
      TableViewEvent(ToggleColumn(1)),
    ).0
  let html = imported_fixture_render(projected)
  assert_true(html.contains("3 of 5 data rows"))
  assert_true(html.contains("Omitted 2: status"))
  assert_false(html.contains(">alpha<"))
  guard imported_outputs_transition(projected, DownloadFilteredTable).1
    is Some(SaveFilteredTable(csv, filename)) else {
    fail("export")
  }
  assert_eq(filename, "table-view.csv")
  let table = @imported_output_contract.parse_data_table(csv, ',').unwrap()
  assert_eq(table.headers, ["source_data_row", "name", "note"])
  assert_eq(table.rows, [
    ["3", "Beta", "001"],
    ["4", "beta", "002"],
    ["1", "Zulu", "closed"],
  ])
  let descending = imported_outputs_transition(
      projected,
      TableViewEvent(SortDescending(true)),
    ).0
  guard imported_outputs_transition(descending, DownloadFilteredTable).1
    is Some(SaveFilteredTable(csv, _)) else {
    fail("descending")
  }
  assert_eq(
    @imported_output_contract.parse_data_table(csv, ',').unwrap().rows[0][0],
    "1",
  )
  assert_eq(projected.text, state.text)
  let reset = imported_outputs_transition(
      projected,
      TableViewEvent(TableViewMsg::Reset),
    ).0
  assert_eq(reset.table_view, initial_table_view())
  assert_eq(reset.table_query, "")
}

///|
test "table view discloses and preserves ASCII-only case folding" {
  let state = imported_table_fixture("name\né\nÉ\nE\ne\n")
  assert_true(
    imported_fixture_render(state).contains("ASCII-only case folding"),
  )
  let filtered = imported_outputs_transition(state, SearchImportedTable("é")).0
  let filtered = imported_outputs_transition(
      filtered,
      TableViewEvent(MatchMode(true)),
    ).0
  guard imported_outputs_transition(filtered, DownloadFilteredTable).1
    is Some(SaveFilteredTable(csv, _)) else {
    fail("case filter")
  }
  assert_eq(
    @imported_output_contract.parse_data_table(csv, ',').unwrap().rows,
    [["1", "é"]],
  )
  let sorted = imported_outputs_transition(
      state,
      TableViewEvent(SortColumn("0")),
    ).0
  guard imported_outputs_transition(sorted, DownloadFilteredTable).1
    is Some(SaveFilteredTable(csv, _)) else {
    fail("case sort")
  }
  assert_eq(
    @imported_output_contract.parse_data_table(csv, ',').unwrap().rows,
    [["3", "E"], ["4", "e"], ["2", "É"], ["1", "é"]],
  )
}

///|
test "table view exports all sorted pages and resets when source changes" {
  let lines : Array[String] = []
  for i in 0..<55 {
    lines.push("same," + i.to_string())
  }
  let state = imported_table_fixture("name,id\n" + lines.join("\n") + "\n")
  let sorted = imported_outputs_transition(
      state,
      TableViewEvent(SortColumn("0")),
    ).0
  let page = imported_outputs_transition(sorted, PageImportedTable(2)).0
  guard imported_outputs_transition(page, DownloadFilteredTable).1
    is Some(SaveFilteredTable(csv, _)) else {
    fail("pages")
  }
  let output = @imported_output_contract.parse_data_table(csv, ',').unwrap()
  assert_eq(output.rows.length(), 55)
  assert_eq(output.rows[54][0], "55")
  let omitted = imported_outputs_transition(
      page,
      TableViewEvent(ToggleColumn(0)),
    ).0
  let empty = imported_outputs_transition(
      omitted,
      TableViewEvent(ToggleColumn(1)),
    ).0
  assert_eq(empty.table_page, 0)
  assert_eq(imported_outputs_transition(empty, DownloadFilteredTable).1, None)
  assert_true(
    imported_fixture_render(empty).contains("Choose at least one output column"),
  )
  assert_eq(
    imported_outputs_transition(empty, TableViewEvent(FilterColumn("99"))).0,
    empty,
  )
  let refreshed = imported_outputs_transition(page, RefreshImportedOutputs).0
  assert_eq(refreshed.table_view, initial_table_view())
  let selected = imported_outputs_transition(
      page,
      ChooseImportedFile(state.selection.unwrap().path),
    ).0
  assert_eq(selected.table_view, initial_table_view())
  let closed = imported_outputs_transition(page, CloseImportedOutputs).0
  assert_eq(
    imported_outputs_transition(closed, TableViewEvent(SortColumn("0"))).0,
    closed,
  )
}
