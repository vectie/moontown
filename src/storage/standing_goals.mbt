///|
pub fn default_standing_goal_path() -> String {
  ".moontown/standing-goals.json"
}

///|
pub fn default_standing_goals() -> Array[@core.StandingGoal] {
  [
    @core.StandingGoal::new(
      id="watch-opc-news",
      title="Track One Person Company news",
      prompt="Research the latest news, evidence, risks, examples, and strategic implications about One Person Company (OPC). Use web search first, fetch and screen sources, update the research-opc book wiki with source cards, claims, timeline notes, and a short digest.",
      target_book_id=Some("research-opc"),
      cadence_ticks=60,
      next_due_tick=0,
      source_policy=@policy.web_first_policy(),
      quality_threshold=85,
    ),
  ]
}

///|
pub async fn save_standing_goals_file(
  path : String,
  goals : Array[@core.StandingGoal],
) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(goals.to_json().stringify()),
    create=0o644,
    truncate=true,
  )
}

///|
pub async fn load_standing_goals_file(
  path : String,
) -> Array[@core.StandingGoal]? {
  if !@fs.exists(path) {
    return None
  }
  let text = @fs.read_file(path).text()
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
pub async fn load_or_create_standing_goals(
  path? : String = default_standing_goal_path(),
) -> Array[@core.StandingGoal] {
  match load_standing_goals_file(path) {
    Some(goals) => goals
    None => {
      let goals = default_standing_goals()
      save_standing_goals_file(path, goals)
      goals
    }
  }
}
