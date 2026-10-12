///|
fn snapshot(goals : Array[@core.StandingGoal]) -> Bytes {
  @utf8.encode(goals.to_json().stringify())
}

///|
fn success(result : Result[String, String]) -> String raise {
  match result {
    Ok(value) => value
    Err(error) => fail(error)
  }
}

///|
fn decoded(text : String) -> Array[@core.StandingGoal] raise {
  @json.from_json(@json.parse(text))
}

///|
fn quote(text : String) -> String {
  "\"" + text.replace_all(old="\"", new="\"\"") + "\""
}

///|
fn table_text(table : @table.DataTable, delimiter : Char) -> String {
  let lines = [table.headers.map(quote).join(delimiter.to_string())]
  for row in table.rows {
    lines.push(row.map(quote).join(delimiter.to_string()))
  }
  lines.join("\r\n") + "\r\n"
}

///|
fn fixture() -> Array[@core.StandingGoal] {
  [
    @core.StandingGoal::new(
      id="watch-a",
      title="=Review \"launch\", 中文 🌙",
      prompt="First line\nSecond\r\nTab\tBackslash\\ and NUL\u0000",
      target_book_id=Some("research-customer"),
      cadence_ticks=60,
      next_due_tick=240,
      last_run_tick=Some(180),
      source_policy="local-material:plans/customer.json",
      quality_threshold=85,
    ),
    @core.StandingGoal::new(
      id="watch-b",
      title="'literal",
      prompt="@pending",
      enabled=false,
    ),
  ]
}

///|
fn fixture_table() -> @table.DataTable raise {
  let csv = success(@goal_table.snapshot_to_table(snapshot(fixture()), ','))
  match @table.parse_data_table(csv, ',') {
    Ok(table) => table
    Err(error) => fail(error)
  }
}

///|
fn invalid_table(table : @table.DataTable, expected : String) -> Unit raise {
  guard @goal_table.table_to_snapshot(@utf8.encode(table_text(table, ',')), ',')
    is Err(error) else {
    fail("Expected table failure")
  }
  assert_true(error.contains(expected))
}

///|
test "CSV and BOM TSV round trip every real StandingGoal field including source policy and run state" {
  let goals = fixture()
  for delimiter in [',', '\t'] {
    let text = success(
      @goal_table.snapshot_to_table(snapshot(goals), delimiter),
    )
    let result = success(
      @goal_table.table_to_snapshot(@utf8.encode("\uFEFF" + text), delimiter),
    )
    assert_eq(decoded(result), goals)
    let table = match @table.parse_data_table(text, delimiter) {
      Ok(t) => t
      Err(e) => fail(e)
    }
    assert_eq(table.rows[0][0], "\"watch-a\"")
    assert_true(table.rows[0][1].has_prefix("\"="))
    assert_eq(table.rows[0][3], "\"research-customer\"")
    assert_eq(table.rows[0][4], "60")
    assert_eq(table.rows[0][5], "240")
    assert_eq(table.rows[0][6], "180")
    assert_eq(table.rows[1][3], "null")
    assert_eq(table.rows[1][6], "null")
    assert_eq(table.rows[1][7], "false")
  }
}

///|
test "editing changes only selected declaration fields and table order is snapshot order" {
  let table = fixture_table()
  table.rows[0][1] = "\"Edited launch review\""
  table.rows[0][4] = "120"
  table.rows[0][7] = "false"
  let edited = decoded(
    success(
      @goal_table.table_to_snapshot(@utf8.encode(table_text(table, ',')), ','),
    ),
  )
  let old = fixture()[0]
  assert_eq(
    edited[0],
    @core.StandingGoal::new(
      id=old.id,
      title="Edited launch review",
      prompt=old.prompt,
      target_book_id=old.target_book_id,
      cadence_ticks=120,
      next_due_tick=old.next_due_tick,
      last_run_tick=old.last_run_tick,
      enabled=false,
      source_policy=old.source_policy,
      quality_threshold=old.quality_threshold,
    ),
  )
  assert_eq(edited[1], fixture()[1])
  let reordered : @table.DataTable = {
    headers: table.headers,
    rows: [table.rows[1], table.rows[0]],
  }
  assert_eq(
    decoded(
      success(
        @goal_table.table_to_snapshot(
          @utf8.encode(table_text(reordered, ',')),
          ',',
        ),
      ),
    ),
    [edited[1], edited[0]],
  )
  let subset : @table.DataTable = {
    headers: table.headers,
    rows: [table.rows[1]],
  }
  assert_eq(
    decoded(
      success(
        @goal_table.table_to_snapshot(
          @utf8.encode(table_text(subset, ',')),
          ',',
        ),
      ),
    ),
    [edited[1]],
  )
  table.rows[0][0] = "\"new-goal\""
  assert_eq(
    decoded(
      success(
        @goal_table.table_to_snapshot(@utf8.encode(table_text(table, ',')), ','),
      ),
    )[0].id,
    "new-goal",
  )
}

