///|
async test "local imported CSV and TSV flow through discovery verified response and derived output" {
  for
    (filename, mime, content, delimiter) in [
      (
        "research.csv", "text/csv", "place,topic,count\r\n杭州,\"river, study\",001\r\nNorth,transport,2\r\n",
        ',',
      ),
      (
        "research.tsv", "text/tab-separated-values", "place\ttopic\tcount\n杭州\t\"river\tstudy\"\t001\nNorth\ttransport\t2\n",
        '\t',
      ),
    ] {
    let bytes = @utf8.encode(content)
    let (home, root, selection) = fixture(bytes, filename~, mime~)
    defer @fs.rmdir(home, recursive=true)
    let catalog_path = home + "/missing-catalog.json"
    let catalog = discover(catalog_path, home)
    assert_eq(catalog.books[0].outputs[0].files[0].path, selection.path)
    assert_eq(
      @contract.table_delimiter(
        selection.path,
        catalog.books[0].outputs[0].mime_type,
      ),
      Some(delimiter),
    )
    let response = respond(
      "GET",
      @contract.content_path(selection, mode="text"),
      catalog_path,
      home,
    )
    assert_eq(response.status, 200)
    let reply = @contract.parse_text_reply(@utf8.decode(response.body)).unwrap()
    assert_eq(reply.selection, selection)
    guard @contract.parse_data_table(reply.content.unwrap(), delimiter)
      is Ok(table) else {
      fail("table")
    }
    assert_eq(table.matching_rows("river"), [0])
    guard @contract.parse_data_table(table.filtered_csv("river"), ',')
      is Ok(exported) else {
      fail("export")
    }
    assert_eq(exported.headers, ["place", "topic", "count"])
    assert_eq(exported.rows.length(), 1)
    assert_eq(exported.rows[0][0], "杭州")
    assert_eq(exported.rows[0][2], "001")
    assert_eq(
      respond(
        "GET",
        @contract.content_path(selection, mode="download"),
        catalog_path,
        home,
      ).body,
      bytes,
    )
    assert_eq(@fs.read_file(root + "/" + selection.path).binary(), bytes)
    assert_false(@fs.exists(catalog_path))
  }
}
