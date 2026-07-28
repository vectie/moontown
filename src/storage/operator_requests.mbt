///|
priv struct OperatorRequestRecord {
  status : String
  title : String
  prompt : String
  target_book_id : String
  cadence_ticks : Int
  source_policy : String
  quality_threshold : Int
  standing_goal_id : String
} derive(FromJson)

///|
fn default_operator_request_ledger_path() -> String {
  moontown_product_artifact("operator-requests/requests.jsonl")
}

///|
async fn load_accepted_operator_request_goals_file(
  path : String,
) -> Array[@core.StandingGoal] {
  let mut goals : Array[@core.StandingGoal] = []
  if !@fs.exists(path) {
    return goals
  }
  let text = @fs.read_file(path).text() catch { _ => return goals }
  for raw in text.split("\n") {
    let line = raw.trim().to_owned()
    if line.is_empty() {
      continue
    }
    let parsed = @json.parse(line) catch { _ => continue }
    let request : OperatorRequestRecord = @json.from_json(parsed) catch {
      _ => continue
    }
    if request.status != "accepted" ||
      request.standing_goal_id.trim().is_empty() {
      continue
    }
    let goal = @core.StandingGoal::new(
      id=request.standing_goal_id,
      title=request.title,
      prompt=request.prompt,
      target_book_id=Some(request.target_book_id),
      cadence_ticks=request.cadence_ticks,
      next_due_tick=0,
      enabled=true,
      source_policy=request.source_policy,
      quality_threshold=request.quality_threshold,
    )
    goals = @core.standing_goal_registry_replace_or_append(goals, goal)
  }
  goals
}

///|
pub async fn merge_accepted_operator_request_goals(
  goals : Array[@core.StandingGoal],
  path? : String = default_operator_request_ledger_path(),
) -> Array[@core.StandingGoal] {
  let merged = goals.copy()
  for recovered in load_accepted_operator_request_goals_file(path) {
    if @core.standing_goal_registry_find(merged, recovered.id) is None {
      merged.push(recovered)
    }
  }
  merged
}
