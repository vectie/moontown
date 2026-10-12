///|
fn table_view_valid(table : DataTable) -> Bool {
  !table.headers.is_empty() &&
  table.headers.length() <= 128 &&
  table.rows.length() <= 10000 &&
  (table.rows.length() + 1) * table.headers.length() <= 100000 &&
  table.rows.all(row => row.length() == table.headers.length())
}

///|
/// Filter one explicit column (or all columns), using ASCII-only case folding,
/// then sort lexically by UTF-16 code units after that folding. Non-ASCII case
/// variants such as é/É remain distinct. Ties always keep source order,
/// including descending order. Empty exact
/// queries find empty cells; contains with an empty query includes every row.
/// Indices refer to the original data rows, never to filtered positions.
pub fn DataTable::view_rows(
  self : DataTable,
  query : String,
  column? : Int,
  exact? : Bool = false,
  sort_column? : Int,
  descending? : Bool = false,
) -> Result[Array[Int], String] {
  if !table_view_valid(self) {
    return Err("Invalid or oversized table")
  }
  for choice in [column, sort_column] {
    if choice is Some(index) && (index < 0 || index >= self.headers.length()) {
      return Err("Column position is outside the source table")
    }
  }
  let needle = query.to_lower()
  fn matches(cell : String) -> Bool {
    if exact {
      cell.to_lower() == needle
    } else {
      cell.to_lower().contains(needle)
    }
  }
  let rows : Array[Int] = []
  for index, row in self.rows {
    let matched = match column {
      Some(c) => matches(row[c])
      None => row.any(matches)
    }
    if matched {
      rows.push(index)
    }
  }
  if sort_column is Some(c) {
    let keys = self.rows.map(row => row[c].to_lower())
    rows.sort_by((a, b) => {
      // String::compare uses shortlex. This explicit lexical comparator sorts
      // by code units rather than putting all shorter strings first.
      let order = keys[a].compare_ignore_ascii_case(keys[b])
      if order == 0 {
        a.compare(b)
      } else if descending {
        0 - order
      } else {
        order
      }
    })
  }
  Ok(rows)
}

///|
/// Export explicit original row and column positions, in requested order, with
/// a first column identifying the 1-based source data row. Duplicate/invalid
/// positions and empty projections fail atomically. Original labels and values
/// are preserved except existing formula-neutralization for derived CSV.
pub fn DataTable::view_csv(
  self : DataTable,
  rows : Array[Int],
  columns : Array[Int],
) -> Result[String, String] {
  if !table_view_valid(self) {
    return Err("Invalid or oversized table")
  }
  if columns.is_empty() {
    return Err("Choose at least one output column")
  }
  let seen_columns : Map[Int, Bool] = {}
  for c in columns {
    if c < 0 || c >= self.headers.length() || seen_columns.contains(c) {
      return Err(
        "Output column positions must be distinct and within the source table",
      )
    }
    seen_columns[c] = true
  }
  let seen_rows : Map[Int, Bool] = {}
  for r in rows {
    if r < 0 || r >= self.rows.length() || seen_rows.contains(r) {
      return Err(
        "Output row positions must be distinct and within the source table",
      )
    }
    seen_rows[r] = true
  }
  let lines = [
    (["source_data_row"] + columns.map(c => self.headers[c]))
    .map(csv_cell)
    .join(","),
  ]
  let mut bytes = @utf8.encode(lines[0]).length() + 2
  for r in rows {
    let line = ([(r + 1).to_string()] + columns.map(c => self.rows[r][c]))
      .map(csv_cell)
      .join(",")
    bytes += @utf8.encode(line).length() + 2
    if bytes > 4 * 1024 * 1024 {
      return Err("Derived table view exceeds 4 MiB")
    }
    lines.push(line)
  }
  if bytes > 4 * 1024 * 1024 {
    return Err("Derived table view exceeds 4 MiB")
  }
  Ok(lines.join("\r\n") + "\r\n")
}
