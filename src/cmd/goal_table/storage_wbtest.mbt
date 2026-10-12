///|
async test "table edit and reimport is readable by actual StandingGoal storage without changing the saved original" {
  let root = @env.get_env_var("MOONTOWN_TABLE_EVIDENCE").unwrap_or(
    "/tmp/moontown-goal-table-native-fixture",
  )
  if !@fs.exists(root) {
    @fs.mkdir(root, recursive=true)
  }
  let path = root + "/standing-goals.json"
  let original = [
    @core.StandingGoal::new(
      id="watch-customer",
      title="=Customer launch, 中文",
      prompt="Review the launch assumption.\nCite the exact source.",
      target_book_id=Some("research-customer"),
      cadence_ticks=60,
      next_due_tick=240,
      last_run_tick=Some(180),
      source_policy="local-material:plans/customer.json",
      quality_threshold=85,
    ),
    @core.StandingGoal::new(
      id="watch-paused",
      title="Paused market review",
      prompt="Keep this intent for later",
      cadence_ticks=120,
      next_due_tick=360,
      last_run_tick=None,
      enabled=false,
      source_policy="",
      quality_threshold=80,
    ),
    @core.StandingGoal::new(
      id="watch-unassigned",
      title="Literal empty Book ID",
      prompt="Retain an explicit empty target",
      target_book_id=Some(""),
      last_run_tick=Some(0),
      enabled=false,
    ),
  ]
  @storage.save_standing_goals_file(path, original)
  assert_eq(@storage.load_standing_goals_file(path), Some(original))
  let before = read_source(path)
  for (format, delimiter) in [("csv", ','), ("tsv", '\t')] {
    guard @transfer.snapshot_to_table(before, delimiter) is Ok(text) else {
      fail("export failed")
    }
    @fs.write_file(
      root + "/goals." + format,
      @utf8.encode(text),
      create_mode=CreateOrTruncate,
      permission=0o644,
    )
    guard @transfer.table_to_snapshot(@utf8.encode(text), delimiter)
      is Ok(roundtrip) else {
      fail("import failed")
    }
    let copy_path = root + "/roundtrip-" + format + ".json"
    @fs.write_file(
      copy_path,
      @utf8.encode(roundtrip),
      create_mode=CreateOrTruncate,
      permission=0o644,
    )
    assert_eq(@storage.load_standing_goals_file(copy_path), Some(original))
  }
  let csv = @utf8.decode(read_source(root + "/goals.csv"))
  // Edit human-facing declaration fields; preserve the durable ID/run/schedule state.
  let edited = csv
    .replace_all(old="Customer launch, 中文", new="Customer evidence review")
    .replace_all(old="\"60\",\"240\"", new="\"120\",\"240\"")
    .replace_all(old="\"180\",\"true\"", new="\"180\",\"false\"")
  @fs.write_file(
    root + "/edited-goals.csv",
    @utf8.encode(edited),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  guard @transfer.table_to_snapshot(@utf8.encode(edited), ',') is Ok(candidate) else {
    fail("edited import failed")
  }
  let candidate_path = root + "/candidate-goals.json"
  @fs.write_file(
    candidate_path,
    @utf8.encode(candidate),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  let first = original[0]
  let expected = [
    @core.StandingGoal::new(
      id=first.id,
      title="=Customer evidence review",
      prompt=first.prompt,
      target_book_id=first.target_book_id,
      cadence_ticks=120,
      next_due_tick=first.next_due_tick,
      last_run_tick=first.last_run_tick,
      enabled=false,
      source_policy=first.source_policy,
      quality_threshold=first.quality_threshold,
    ),
    original[1],
    original[2],
  ]
  assert_eq(@storage.load_standing_goals_file(candidate_path), Some(expected))
  @storage.save_standing_goals_file(root + "/expected-edited.json", expected)
  assert_eq(read_source(path), before)
  assert_eq(@storage.load_standing_goals_file(path), Some(original))
}
