///|
/// Close transient town surfaces before opening a new primary surface.
/// Keeping this list in one place prevents a newly added drawer from silently
/// stacking underneath an older modal or inspector.
fn close_town_transient_surfaces(model : Model) -> Model {
  {
    ..model,
    energy_board_open: false,
    energy_first_agent_open: false,
    energy_guide_open: false,
    energy_reset_open: false,
    energy_request_open: false,
    resident_explorer_open: false,
    town_chronicle_open: false,
    energy_selected_building: None,
    phone_open: false,
    square_open: false,
    ops_open: false,
    knowledge_dialog_open: false,
  }
}
