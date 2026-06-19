///|
fn standing_watch_task(
  goal : @core.StandingGoal,
  target_book_id : String,
  tick : Int,
  no_change_streak : Int,
) -> @moonbook.BookTask {
  @moonbook.BookTask::new(
    id=@standing_watch_policy.standing_watch_task_id(goal.id, tick),
    goal=Some(goal.prompt),
    title="Standing watch: \{goal.title}",
    kind=@standing_watch_policy.standing_watch_task_kind(),
    prompt=@standing_watch_policy.standing_watch_prompt(
      goal, target_book_id, tick, no_change_streak,
    ),
    priority=95,
    requires_review=false,
    target_pages=@standing_watch_policy.standing_watch_target_pages(),
    required_role=Some(Watcher),
  )
}
