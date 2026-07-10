///|
fn refresh_version_changed(version : Int, current_version : Int) -> Bool {
  version != current_version
}

///|
fn[T] refresh_optional_snapshot(
  version : Int,
  current_version : Int,
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
  version : Int,
  current_version : Int,
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
  version : Int,
  current_version : Int,
  current : ProjectionSnapshot?,
) -> ProjectionSnapshot? {
  refresh_optional_snapshot(
    version, current_version, current, parse_bootstrap_town_snapshot,
  )
}

///|
fn refresh_visual_projection(
  version : Int,
  current_version : Int,
  current : VisualProjectionSnapshot?,
) -> VisualProjectionSnapshot? {
  refresh_optional_snapshot(
    version, current_version, current, parse_bootstrap_visual_projection,
  )
}

///|
fn refresh_moondesk_bridge(
  version : Int,
  current_version : Int,
  current : MoondeskBridgeIndex?,
) -> MoondeskBridgeIndex? {
  refresh_optional_snapshot(
    version, current_version, current, parse_bootstrap_moondesk_bridge,
  )
}

///|
fn refresh_daemon_snapshot(
  version : Int,
  current_version : Int,
  current : DaemonSnapshot?,
) -> DaemonSnapshot? {
  refresh_optional_snapshot(
    version, current_version, current, parse_bootstrap_daemon_snapshot,
  )
}

///|
fn refresh_live_autonomy(
  version : Int,
  current_version : Int,
  current : LiveAutonomySnapshot?,
) -> LiveAutonomySnapshot? {
  refresh_optional_snapshot(
    version, current_version, current, parse_bootstrap_live_autonomy,
  )
}

///|
fn refresh_editor_pipeline(
  version : Int,
  current_version : Int,
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
