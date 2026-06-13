///|
fn civic_salon_reducer_output_path(
  scenario : CivicCommunicationScenario,
  workspace_base : String,
) -> String {
  civic_salon_reducer_output_path_in_workspace(
    civic_salon_workspace_root(scenario.building_book_id, workspace_base),
  )
}

///|
fn civic_salon_reducer_output_path_in_workspace(
  workspace_root : String,
) -> String {
  "\{workspace_root}/\{@civic.civic_reducer_output_relative_path()}"
}

///|
fn civic_salon_reducer_packet_path(
  scenario : CivicCommunicationScenario,
  round_id : String,
  workspace_base : String,
) -> String {
  "\{civic_salon_workspace_root(scenario.building_book_id, workspace_base)}/raw/bootstrap/civic-communication-reducer-\{scenario.id}-\{round_id}.packet.json"
}
