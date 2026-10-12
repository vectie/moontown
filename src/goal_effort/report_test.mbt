///|
fn goals_bytes() -> Bytes {
  @utf8.encode(
    [
      @core.StandingGoal::new(
        id="watch-a",
        title="Customer evidence",
        prompt="Question",
        target_book_id=Some("book-a"),
      ),
      @core.StandingGoal::new(
        id="watch-b",
        title="=Unmeasured",
        prompt="Question",
        enabled=false,
      ),
    ]
    .to_json()
    .stringify(),
  )
}

///|
fn header() -> String {
  "goal_id,period_start,period_end,outcome,manual_period_start,manual_period_end,manual_minutes,review_minutes,supervision_minutes,followup_minutes,note\n"
}

///|
fn row(
  goal : String,
  start : String,
  end : String,
  manual : String,
  review : String,
  supervision : String,
  followup : String,
  baseline_start? : String,
  baseline_end? : String,
  outcome? : String = "Review customer evidence",
  note? : String = "",
) -> String {
  let ms = baseline_start.unwrap_or(if manual.is_empty() { "" } else { start })
  let me = baseline_end.unwrap_or(if manual.is_empty() { "" } else { end })
  [
    goal, start, end, outcome, ms, me, manual, review, supervision, followup, note,
  ]
  .map(v => "\"" + v.replace_all(old="\"", new="\"\"") + "\"")
  .join(",") +
  "\n"
}

///|
fn result(text : String) -> Result[String, String] {
  @goal_effort.report(
    goals_bytes(),
    @utf8.encode(header() + text),
    ',',
    format="json",
  )
}

///|
fn report(text : String) -> Json raise {
  match result(text) {
    Ok(output) => @json.parse(output)
    Err(error) => fail(error)
  }
}

///|
fn field(value : Json, key : String) -> Json raise {
  guard value is Object(fields) else { fail("Expected object") }
  match fields.get(key) {
    Some(value) => value
    None => fail("Missing JSON field: " + key)
  }
}

///|
fn item(value : Json, i : Int) -> Json raise {
  guard value is Array(items) else { fail("Expected array") }
  match items.get(i) {
    Some(value) => value
    None => fail("Missing JSON item")
  }
}

///|
fn invalid(text : String, contains : String) -> Unit raise {
  guard result(text) is Err(error) else { fail("Expected invalid diary") }
  assert_true(error.contains(contains))
}

///|
test "period pairs aggregate canonical goals with exact source rows and unknown unmeasured goals" {
  let result = report(
    row(
      "watch-a",
      "2026-10-01",
      "2026-10-08",
      "60",
      "10",
      "5",
      "5",
      baseline_start="2026-09-01",
      baseline_end="2026-09-08",
    ) +
    row(
      "watch-a",
      "2026-10-08",
      "2026-10-15",
      "10",
      "10",
      "5",
      "5",
      baseline_start="2026-09-08",
      baseline_end="2026-09-15",
    ),
  )
  assert_eq(
    field(result, "contract"),
    Json::string("moontown.goal-effort-report.v1"),
  )
  let goals = field(result, "goals")
  let first = item(goals, 0)
  assert_eq(field(first, "goal_id"), Json::string("watch-a"))
  assert_eq(field(first, "target_book_id"), Json::string("book-a"))
  assert_eq(field(first, "source_goal"), Json::number(1))
  let totals = field(first, "totals")
  assert_eq(field(totals, "period_count"), Json::number(2))
  assert_eq(field(totals, "paired_periods"), Json::number(2))
  assert_eq(field(totals, "manual_minutes"), Json::number(70))
  assert_eq(field(totals, "town_minutes"), Json::number(40))
  assert_eq(field(totals, "manual_minus_town_minutes"), Json::number(30))
  let second_period = item(field(first, "periods"), 1)
  assert_eq(
    field(second_period, "manual_minus_town_minutes"),
    Json::number(-10),
  )
  assert_eq(
    field(second_period, "manual_period_start"),
    Json::string("2026-09-08"),
  )
  assert_eq(field(second_period, "source_data_row"), Json::number(2))
  let second = item(goals, 1)
  assert_eq(field(second, "enabled"), Json::boolean(false))
  assert_eq(field(field(second, "totals"), "period_count"), Json::number(0))
  assert_eq(
    field(field(second, "totals"), "manual_minus_town_minutes"),
    Json::null(),
  )
  assert_eq(field(field(second, "totals"), "town_minutes"), Json::null())
  assert_eq(field(result, "goal_source"), {
    "digest": "sha256:" +
    @crypto.bytes_to_hex_string(@crypto.sha256(goals_bytes())),
    "size_bytes": goals_bytes().length(),
  })
}

