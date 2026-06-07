///|
fn worker_sims(model : Model) -> Array[WorkerSim] {
  [
    build_worker_sim(
      model,
      id="agent-town-shell",
      title="Town Shell Foreman",
      role="Projection Harness",
      book_id="wenyu-town-shell",
      offset=0,
    ),
    build_worker_sim(
      model,
      id="agent-resident",
      title="Twin Keeper",
      role="Resident Memory Keeper",
      book_id="wenyu-resident-twins",
      offset=1,
    ),
    build_worker_sim(
      model,
      id="agent-policy",
      title="Policy Sprite",
      role="Policy Advisor",
      book_id="policy-hall",
      offset=2,
    ),
    build_worker_sim(
      model,
      id="agent-contest",
      title="Contest Conductor",
      role="Roadshow Planner",
      book_id="wenyu-contest-express",
      offset=3,
    ),
    build_worker_sim(
      model,
      id="agent-social",
      title="Cafe Matchmaker",
      role="Social Operator",
      book_id="social-square",
      offset=4,
    ),
    build_worker_sim(
      model,
      id="agent-talent",
      title="Talent Cartographer",
      role="Memory Keeper",
      book_id="talent-avenue",
      offset=5,
    ),
    build_worker_sim(
      model,
      id="agent-garden",
      title="AI Garden Tutor",
      role="Planner",
      book_id="ai-garden",
      offset=6,
    ),
    build_worker_sim(
      model,
      id="agent-robot",
      title="Physical Bridge Link",
      role="Watcher",
      book_id="wenyu-physical-bridge",
      offset=7,
    ),
  ]
}

///|
fn build_worker_sim(
  model : Model,
  id~ : String,
  title~ : String,
  role~ : String,
  book_id~ : String,
  offset~ : Int,
) -> WorkerSim {
  let status = worker_status_for(model, offset)
  let zone_key = worker_zone_key(book_id, status)
  let load = worker_load(model, offset, status)
  let idle_bonus = if status == @core.WorkerStatus::Idle { 8 } else { 0 }
  let energy = clamp_metric(model.energy - offset * 5 + idle_bonus)
  {
    id,
    title,
    role,
    book_id,
    status,
    zone_key,
    energy,
    load,
    summary: worker_summary(status, load),
  }
}
