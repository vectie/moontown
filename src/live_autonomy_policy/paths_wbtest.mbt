///|
test "live autonomy policy derives spine paths from snapshot directory" {
  assert_eq(
    live_autonomy_path_for_snapshot("/tmp/moontown/town.json"),
    "/tmp/moontown/live-autonomy.json",
  )
  assert_eq(
    live_autonomy_path_for_snapshot("town.json"),
    ".moontown/live-autonomy.json",
  )
  assert_eq(
    town_journal_path_for_snapshot(".moontown/town.json"),
    ".moontown/town-journal.jsonl",
  )
  assert_eq(
    live_digest_path_for_snapshot(".moontown/town.json"),
    ".moontown/live-digest.md",
  )
  assert_eq(
    live_autonomy_standing_goal_path_for_snapshot("/tmp/moontown/town.json"),
    "/tmp/moontown/standing-goals.json",
  )
}

///|
test "live autonomy policy derives planbook history paths from workspace" {
  assert_eq(
    planbook_change_log_path_for_workspace(".moontown/books/planbook"),
    ".moontown/books/planbook/wiki/history/change-log.md",
  )
  assert_eq(
    planbook_engineering_digest_path_for_workspace(".moontown/books/planbook"),
    ".moontown/books/planbook/wiki/history/daily-engineering-digest.md",
  )
}
