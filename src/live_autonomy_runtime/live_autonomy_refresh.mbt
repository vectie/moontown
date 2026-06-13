///|
pub async fn refresh_live_autonomy_spine(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  match @storage.load_snapshot_file(snapshot_path) {
    Some(snapshot) => {
      let inputs = load_live_autonomy_runtime_inputs(
        snapshot_path,
        snapshot.town,
      )
      @visual_projection_runtime.persist_visual_projection(
        snapshot.town,
        snapshot_path,
      )
      let spine = write_live_autonomy_refresh_spine(
        snapshot.town,
        snapshot_path,
        inputs,
        "manual live autonomy refresh",
      )
      live_autonomy_refresh_message(spine, snapshot_path, true)
    }
    None => {
      let inputs = load_live_autonomy_runtime_inputs_without_snapshot(
        snapshot_path,
      )
      let spine = write_live_autonomy_refresh_spine(
        empty_live_autonomy_state(),
        snapshot_path,
        inputs,
        "manual live autonomy refresh without saved town snapshot",
      )
      live_autonomy_refresh_message(spine, snapshot_path, false)
    }
  }
}

///|
async fn write_live_autonomy_refresh_spine(
  state : @core.TownState,
  snapshot_path : String,
  inputs : LiveAutonomyRuntimeInputs,
  tick_summary : String,
) -> LiveAutonomySpine {
  write_live_autonomy_spine(
    state,
    snapshot_path~,
    standing_goals=inputs.standing_goals,
    watcher_records=inputs.watcher_records,
    tick_summary~,
    daemon_tick=Some(inputs.daemon_tick),
  )
}

///|
fn live_autonomy_refresh_message(
  spine : LiveAutonomySpine,
  snapshot_path : String,
  snapshot_found : Bool,
) -> String {
  let destination = default_live_autonomy_path(snapshot_path~)
  if snapshot_found {
    "Refreshed live autonomy spine at \{destination}: \{spine.summary}"
  } else {
    "Refreshed live autonomy spine without saved town snapshot at \{destination}: \{spine.summary}"
  }
}

///|
fn empty_live_autonomy_state() -> @core.TownState {
  @core.empty_state(
    @core.TownConfig::new(
      id="moontown-live-autonomy",
      name="Moontown Live Autonomy",
    ),
  )
}
