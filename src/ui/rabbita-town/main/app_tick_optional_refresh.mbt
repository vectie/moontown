///|
fn refresh_version_changed(version : Int32, current_version : Int32) -> Bool {
  version != current_version
}

///|
fn[T] refresh_optional_snapshot(
  version : Int32,
  current_version : Int32,
  current : T?,
  parse : () -> T?,
) -> T? {
  if refresh_version_changed(version, current_version) {
    match parse() {
      Some(snapshot) => Some(snapshot)
      None => current
    }
  } else {
    current
  }
}

///|
fn[T] refresh_array_snapshot(
  version : Int32,
  current_version : Int32,
  current : Array[T],
  parse : () -> Array[T],
) -> Array[T] {
  if refresh_version_changed(version, current_version) {
    parse()
  } else {
    current
  }
}

///|
fn refresh_snapshot_file(
  version : Int32,
  current_version : Int32,
  current : ProjectionSnapshot?,
) -> ProjectionSnapshot? {
  refresh_optional_snapshot(
    version, current_version, current, parse_bootstrap_town_snapshot,
  )
}

///|
fn refresh_visual_projection(
  version : Int32,
  current_version : Int32,
  current : VisualProjectionSnapshot?,
) -> VisualProjectionSnapshot? {
  refresh_optional_snapshot(
    version, current_version, current, parse_bootstrap_visual_projection,
  )
}

///|
fn refresh_moondesk_bridge(
  version : Int32,
  current_version : Int32,
  current : MoondeskBridgeIndex?,
) -> MoondeskBridgeIndex? {
  refresh_optional_snapshot(
    version, current_version, current, parse_bootstrap_moondesk_bridge,
  )
}

///|
fn refresh_daemon_snapshot(
  version : Int32,
  current_version : Int32,
  current : DaemonSnapshot?,
) -> DaemonSnapshot? {
  refresh_optional_snapshot(
    version, current_version, current, parse_bootstrap_daemon_snapshot,
  )
}

///|
fn refresh_live_autonomy(
  version : Int32,
  current_version : Int32,
  current : LiveAutonomySnapshot?,
) -> LiveAutonomySnapshot? {
  refresh_optional_snapshot(
    version, current_version, current, parse_bootstrap_live_autonomy,
  )
}

///|
fn refresh_editor_pipeline(
  version : Int32,
  current_version : Int32,
  current : EditorPipelineSnapshot?,
) -> EditorPipelineSnapshot? {
  refresh_optional_snapshot(
    version, current_version, current, parse_bootstrap_editor_pipeline,
  )
}

///|
fn refreshed_state_source(
  model : Model,
  refreshed_snapshot : ProjectionSnapshot?,
) -> StateSourceKind {
  ignore(refreshed_snapshot)
  model.state_source
}
