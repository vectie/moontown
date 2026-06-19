///|
struct LiveAutonomyTestWorkspace {
  root : String
  snapshot_path : String
}

///|
async fn live_autonomy_test_workspace(
  root : String,
) -> LiveAutonomyTestWorkspace {
  @support.ignore_checked_command("rm", ["-rf", root])
  { root, snapshot_path: "\{root}/town.json" }
}

///|
fn live_autonomy_empty_test_state() -> @core.TownState {
  @core.empty_state(@core.TownConfig::new(id="test-town", name="Test Town"))
}

///|
fn live_autonomy_build_input_fixture(
  state? : @core.TownState = live_autonomy_empty_test_state(),
  standing_goals? : Array[@core.StandingGoal] = [],
  watcher_records? : Array[@core.WatcherRunRecord] = [],
  tick_summary? : String = "test tick",
  daemon_tick? : Int? = None,
  planbook_open? : Int = 0,
  planbook_repair_active? : Int = 0,
) -> LiveAutonomyBuildInput {
  let snapshot_path = "/tmp/moontown-live-autonomy-build-input/town.json"
  {
    state,
    snapshot_path,
    standing_goals,
    watcher_records,
    tick_summary,
    daemon_tick,
    planbook_open,
    planbook_repair_active,
    planbook_change_log_path: "/tmp/moontown-live-autonomy-build-input/change.log",
    planbook_engineering_digest_path: "/tmp/moontown-live-autonomy-build-input/digest.md",
    latest_change_summary: "none",
    book_template_request_status: @book_templates.empty_request_status(
      request_path=@book_templates.request_path_for_snapshot(snapshot_path),
      event_path=@book_templates.request_event_path_for_request(
        @book_templates.request_path_for_snapshot(snapshot_path),
      ),
    ),
    prior_stable_waiting_observation_streak: 0,
  }
}
