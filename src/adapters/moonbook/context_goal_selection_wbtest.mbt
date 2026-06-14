///|
test "standing watch context hydration uses task prompt over bare goal" {
  let task = moonbook_adapter_task(
    id="standing-watch-opc-news-tick-1",
    goal=Some("Research latest One Person Company news."),
    title="Standing watch",
    kind=@standing_watch_contracts.standing_watch_task_kind(),
    prompt="This is a MoonBook-owned 24/7 standing-watch cycle.\nstanding_goal_decision: update | no_change | needs_review | failed",
    priority=95,
    requires_review=false,
  )
  let goal = context_goal_for_task(task)
  assert_true(goal.contains("24/7 standing-watch"))
  assert_true(goal.contains("standing_goal_decision"))
  assert_true(!goal.contains("Research latest One Person Company news."))
}

///|
test "regular context hydration still honors explicit task goal" {
  let task = moonbook_adapter_task(
    id="research-opc-bootstrap",
    goal=Some("Research One Person Company."),
    title="Bootstrap",
    kind="bootstrap_gather",
    prompt="Detailed bootstrap prompt",
    priority=100,
    requires_review=true,
  )
  assert_eq(context_goal_for_task(task), "Research One Person Company.")
}