///|
test "missing baseline or component stays unknown and zero is measured" {
  let result = report(
    row("watch-a", "2026-01-01", "2026-01-02", "", "1", "2", "3") +
    row("watch-a", "2026-01-02", "2026-01-03", "20", "", "2", "3") +
    row("watch-a", "2026-01-03", "2026-01-04", "0", "0", "0", "0"),
  )
  let first = item(field(result, "goals"), 0)
  let totals = field(first, "totals")
  assert_eq(field(totals, "complete_town_periods"), Json::number(2))
  assert_eq(field(totals, "paired_periods"), Json::number(1))
  for
    name in [
      "manual_minutes", "review_minutes", "town_minutes", "manual_minus_town_minutes",
    ] {
    assert_eq(field(totals, name), Json::null())
  }
  assert_eq(field(totals, "supervision_minutes"), Json::number(4))
  let periods = field(first, "periods")
  assert_eq(field(item(periods, 0), "town_minutes"), Json::number(6))
  assert_eq(field(item(periods, 0), "manual_minus_town_minutes"), Json::null())
  assert_eq(field(item(periods, 0), "manual_period_start"), Json::null())
  assert_eq(field(item(periods, 1), "town_minutes"), Json::null())
  assert_eq(
    field(item(periods, 2), "manual_minus_town_minutes"),
    Json::number(0),
  )
}

///|
test "CSV TSV BOM Unicode and multiline notes retain values" {
  let csv = header() +
    row(
      "watch-a",
      "2024-02-29",
      "2024-03-01",
      "00060",
      "10",
      "5",
      "5",
      outcome="客户🙂",
      note="first\nsecond, \"quoted\"",
    )
  guard @goal_effort.report(
      goals_bytes(),
      @utf8.encode(csv),
      ',',
      format="json",
    )
    is Ok(output) else {
    fail("CSV failed")
  }
  let parsed = @json.parse(output)
  let period = item(field(item(field(parsed, "goals"), 0), "periods"), 0)
  assert_eq(field(period, "note"), Json::string("first\nsecond, \"quoted\""))
  assert_eq(field(period, "outcome"), Json::string("客户🙂"))
  assert_eq(field(period, "manual_minutes"), Json::number(60))
  // Replace only the quoted record separators, leaving the comma in the note intact.
  let tsv = "\uFEFF" +
    header().replace_all(old=",", new="\t") +
    row(
      "watch-a",
      "2024-02-29",
      "2024-03-01",
      "00060",
      "10",
      "5",
      "5",
      outcome="客户🙂",
      note="first\nsecond, \"quoted\"",
    ).replace_all(old="\",\"", new="\"\t\"")
  guard @goal_effort.report(
      goals_bytes(),
      @utf8.encode(tsv),
      '\t',
      format="json",
    )
    is Ok(tsv_output) else {
    fail("TSV failed")
  }
  assert_eq(
    field(item(field(@json.parse(tsv_output), "goals"), 0), "periods"),
    field(item(field(parsed, "goals"), 0), "periods"),
  )
}

