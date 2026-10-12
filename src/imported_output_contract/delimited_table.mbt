///|
/// A complete, bounded table. The first record is the header; labels and cell
/// values remain strings, including duplicate headers, empty cells and zeros.
pub(all) struct DataTable {
  headers : Array[String]
  rows : Array[Array[String]]
} derive(Debug, Eq)

///|
/// Recognize included CSV/TSV filenames. MIME fallback applies only to extensionless
/// files, so a preview.txt beside a data.csv is not mistaken for another table.
pub fn table_delimiter(path : String, mime : String) -> Char? {
  let name = path.split("/").last().unwrap_or("").to_owned().to_lower()
  if name.has_suffix(".csv") {
    return Some(',')
  }
  if name.has_suffix(".tsv") {
    return Some('\t')
  }
  if name.contains(".") {
    return None
  }
  match mime.split(";").next().unwrap_or("").trim().to_owned().to_lower() {
    "text/csv" | "application/csv" => Some(',')
    "text/tab-separated-values" => Some('\t')
    _ => None
  }
}

///|
/// Parse RFC-4180-style quoted fields with either comma or tab separators.
/// CRLF/LF/CR record separators, UTF-8 BOM, escaped quotes and quoted newlines
/// are supported. No partial table is returned on invalid or oversized input.
pub fn parse_data_table(
  text : String,
  delimiter : Char,
) -> Result[DataTable, String] {
  if delimiter != ',' && delimiter != '\t' {
    return Err("Choose CSV or TSV")
  }
  if @utf8.encode(text).length() > 1024 * 1024 {
    return Err(
      "Table exceeds the 1 MiB table-view limit. Download the exact file instead.",
    )
  }
  let chars = text.iter().collect()
  let records : Array[Array[String]] = []
  let mut row : Array[String] = []
  let mut cell = StringBuilder()
  let mut quoted = false
  let mut closed_quote = false
  let mut started = false
  let mut cells = 0
  let mut i = if chars.get(0) == Some('\uFEFF') { 1 } else { 0 }
  while i < chars.length() {
    let c = chars[i]
    if c == '\u0000' {
      return Err("NUL bytes are not supported in a table")
    }
    if quoted {
      if c == '"' {
        if chars.get(i + 1) == Some('"') {
          cell.write_char('"')
          i += 2
          continue
        }
        quoted = false
        closed_quote = true
      } else {
        cell.write_char(c)
      }
      i += 1
      continue
    }
    if c == delimiter || c == '\r' || c == '\n' {
      row.push(cell.to_string())
      cells += 1
      if row.length() > 128 || cells > 100000 {
        return Err(
          "Table exceeds 128 columns or 100,000 cells. Download the exact file instead.",
        )
      }
      cell = StringBuilder()
      closed_quote = false
      started = false
      if c != delimiter {
        if records.length() >= 10001 {
          return Err(
            "Table exceeds 10,000 data rows. Download the exact file instead.",
          )
        }
        records.push(row)
        row = []
        if c == '\r' && chars.get(i + 1) == Some('\n') {
          i += 1
        }
      }
    } else if closed_quote {
      return Err(
        "Unexpected character after closing quote in record " +
        (records.length() + 1).to_string(),
      )
    } else if c == '"' {
      if started {
        return Err(
          "Quote inside an unquoted field in record " +
          (records.length() + 1).to_string(),
        )
      }
      quoted = true
      started = true
    } else {
      cell.write_char(c)
      started = true
    }
    i += 1
  }
  if quoted {
    return Err(
      "Unclosed quoted field in record " + (records.length() + 1).to_string(),
    )
  }
  if started || closed_quote || !row.is_empty() {
    row.push(cell.to_string())
    cells += 1
    if row.length() > 128 || cells > 100000 || records.length() >= 10001 {
      return Err("Table exceeds 128 columns, 10,000 data rows or 100,000 cells")
    }
    records.push(row)
  }
  guard records.get(0) is Some(headers) else {
    return Err("This table is empty")
  }
  let rows : Array[Array[String]] = []
  for index = 1; index < records.length(); index = index + 1 {
    if records[index].length() != headers.length() {
      return Err(
        "Record " +
        (index + 1).to_string() +
        " has " +
        records[index].length().to_string() +
        " columns; expected " +
        headers.length().to_string(),
      )
    }
    rows.push(records[index])
  }
  Ok({ headers, rows, })
}

///|
/// Stable row indices matching a case-insensitive substring in any column.
pub fn DataTable::matching_rows(self : DataTable, query : String) -> Array[Int] {
  let needle = query.to_lower()
  let indices : Array[Int] = []
  for index, row in self.rows {
    if needle.is_empty() || row.any(cell => cell.to_lower().contains(needle)) {
      indices.push(index)
    }
  }
  indices
}

///|
fn csv_cell(value : String) -> String {
  // Derived spreadsheet exports neutralize formula-leading values. The exact
  // original download is unchanged, and the UI explicitly describes this step.
  let trimmed = value.trim_start()
  let value = if trimmed.has_prefix("=") ||
    trimmed.has_prefix("+") ||
    trimmed.has_prefix("-") ||
    trimmed.has_prefix("@") ||
    value.has_prefix("\t") ||
    value.has_prefix("\r") ||
    value.has_prefix("\n") {
    "'" + value
  } else {
    value
  }
  "\"" + value.replace_all(old="\"", new="\"\"") + "\""
}

///|
/// Export all matching rows, not only a visible page. Headers and row order are
/// retained; every field is quoted and formula-leading cells are apostrophe-prefixed.
pub fn DataTable::filtered_csv(self : DataTable, query : String) -> String {
  let lines = [self.headers.map(csv_cell).join(",")]
  for index in self.matching_rows(query) {
    lines.push(self.rows[index].map(csv_cell).join(","))
  }
  lines.join("\r\n") + "\r\n"
}
