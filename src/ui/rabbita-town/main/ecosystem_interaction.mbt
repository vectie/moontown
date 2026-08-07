///|
fn ecosystem_focused_place_id(model : Model) -> String {
  match model.energy_selected_building {
    Some(building) => ecosystem_place_profile_for_building(building).id
    None => ""
  }
}

///|
fn ecosystem_attention_signal_for_action(
  model : Model,
  cooldown_key : String,
  interaction_target : String,
) -> EcosystemAttentionSignal? {
  let seed = active_energy_valley_seed()
  for
    signal in ecosystem_attention_candidates(
      model,
      seed,
      ecosystem_focused_place_id(model),
    ) {
    if signal.cooldown_key == cooldown_key &&
      signal.interaction_target == interaction_target {
      return Some(signal)
    }
  }
  None
}

///|
fn ecosystem_building_for_profile_id(
  model : Model,
  profile_id : String,
) -> GoldenValleyBuilding? {
  let buildings = golden_valley_buildings(active_energy_valley_seed())
  for building in energy_valley_model_buildings(model) {
    buildings.push(building)
  }
  for building in buildings {
    if ecosystem_place_profile_for_building(building).id == profile_id {
      return Some(building)
    }
  }
  None
}

///|
/// Acting on a surfaced signal both acknowledges it (so salience can cool
/// down instead of nagging) and opens the real semantic target. Ambient
/// residents lead to their scheduled place; runtime signals lead to the
/// evidence-backed Agent detail rather than pretending the preview is work.
fn ecosystem_open_attention_update(
  model : Model,
  cooldown_key : String,
  interaction_target : String,
) -> (Cmd, Model) {
  match
    ecosystem_attention_signal_for_action(
      model, cooldown_key, interaction_target,
    ) {
    None => model_only_update(model)
    Some(signal) => {
      let acknowledged = town_life_record_attention(
        model,
        signal.cooldown_key,
        model.tick,
      )
      let tracked = track_event(
        acknowledged,
        "ecosystem_attention_open",
        "\{ecosystem_provenance_short(signal.provenance)}:\{signal.place_id}",
      )
      if interaction_target.has_prefix("runtime:") {
        town_life_commit({
          ..close_town_transient_surfaces(tracked),
          selection: Agent(interaction_target),
          energy_status_open: false,
        })
      } else {
        match ecosystem_building_for_profile_id(tracked, signal.place_id) {
          Some(building) => {
            let next = {
              ..close_town_transient_surfaces(tracked),
              selection: Overview,
              energy_selected_building: Some(building),
              energy_status_open: false,
            }
            town_life_commit(complete_quest(next, "visit-building"))
          }
          None => town_life_commit(tracked)
        }
      }
    }
  }
}
