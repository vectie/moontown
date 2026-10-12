///|
async test "effort import consumes an actual saved StandingGoal file and preserves both inputs" {
  let root = @env.get_env_var("MOONTOWN_EFFORT_EVIDENCE").unwrap_or(
    "/tmp/moontown-goal-effort-native-fixture",
  )
  if !@fs.exists(root) {
    @fs.mkdir(root, recursive=true)
  }
  let path = root + "/standing-goals.json"
  let diary_path = root + "/effort.csv"
  let goals = [
    @core.StandingGoal::new(
      id="watch-customer",
      title="Customer launch evidence",
      prompt="Review the launch assumption",
      target_book_id=Some("research-customer"),
    ),
    @core.StandingGoal::new(
      id="watch-market",
      title="Market evidence 未测量",
      prompt="Review market evidence",
      target_book_id=Some("research-market"),
    ),
    @core.StandingGoal::new(
      id="watch-heavy",
      title="High supervision effort",
      prompt="Review procurement evidence",
      target_book_id=Some("research-procurement"),
    ),
    @core.StandingGoal::new(
      id="watch-paused",
      title="=Paused and unmeasured",
      prompt="Retain this goal",
      enabled=false,
    ),
  ]
  @storage.save_standing_goals_file(path, goals)
  assert_eq(@storage.load_standing_goals_file(path), Some(goals))
  let diary = "goal_id,period_start,period_end,outcome,manual_period_start,manual_period_end,manual_minutes,review_minutes,supervision_minutes,followup_minutes,note\nwatch-customer,2026-10-01,2026-10-08,Review five launch sources,2026-09-01,2026-09-08,60,10,5,5,Manually timed comparable source set\nwatch-market,2026-10-01,2026-10-08,Review market assumption,,,,5,5,5,Manual baseline was not measured\nwatch-customer,2026-10-08,2026-10-15,Review five launch sources,2026-09-08,2026-09-15,10,10,5,5,\"Second comparison\nIncludes handoff time\"\nwatch-heavy,2026-10-01,2026-10-08,Review two procurement changes,2026-09-01,2026-09-08,5,10,5,2,Town effort was higher\n"
  @fs.write_file(
    diary_path,
    @utf8.encode(diary),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  let before_goals = read_source(path)
  let before_diary = read_source(diary_path)
  for format in ["json", "csv"] {
    guard @effort.report(before_goals, before_diary, ',', format~) is Ok(output) else {
      fail("Saved-goal effort report failed")
    }
    @fs.write_file(
      root + "/expected." + format,
      @utf8.encode(output),
      create_mode=CreateOrTruncate,
      permission=0o644,
    )
  }
  assert_eq(read_source(path), before_goals)
  assert_eq(read_source(diary_path), before_diary)
  assert_eq(@storage.load_standing_goals_file(path), Some(goals))
}
