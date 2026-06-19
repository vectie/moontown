///|
fn scene_render_test_state() -> @core.TownState {
  @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
}

///|
fn scene_render_register_book(
  state : @core.TownState,
  id? : String = "coding",
  name? : String = "Moonbook / Coding",
  purpose? : String = "Harness engineering for source work.",
  workspace_root? : String = "/workspace/coding",
  memory_scope? : @core.MemoryScope = BookPrivate,
) -> Unit {
  state.register_book(
    @core.BookRef::new(id~, name~, purpose~, workspace_root~, memory_scope~),
  )
}

///|
fn scene_render_register_harness_worker(
  state : @core.TownState,
  book_id? : String = "coding",
) -> Unit {
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-harness",
      name="Harness Hound",
      book_id~,
      role=Harness,
    ),
  )
}

///|
fn scene_render_enqueue_task(
  state : @core.TownState,
  id~ : String,
  title~ : String,
  prompt~ : String,
  domain? : @core.WorkDomain = Coding,
  book_id? : String = "coding",
  required_role? : @core.WorkerRole? = None,
) -> Unit {
  state.enqueue_task(
    @core.TownTask::new(id~, book_id~, title~, prompt~, domain~, required_role~),
  )
}

///|
fn scene_render_register_execution(
  state : @core.TownState,
  task_id~ : String,
  status~ : @core.TaskExecutionStatus,
  summary~ : String,
  output_contract~ : String,
  book_id? : String = "coding",
  packet_id? : String = "",
) -> Unit {
  let resolved_packet_id = if packet_id == "" {
    "packet-\{task_id}"
  } else {
    packet_id
  }
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id~,
      book_id~,
      packet_id=resolved_packet_id,
      packet_path="/tmp/\{resolved_packet_id}.json",
      status~,
      summary~,
      output_contract~,
    ),
  )
}

///|
fn scene_render_dashboard(state : @core.TownState) -> @ui.DashboardModel {
  @ui.build_dashboard(state, @health.inspect_town(state))
}