///|
test "periods validate calendar days, equal lengths and both kinds of overlapping reuse" {
  let valid = report(
    row("watch-a", "2026-02-01", "2026-02-02", "1", "0", "0", "0") +
    row("watch-b", "2026-02-01", "2026-02-02", "1", "0", "0", "0") +
    row("watch-a", "2026-01-01", "2026-02-01", "1", "0", "0", "0"),
  )
  let periods = field(item(field(valid, "goals"), 0), "periods")
  assert_eq(field(item(periods, 0), "source_data_row"), Json::number(1))
  assert_eq(field(item(periods, 1), "source_data_row"), Json::number(3))
  for
    (start, end) in [
      ("2026-02-29", "2026-03-02"),
      ("1900-02-29", "1900-03-01"),
      ("2026-13-01", "2027-01-01"),
      ("0000-01-01", "2026-01-01"),
      ("2026-04-31", "2026-05-02"),
      ("2026-01-01", "2026-01-01"),
      ("2026-02-01", "2026-01-01"),
      ("2026-1-01", "2026-01-02"),
      ("2026-01-X1", "2026-01-02"),
    ] {
    assert_true(
      result(row("watch-a", start, end, "1", "0", "0", "0")) is Err(_),
    )
  }
  ignore(report(row("watch-a", "2000-02-29", "2000-03-01", "1", "0", "0", "0")))
  invalid(
    row("watch-a", "2026-01-01", "2026-01-10", "1", "0", "0", "0") +
    row("watch-a", "2026-01-02", "2026-01-03", "1", "0", "0", "0"),
    "Overlapping periods",
  )
  invalid(
    row(
      "watch-a",
      "2026-01-01",
      "2026-01-02",
      "1",
      "0",
      "0",
      "0",
      baseline_start="2025-01-01",
      baseline_end="2025-01-02",
    ) +
    row(
      "watch-a",
      "2026-01-02",
      "2026-01-03",
      "1",
      "0",
      "0",
      "0",
      baseline_start="2025-01-01",
      baseline_end="2025-01-02",
    ),
    "Overlapping manual",
  )
  invalid(
    row(
      "watch-a",
      "2026-01-01",
      "2026-01-02",
      "1",
      "0",
      "0",
      "0",
      baseline_start="2025-01-01",
      baseline_end="2025-01-03",
    ),
    "equal positive day",
  )
  invalid(
    row(
      "watch-a",
      "2026-01-01",
      "2026-01-02",
      "1",
      "0",
      "0",
      "0",
      baseline_start="",
      baseline_end="",
    ),
    "require explicit manual",
  )
  invalid(
    row(
      "watch-a",
      "2026-01-01",
      "2026-01-02",
      "",
      "0",
      "0",
      "0",
      baseline_start="2025-01-01",
      baseline_end="",
    ),
    "YYYY-MM-DD",
  )
}

///|
test "unknown IDs empty outcomes invalid numbers and schema fail" {
  invalid(
    row("unknown", "2026-01-01", "2026-01-02", "1", "0", "0", "0"),
    "Unknown goal_id",
  )
  invalid(
    row(
      "watch-a",
      "2026-01-01",
      "2026-01-02",
      "1",
      "0",
      "0",
      "0",
      outcome="   ",
    ),
    "common measured outcome",
  )
  for
    value in [
      "-1", "+1", "1.5", "NaN", " 1", "1 ", "100001", "1000000", "1e2", "１２",
    ] {
    invalid(
      row("watch-a", "2026-01-01", "2026-01-02", value, "0", "0", "0"),
      "Minutes must",
    )
  }
  let accepted = report(
    row(
      "watch-a", "2026-01-01", "2026-01-02", "100000", "100000", "100000", "100000",
    ),
  )
  assert_eq(
    field(
      field(item(field(accepted, "goals"), 0), "totals"),
      "manual_minus_town_minutes",
    ),
    Json::number(-200000),
  )
  assert_true(
    @goal_effort.report(
      goals_bytes(),
      b"goal_id\nwatch-a\n",
      ',',
      format="json",
    )
    is Err(_),
  )
  assert_true(result("watch-a,bad\n") is Err(_))
  assert_true(
    @goal_effort.report(
      goals_bytes(),
      @utf8.encode(header()),
      '|',
      format="json",
    )
    is Err(_),
  )
  assert_true(
    @goal_effort.report(
      goals_bytes(),
      @utf8.encode(header()),
      ',',
      format="html",
    )
    is Err(_),
  )
}

