///|
fn civic_salon_reducer_output_path(
  scenario : CivicSalonScenario,
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
  "\{workspace_root}/raw/bootstrap/civic-salon-ideas.json"
}

///|
fn civic_salon_reducer_packet_path(
  scenario : CivicSalonScenario,
  round_id : String,
  workspace_base : String,
) -> String {
  "\{civic_salon_workspace_root(scenario.building_book_id, workspace_base)}/raw/bootstrap/civic-salon-reducer-\{scenario.id}-\{round_id}.packet.json"
}
