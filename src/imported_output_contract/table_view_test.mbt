///|
test "column filter distinguishes exact text from unrelated fields and empty cells" {
  let table = @imported_output_contract.parse_data_table(
    "name,status,note\nBeta,open,closed\nalpha,closed,open\nALPHA,open,\nempty,,blank\n",
    ',',
  ).unwrap()
  assert_eq(table.view_rows("OPEN", column=1, exact=true).unwrap(), [0, 2])
  assert_eq(table.view_rows("open").unwrap(), [0, 1, 2])
  assert_eq(table.view_rows("", column=1, exact=true).unwrap(), [3])
  assert_eq(table.view_rows("", column=1).unwrap(), [0, 1, 2, 3])
  assert_eq(table.view_rows(" open", column=1, exact=true).unwrap(), [])
  assert_true(table.view_rows("", column=3) is Err(_))
  assert_true(table.view_rows("", sort_column=-1) is Err(_))
}

///|
test "stable text sorting preserves tied source rows both directions" {
  let table = @imported_output_contract.parse_data_table(
    "name,n\nBeta,2\nalpha,10\nALPHA,1\n,0\n", ',',
  ).unwrap()
  assert_eq(table.view_rows("", sort_column=0).unwrap(), [3, 1, 2, 0])
  assert_eq(table.view_rows("", sort_column=0, descending=true).unwrap(), [
    0, 1, 2, 3,
  ])
  assert_eq(table.view_rows("", sort_column=1).unwrap(), [3, 2, 1, 0])
  assert_eq(table.rows[0], ["Beta", "2"])
}

///|
test "projection retains row provenance duplicate labels Unicode and safe CSV" {
  let table = @imported_output_contract.parse_data_table(
    "name,,name\n=SUM(A1),001,河流\nB,002,\"two\nlines\"\n", ',',
  ).unwrap()
  let csv = table.view_csv([1, 0], [2, 0]).unwrap()
  let output = @imported_output_contract.parse_data_table(csv, ',').unwrap()
  assert_eq(output.headers, ["source_data_row", "name", "name"])
  assert_eq(output.rows, [
    ["2", "two\nlines", "B"],
    ["1", "河流", "'=SUM(A1)"],
  ])
  assert_eq(table.view_csv([], [1]).unwrap(), "\"source_data_row\",\"\"\r\n")
  assert_true(table.view_csv([0, 0], [1]) is Err(_))
  assert_true(table.view_csv([2], [1]) is Err(_))
  assert_true(table.view_csv([0], [1, 1]) is Err(_))
  assert_true(table.view_csv([0], []) is Err(_))
  assert_true(table.view_csv([0], [-1]) is Err(_))
}

///|
test "ASCII-only folding keeps non-ASCII case variants distinct" {
  let table = @imported_output_contract.parse_data_table(
    "name\né\nÉ\nE\ne\n", ',',
  ).unwrap()
  assert_eq(table.view_rows("é", column=0, exact=true).unwrap(), [0])
  assert_eq(table.view_rows("é", column=0).unwrap(), [0])
  assert_eq(table.view_rows("É", column=0, exact=true).unwrap(), [1])
  assert_eq(table.view_rows("e", column=0, exact=true).unwrap(), [2, 3])
  assert_eq(table.view_rows("", sort_column=0).unwrap(), [2, 3, 1, 0])
  assert_eq(table.view_rows("", sort_column=0, descending=true).unwrap(), [
    0, 1, 2, 3,
  ])
}

///|
test "invalid public table shape and oversized derived output fail atomically" {
  let bad : @imported_output_contract.DataTable = {
    headers: ["a"],
    rows: [["a", "b"]],
  }
  assert_true(bad.view_rows("") is Err(_))
  assert_true(bad.view_csv([0], [0]) is Err(_))
  let large : @imported_output_contract.DataTable = {
    headers: ["h"],
    rows: [["x".repeat(4 * 1024 * 1024)]],
  }
  assert_true(large.view_csv([0], [0]) is Err(_))
}