///|
test "canonical goals reject broken or ambiguous IDs and allow empty source" {
  for bytes in [b"{}", b"[{\"id\":\"watch-a\"}]"] {
    assert_true(
      @goal_effort.report(bytes, @utf8.encode(header()), ',', format="json")
      is Err(_),
    )
  }
  let goal = @core.StandingGoal::new(
    id="duplicate",
    title="Title",
    prompt="Prompt",
  )
  assert_true(
    @goal_effort.report(
      @utf8.encode([goal, goal].to_json().stringify()),
      @utf8.encode(header()),
      ',',
      format="json",
    )
    is Err(_),
  )
  let blank = @core.StandingGoal::new(id=" ", title="Title", prompt="Prompt")
  assert_true(
    @goal_effort.report(
      @utf8.encode([blank].to_json().stringify()),
      @utf8.encode(header()),
      ',',
      format="json",
    )
    is Err(_),
  )
  guard @goal_effort.report(b"[]", @utf8.encode(header()), ',', format="json")
    is Ok(output) else {
    fail("Empty sources")
  }
  assert_eq(field(@json.parse(output), "goals"), Json::array([]))
}

///|
test "CSV has every goal with safe text unknowns zeros and deterministic output" {
  let text = header() +
    row("watch-a", "2026-01-01", "2026-01-02", "0", "0", "0", "0")
  guard @goal_effort.report(
      goals_bytes(),
      @utf8.encode(text),
      ',',
      format="csv",
    )
    is Ok(csv) else {
    fail("CSV failed")
  }
  guard @table.parse_data_table(csv, ',') is Ok(table) else { fail("Bad CSV") }
  assert_eq(table.rows.length(), 2)
  assert_eq(table.rows[0][16], "0")
  assert_eq(table.rows[1][4], "'=Unmeasured")
  assert_eq(table.rows[1][8], "0")
  assert_eq(table.rows[1][15], "")
  assert_true(csv.has_suffix("\r\n"))
  assert_eq(
    @goal_effort.report(goals_bytes(), @utf8.encode(text), ',', format="csv"),
    Ok(csv),
  )
}

///|
test "byte row and output limits reject without truncation" {
  assert_true(
    @goal_effort.report(
      Bytes::make(1048577, 0x20),
      @utf8.encode(header()),
      ',',
      format="json",
    )
    is Err(_),
  )
  assert_true(
    @goal_effort.report(
      goals_bytes(),
      Bytes::make(1048577, 0x20),
      ',',
      format="json",
    )
    is Err(_),
  )
  assert_true(
    @goal_effort.report(b"\xff", @utf8.encode(header()), ',', format="json")
    is Err(_),
  )
  assert_true(
    @goal_effort.report(goals_bytes(), b"\xff", ',', format="json") is Err(_),
  )
  invalid(
    Array::make(
      2001,
      row("watch-a", "2026-01-01", "2026-01-02", "1", "0", "0", "0"),
    ).join(""),
    "2,000 periods",
  )
  let huge_note = Array::make(710000, "\u0001").join("")
  invalid(
    row(
      "watch-a",
      "2026-01-01",
      "2026-01-02",
      "1",
      "0",
      "0",
      "0",
      note=huge_note,
    ),
    "4 MiB",
  )
}

///|
test "maximum period count sums exactly and excess goal count fails" {
  let rows : Array[String] = []
  for year = 1; year <= 2000; year = year + 1 {
    let y = "0000" + year.to_string()
    let y = try! y[y.length() - 4:].to_string()
    rows.push(
      row(
        "watch-a",
        y + "-01-01",
        y + "-01-02",
        "100000",
        "100000",
        "100000",
        "100000",
      ),
    )
  }
  let result = report(rows.join(""))
  let totals = field(item(field(result, "goals"), 0), "totals")
  assert_eq(field(totals, "period_count"), Json::number(2000))
  assert_eq(field(totals, "town_minutes"), Json::number(600000000))
  assert_eq(
    field(totals, "manual_minus_town_minutes"),
    Json::number(-400000000),
  )
  let goals = Array::makei(2001, i => {
    @core.StandingGoal::new(
      id="goal-" + i.to_string(),
      title="Title",
      prompt="Prompt",
    )
  })
  guard @goal_effort.report(
      @utf8.encode(goals.to_json().stringify()),
      @utf8.encode(header()),
      ',',
      format="json",
    )
    is Err(error) else {
    fail("Accepted 2,001 goals")
  }
  assert_true(error.contains("2,000 entries"))
}
