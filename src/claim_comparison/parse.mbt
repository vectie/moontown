///|
fn decode(bytes : Bytes, limit : Int, label : String) -> String raise {
  guard bytes.length() <= limit else { fail(label + " exceeds byte limit") }
  @utf8.decode(bytes) catch {
    _ => fail(label + " must be valid UTF-8")
  }
}

///|
fn parse(bytes : Bytes, delimiter : Char) -> Array[Claim] raise {
  guard delimiter == ',' || delimiter == '\t' else { fail("Use CSV or TSV") }
  let table = match
    @table.parse_data_table(decode(bytes, 1048576, "Claim table"), delimiter) {
    Ok(table) => table
    Err(error) => fail(error)
  }
  guard table.headers ==
    ["claim_id", "book_id", "topic", "context", "value", "source_path", "quote"] else {
    fail(
      "Expected columns: claim_id,book_id,topic,context,value,source_path,quote",
    )
  }
  guard table.rows.length() > 0 && table.rows.length() <= 200 else {
    fail("Supply 1 to 200 claims")
  }
  let ids : Map[String, Bool] = {}
  table.rows.mapi((i, row) => {
    for cell in row {
      guard !cell.trim().is_empty() && cell.length() <= 16384 else {
        fail(
          "Data row " +
          (i + 1).to_string() +
          ": cells must be nonblank and at most 16384 code units",
        )
      }
    }
    guard !ids.contains(row[0]) else { fail("Duplicate claim_id: " + row[0]) }
    ids[row[0]] = true
    guard @table.relative_path_valid(row[5]) else {
      fail("Unsafe source_path: " + row[5])
    }
    {
      claim_id: row[0],
      book_id: row[1],
      topic: row[2],
      context: row[3],
      value: row[4],
      source_path: row[5],
      quote: row[6],
    }
  })
}

///|
fn paths(claims : Array[Claim]) -> Array[String] raise {
  let result : Array[String] = []
  for claim in claims {
    if !result.contains(claim.source_path) {
      result.push(claim.source_path)
    }
  }
  guard result.length() <= 64 else {
    fail("At most 64 source files are supported")
  }
  result
}

///|
/// Validate a bounded claim table and return its explicit, distinct relative source paths.
/// No source is opened by this portable API.
pub fn source_paths(
  bytes : Bytes,
  delimiter : Char,
) -> Result[Array[String], String] {
  try paths(parse(bytes, delimiter)) catch {
    error => Err("\{error}")
  } noraise {
    value => Ok(value)
  }
}
