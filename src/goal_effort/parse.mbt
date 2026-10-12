///|
fn decode_source(bytes : Bytes, label : String) -> String raise {
  guard bytes.length() <= 1048576 else { fail(label + " exceeds 1 MiB") }
  @utf8.decode(bytes) catch {
    _ => fail(label + " must be valid UTF-8")
  }
}

///|
fn parse_goals(bytes : Bytes) -> Array[@core.StandingGoal] raise {
  let text = decode_source(bytes, "Goals")
  let goals : Array[@core.StandingGoal] = @json.from_json(@json.parse(text))
  guard goals.length() <= 2000 else { fail("Goals exceed 2,000 entries") }
  let seen : Map[String, Bool] = {}
  for goal in goals {
    guard !goal.id.trim().is_empty() && !seen.contains(goal.id) else {
      fail("Saved goals must have distinct nonblank IDs")
    }
    seen[goal.id] = true
  }
  goals
}

///|
fn date_day(text : String) -> Int raise {
  guard text.length() == 10 && text[4] == '-' && text[7] == '-' else {
    fail("Periods require YYYY-MM-DD dates")
  }
  for i = 0; i < 10; i = i + 1 {
    if i != 4 && i != 7 && (text[i] < '0' || text[i] > '9') {
      fail("Periods require YYYY-MM-DD dates")
    }
  }
  let year = @string.parse_int(try! text[0:4].to_string())
  let month = @string.parse_int(try! text[5:7].to_string())
  let day = @string.parse_int(try! text[8:10].to_string())
  guard year >= 1 && month >= 1 && month <= 12 else {
    fail("Invalid period date")
  }
  let leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
  let months = [
    31,
    if leap {
      29
    } else {
      28
    },
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ]
  guard day >= 1 && day <= months[month - 1] else {
    fail("Invalid period date")
  }
  let y = year - 1
  let mut ordinal = y * 365 + y / 4 - y / 100 + y / 400 + day - 1
  for m = 0; m < month - 1; m = m + 1 {
    ordinal += months[m]
  }
  ordinal
}

///|
fn minutes(value : String) -> Int? raise {
  if value.is_empty() {
    return None
  }
  guard value.length() <= 6 && value.iter().all(c => c >= '0' && c <= '9') else {
    fail("Minutes must be blank (unknown) or a whole number from 0 to 100000")
  }
  let n = @string.parse_int(value)
  guard n <= 100000 else {
    fail("Minutes must be blank (unknown) or a whole number from 0 to 100000")
  }
  Some(n)
}

///|
fn parse_diary(
  bytes : Bytes,
  delimiter : Char,
  goals : Array[@core.StandingGoal],
) -> Array[Array[EffortPeriod]] raise {
  let table = match
    @table.parse_data_table(decode_source(bytes, "Diary"), delimiter) {
    Ok(t) => t
    Err(error) => fail("Diary: " + error)
  }
  let headers = [
    "goal_id", "period_start", "period_end", "outcome", "manual_period_start", "manual_period_end",
    "manual_minutes", "review_minutes", "supervision_minutes", "followup_minutes",
    "note",
  ]
  guard table.headers == headers else {
    fail("Diary columns must be exactly: " + headers.join(","))
  }
  guard table.rows.length() <= 2000 else { fail("Diary exceeds 2,000 periods") }
  let indices : Map[String, Int] = {}
  for i, goal in goals {
    indices[goal.id] = i
  }
  let periods : Array[Array[EffortPeriod]] = goals.map(_ => [])
  let windows : Array[Array[(Int, Int)]] = goals.map(_ => [])
  let manual_windows : Array[Array[(Int, Int)]] = goals.map(_ => [])
  for i, row in table.rows {
    try {
      guard indices.get(row[0]) is Some(index) else {
        fail("Unknown goal_id: " + row[0])
      }
      let start = date_day(row[1])
      let end = date_day(row[2])
      guard end > start else {
        fail("period_end must be later than period_start")
      }
      guard !row[3].trim().is_empty() else {
        fail("Name the common measured outcome for the period")
      }
      for (previous_start, previous_end) in windows[index] {
        guard start >= previous_end || end <= previous_start else {
          fail("Overlapping periods for goal_id: " + row[0])
        }
      }
      windows[index].push((start, end))
      let manual = minutes(row[6])
      let review = minutes(row[7])
      let supervision = minutes(row[8])
      let followup = minutes(row[9])
      let has_manual_dates = !row[4].is_empty() || !row[5].is_empty()
      guard manual is None || has_manual_dates else {
        fail("Measured manual minutes require explicit manual period dates")
      }
      if has_manual_dates {
        let manual_start = date_day(row[4])
        let manual_end = date_day(row[5])
        guard manual_end - manual_start == end - start else {
          fail("Manual and Town periods must have equal positive day counts")
        }
        for (previous_start, previous_end) in manual_windows[index] {
          guard manual_start >= previous_end || manual_end <= previous_start else {
            fail("Overlapping manual baseline periods for goal_id: " + row[0])
          }
        }
        manual_windows[index].push((manual_start, manual_end))
      }
      let town = match (review, supervision, followup) {
        (Some(r), Some(s), Some(f)) => Some(r + s + f)
        _ => None
      }
      let difference = match (manual, town) {
        (Some(m), Some(t)) => Some(m - t)
        _ => None
      }
      periods[index].push({
        source_data_row: i + 1,
        period_start: row[1],
        period_end: row[2],
        outcome: row[3],
        manual_period_start: if has_manual_dates {
          Some(row[4])
        } else {
          None
        },
        manual_period_end: if has_manual_dates {
          Some(row[5])
        } else {
          None
        },
        manual_minutes: manual,
        review_minutes: review,
        supervision_minutes: supervision,
        followup_minutes: followup,
        town_minutes: town,
        manual_minus_town_minutes: difference,
        note: row[10],
      })
    } catch {
      error => fail("Diary data row " + (i + 1).to_string() + ": " + "\{error}")
    }
  }
  periods
}