///|
test "nullable target and last-run preserve empty strings null text zero and signed Int boundaries" {
  let absent = @core.StandingGoal::new(id="optional", title="", prompt="")
  let with_null = absent
    .to_json()
    .stringify()
    .replace_all(
      old="\"id\":",
      new="\"target_book_id\":null,\"last_run_tick\":null,\"id\":",
    )
  // Canonical storage encodes None by omitting a field; explicit JSON null is
  // not accepted by its derived decoder. Table null converts to omission.
  assert_true(
    @goal_table.snapshot_to_table(@utf8.encode("[" + with_null + "]"), ',')
    is Err(_),
  )
  let goals = [
    @core.StandingGoal::new(
      id="a",
      title="",
      prompt="",
      target_book_id=Some(""),
      last_run_tick=Some(0),
    ),
    @core.StandingGoal::new(
      id="b",
      title="null",
      prompt="null",
      target_book_id=Some("null"),
      cadence_ticks=-2147483648,
      next_due_tick=2147483647,
      last_run_tick=Some(-2147483648),
      quality_threshold=-1,
    ),
  ]
  assert_eq(
    decoded(
      success(
        @goal_table.table_to_snapshot(
          @utf8.encode(
            success(@goal_table.snapshot_to_table(snapshot(goals), ',')),
          ),
          ',',
        ),
      ),
    ),
    goals,
  )
}

///|
test "invalid table data fails as a whole with a row diagnostic" {
  for
    (index, value, expected) in [
      (0, "\"   \"", "blank ID"),
      (0, "\"watch-b\"", "duplicates"),
      (1, "unquoted title", "Data row 1"),
      (1, "42", "JSON string"),
      (3, "false", "Target Book"),
      (3, "\"unterminated", "Data row 1"),
      (4, "2147483648", "32-bit"),
      (4, "-2147483649", "32-bit"),
      (4, "+1", "decimal"),
      (5, "1.5", "decimal"),
      (6, "", "decimal"),
      (6, "NaN", "decimal"),
      (7, "TRUE", "true or false"),
      (8, "null", "JSON string"),
      (9, " 80", "decimal"),
    ] {
    let table = fixture_table()
    table.rows[0][index] = value
    invalid_table(table, expected)
  }
  let table = fixture_table()
  table.headers[0] = "id"
  invalid_table(table, "Columns must be exactly")
  assert_true(
    @goal_table.table_to_snapshot(b"id_json\n\"broken", ',') is Err(_),
  )
  assert_true(@goal_table.table_to_snapshot(b"a,b\n1\n", ',') is Err(_))
  assert_true(@goal_table.table_to_snapshot([0xff], ',') is Err(_))
  assert_true(@goal_table.table_to_snapshot(b"anything", ';') is Err(_))
}

///|
test "snapshot rejects unknown fields malformed types duplicate and blank IDs instead of discarding them" {
  let original = fixture()[0].to_json().stringify()
  let extra = original.replace_all(
    old="\"id\":",
    new="\"future_field\":true,\"id\":",
  )
  guard @goal_table.snapshot_to_table(@utf8.encode("[" + extra + "]"), ',')
    is Err(error) else {
    fail("unknown field must fail")
  }
  assert_true(error.contains("unknown field"))
  assert_true(
    @goal_table.snapshot_to_table(snapshot([fixture()[0], fixture()[0]]), ',')
    is Err(_),
  )
  assert_true(
    @goal_table.snapshot_to_table(
      snapshot([@core.StandingGoal::new(id="", title="x", prompt="y")]),
      ',',
    )
    is Err(_),
  )
  for
    text in [
      "{}",
      "[1]",
      "[{}]",
      "[" +
      original.replace_all(
        old="\"cadence_ticks\":60",
        new="\"cadence_ticks\":1.5",
      ) +
      "]",
    ] {
    assert_true(
      @goal_table.snapshot_to_table(@utf8.encode(text), ',') is Err(_),
    )
  }
  assert_true(@goal_table.snapshot_to_table([0xff], ',') is Err(_))
  assert_true(@goal_table.snapshot_to_table(b"[]", ';') is Err(_))
}

///|
test "empty snapshots and limits are explicit and successful exports remain importable" {
  let empty = success(@goal_table.snapshot_to_table(b"[]", ','))
  assert_eq(
    success(@goal_table.table_to_snapshot(@utf8.encode(empty), ',')),
    "[]\n",
  )
  let goals = Array::makei(2000, i => {
    @core.StandingGoal::new(id="g" + i.to_string(), title="", prompt="")
  })
  let csv = success(@goal_table.snapshot_to_table(snapshot(goals), ','))
  assert_eq(
    decoded(success(@goal_table.table_to_snapshot(@utf8.encode(csv), ','))),
    goals,
  )
  goals.push(@core.StandingGoal::new(id="extra", title="", prompt=""))
  assert_true(@goal_table.snapshot_to_table(snapshot(goals), ',') is Err(_))
  let table = fixture_table()
  let too_many : @table.DataTable = {
    headers: table.headers,
    rows: Array::makei(2001, _ => table.rows[0]),
  }
  invalid_table(too_many, "2,000")
  let huge = @utf8.encode(" ".repeat(1048577))
  assert_true(@goal_table.snapshot_to_table(huge, ',') is Err(_))
  assert_true(@goal_table.table_to_snapshot(huge, ',') is Err(_))
  // JSON escaping plus CSV quote escaping can make an export exceed the bound.
  let big_goal = @core.StandingGoal::new(
    id="large",
    title="",
    prompt="\"".repeat(400000),
  )
  guard @goal_table.snapshot_to_table(snapshot([big_goal]), ',') is Err(error) else {
    fail("oversized output must fail")
  }
  assert_true(error.contains("Output exceeds"))
}
