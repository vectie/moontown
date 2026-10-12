///|
test "CSV quoted multiline Unicode fields trailing blanks and CRLF stay intact" {
  let input = "\uFEFFname,note,count,empty\r\n学习,\"line one\r\nline two, with \"\"quotes\"\"\",001,\r\nRiver,plain,0,\r\n"
  guard @imported_output_contract.parse_data_table(input, ',') is Ok(table) else {
    fail("expected table")
  }
  assert_eq(table.headers, ["name", "note", "count", "empty"])
  assert_eq(table.rows, [
    ["学习", "line one\r\nline two, with \"quotes\"", "001", ""],
    ["River", "plain", "0", ""],
  ])
  assert_eq(table.matching_rows("QUOTES"), [0])
  assert_eq(table.matching_rows("river"), [1])
  assert_eq(table.matching_rows("missing"), [])
  let roundtrip = match
    @imported_output_contract.parse_data_table(table.filtered_csv(""), ',') {
    Ok(value) => value
    Err(message) => fail(message + "\n" + table.filtered_csv(""))
  }
  assert_eq(roundtrip, table)
}

///|
test "TSV preserves duplicate headers empty labels and quoted tabs" {
  guard @imported_output_contract.parse_data_table(
      "id\tid\t\r007\t\"a\tb\"\t\n", '\t',
    )
    is Ok(table) else {
    fail("TSV")
  }
  assert_eq(table.headers, ["id", "id", ""])
  assert_eq(table.rows, [["007", "a\tb", ""]])
  assert_eq(
    @imported_output_contract.table_delimiter("data.CSV", "text/plain"),
    Some(','),
  )
  assert_eq(
    @imported_output_contract.table_delimiter(
      "data", "text/tab-separated-values; charset=utf-8",
    ),
    Some('\t'),
  )
  assert_eq(
    @imported_output_contract.table_delimiter("preview.txt", "text/csv"),
    None,
  )
}

///|
test "empty header only and malformed records return complete explicit outcomes" {
  assert_true(@imported_output_contract.parse_data_table("", ',') is Err(_))
  guard @imported_output_contract.parse_data_table("a,b\n", ',') is Ok(table) else {
    fail("headers")
  }
  assert_eq(table.rows, [])
  for
    input in [
      "a,b\n1", "a\nb,c", "a\n\"unclosed", "a\n\"x\"tail", "a\nx\"y", "a\n\u0000",
    ] {
    assert_true(
      @imported_output_contract.parse_data_table(input, ',') is Err(_),
    )
  }
  assert_true(
    @imported_output_contract.parse_data_table("a\n" + "x\n".repeat(10001), ',')
    is Err(_),
  )
  assert_true(
    @imported_output_contract.parse_data_table("a,".repeat(128) + "b", ',')
    is Err(_),
  )
  assert_true(
    @imported_output_contract.parse_data_table("x".repeat(1024 * 1024 + 1), ',')
    is Err(_),
  )
}

///|
test "filtered CSV includes headers all matches original ordering and safe formula text" {
  guard @imported_output_contract.parse_data_table(
      "=header,note\n=1+2,keep\n-12,skip\n @SUM(A1),keep\n", ',',
    )
    is Ok(table) else {
    fail("table")
  }
  assert_eq(
    table.filtered_csv("keep"),
    "\"'=header\",\"note\"\r\n\"'=1+2\",\"keep\"\r\n\"' @SUM(A1)\",\"keep\"\r\n",
  )
  assert_eq(table.filtered_csv("missing"), "\"'=header\",\"note\"\r\n")
  assert_eq(table.rows[0][0], "=1+2")
}
