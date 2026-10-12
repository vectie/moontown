///|
/// Export an explicit canonical StandingGoal snapshot as a lossless editable
/// CSV/TSV table. JSON string cells preserve all text and keep formula-looking
/// values inert. No schedule is reset, normalized or executed. Input and output
/// are at most 1 MiB; at most 2,000 exact, nonblank, distinct goal IDs are allowed.
pub fn snapshot_to_table(
  bytes : Bytes,
  delimiter : Char,
) -> Result[String, String] {
  try {
    guard delimiter == ',' || delimiter == '\t' else {
      fail("Choose CSV or TSV")
    }
    let separator = delimiter.to_string()
    let goals = snapshot_goals(bytes)
    let lines = [headers().map(quoted_cell).join(separator)]
    for goal in goals {
      lines.push(
        [
          text_cell(goal.id),
          text_cell(goal.title),
          text_cell(goal.prompt),
          optional_text_cell(goal.target_book_id),
          goal.cadence_ticks.to_string(),
          goal.next_due_tick.to_string(),
          optional_int_cell(goal.last_run_tick),
          goal.enabled.to_string(),
          text_cell(goal.source_policy),
          goal.quality_threshold.to_string(),
        ]
        .map(quoted_cell)
        .join(separator),
      )
    }
    bounded_output(lines.join("\r\n") + "\r\n")
  } catch {
    error => Err("\{error}")
  } noraise {
    value => Ok(value)
  }
}

///|
/// Import an entire edited CSV/TSV table into canonical StandingGoal JSON, using
/// the same type/serializer as the existing storage writer. This is a complete
/// snapshot, not an upsert: rows and order are exactly those supplied. Text
/// columns are JSON strings; absent target/last-run values use literal null.
pub fn table_to_snapshot(
  bytes : Bytes,
  delimiter : Char,
) -> Result[String, String] {
  try {
    let table = match @table.parse_data_table(source_text(bytes), delimiter) {
      Ok(value) => value
      Err(error) => fail(error)
    }
    guard table.headers == headers() else {
      fail("Columns must be exactly: " + headers().join(","))
    }
    guard table.rows.length() <= 2000 else {
      fail("At most 2,000 goals are supported")
    }
    let goals = table.rows.mapi((index, row) => {
      row_goal(row) catch {
        error => fail("Data row " + (index + 1).to_string() + ": " + "\{error}")
      }
    })
    check_goals(goals)
    bounded_output(goals.to_json().stringify() + "\n")
  } catch {
    error => Err("\{error}")
  } noraise {
    value => Ok(value)
  }
}

///|
/// Decode a bounded exact StandingGoal snapshot without table serialization.
/// Shares the export/import identity, field, UTF-8 and exact-integer checks.
pub fn decode_snapshot(
  bytes : Bytes,
) -> Result[Array[@core.StandingGoal], String] {
  try snapshot_goals(bytes) catch {
    error => Err("\{error}")
  } noraise {
    goals => Ok(goals)
  }
}
