///|
fn visual_agent_projection(
  state : @core.TownState,
  worker : @core.WorkerRef,
) -> VisualAgentProjection {
  let execution = visual_latest_execution_for_worker(state, worker)
  let phase = visual_agent_phase(worker, execution)
  let status = visual_worker_status(worker.status)
  let book_title = visual_book_title(state, worker.book_id)
  let task_id = execution.map(fn(record) { record.task_id })
  let task_title = task_id.map(fn(id) { visual_task_title(state, id) })
  let run_id = match execution {
    Some(record) => record.run_id
    None => None
  }
  let grid = visual_agent_grid(worker.book_id, worker.id, phase)
  {
    worker_id: worker.id,
    worker_name: worker.name,
    book_id: worker.book_id,
    book_title,
    role: worker.role.to_string(),
    status,
    phase,
    task_id,
    task_title,
    run_id,
    sprite_key: visual_sprite_key(worker.id),
    zone_key: visual_zone_key(worker.book_id, phase, worker.status),
    location: visual_location_label(worker.book_id, phase),
    destination: visual_destination_label(worker.book_id, phase),
    behavior: visual_behavior_for_phase(phase),
    effect: visual_effect_for_phase(phase),
    visible_on_overworld: visual_agent_visible_on_overworld(phase),
    message: visual_agent_message(worker, book_title, task_title, phase),
    grid_x: grid.0,
    grid_y: grid.1,
    z: grid.0 + grid.1,
  }
}
