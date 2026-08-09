///|
/// Town-life update handlers: one place that turns the new social/gamification
/// messages into model transitions, always paired with persistence and
/// analytics. Keeping them together keeps app_lifecycle.mbt readable.
fn town_life_tick(model : Model) -> Model {
  let mut next = model
  if !next.life_toast.is_empty() && next.tick - next.life_toast_tick >= 5 {
    next = { ..next, life_toast: "" }
  }
  let phone_before = next.phone_log.length()
  let reports_before = next.ops_reports.length()
  let quests_before = next.quest_done.length()
  next = phone_maybe_receive(next)
  next = ops_maybe_scheduled_report(next)
  next = player_maybe_complete_first_walk(next)
  if next.phone_log.length() != phone_before ||
    next.ops_reports.length() != reports_before ||
    next.quest_done.length() != quests_before {
    next = persist_town_life_model(next)
  }
  next
}

///|
/// Reward the walking task only after animation has visibly covered two
/// world tiles, or after a shorter route has actually reached its endpoint.
fn player_maybe_complete_first_walk(model : Model) -> Model {
  if quest_completed(model, "first-walk") {
    return model
  }
  match model.player_motion {
    Some(motion) => {
      let total = player_path_length(motion.path)
      let required = if total < 2.0 { total } else { 2.0 }
      let elapsed = golden_animation_seconds() - motion.started_seconds
      if required > 0.0 && elapsed * player_walk_speed >= required {
        complete_quest(model, "first-walk")
      } else {
        model
      }
    }
    None => model
  }
}

///|
fn avatar_create_update(model : Model) -> (Cmd, Model) {
  let editing = model.player is Some(_)
  let name = model.avatar_draft_name.trim().to_owned()
  if name.is_empty() {
    return model_only_update(model)
  }
  let persona = if model.avatar_draft_persona.is_empty() {
    "observer"
  } else {
    model.avatar_draft_persona
  }
  let player : PlayerAvatar = {
    name,
    persona,
    color: model.avatar_draft_color,
    sprite_index: model.avatar_draft_color % 12,
    title: player_title_for(model.spark),
  }
  browser_mark_energy_valley_intro_seen()
  let embodied = town_life_set_player(model, Some(player))
  let embodied = if editing {
    embodied
  } else {
    town_life_set_player_position(embodied, None)
  }
  let next = {
    ..embodied,
    energy_intro_open: false,
    avatar_wizard_step: 0,
    player_motion: None,
  }
  let next = track_event(
    next,
    if editing {
      "avatar_edit"
    } else {
      "avatar_create"
    },
    name,
  )
  town_life_commit(complete_quest(next, "create-avatar"))
}

///|
fn avatar_open_editor_update(model : Model) -> (Cmd, Model) {
  let next = match model.player {
    Some(player) =>
      {
        ..model,
        avatar_draft_name: player.name,
        avatar_draft_persona: player.persona,
        avatar_draft_color: player.color,
      }
    None => model
  }
  model_only_update({ ..next, avatar_wizard_step: 0, energy_intro_open: true })
}

///|
fn player_step_to_update(model : Model, tx : Int, ty : Int) -> (Cmd, Model) {
  match player_begin_walk(model, tx, ty) {
    Some(next) => {
      let next = track_event(next, "walk_step", "\{tx}:\{ty}")
      town_life_commit(next)
    }
    None =>
      model_only_update({
        ..model,
        life_toast: "那里过不去（水面或楼体），换条路试试",
        life_toast_tick: model.tick,
      })
  }
}

///|
fn player_step_direction_update(
  model : Model,
  dx : Int,
  dy : Int,
) -> (Cmd, Model) {
  let events_before = model.analytics.length()
  let next = player_step_direction_model(model, dx, dy)
  if next.analytics.length() == events_before {
    model_only_update({
      ..model,
      life_toast: "这个方向走不通",
      life_toast_tick: model.tick,
    })
  } else {
    town_life_commit(next)
  }
}

///|
fn phone_toggle_update(model : Model) -> (Cmd, Model) {
  if model.phone_open {
    town_life_commit({ ..model, phone_open: false })
  } else {
    let next = {
      ..model,
      phone_open: true,
      phone_unread: 0,
      square_open: false,
      ops_open: false,
      energy_request_open: false,
      resident_explorer_open: false,
      town_chronicle_open: false,
    }
    town_life_commit(track_event(next, "phone_open", ""))
  }
}

///|
fn moonclaw_guide_open_update(model : Model) -> (Cmd, Model) {
  let next = {
    ..model,
    phone_open: true,
    phone_contact: moonclaw_guide_contact_id,
    phone_unread: 0,
    moonclaw_guide_error: "",
    square_open: false,
    ops_open: false,
    energy_request_open: false,
    energy_intro_open: false,
    resident_explorer_open: false,
    town_chronicle_open: false,
  }
  town_life_commit(track_event(next, "phone_open", moonclaw_guide_contact_id))
}

///|
fn square_toggle_update(model : Model) -> (Cmd, Model) {
  if model.square_open {
    town_life_commit({ ..model, square_open: false })
  } else {
    town_life_commit(
      track_event(
        {
          ..model,
          square_open: true,
          phone_open: false,
          ops_open: false,
          energy_request_open: false,
          resident_explorer_open: false,
          town_chronicle_open: false,
        },
        "square_open",
        "",
      ),
    )
  }
}

///|
fn ops_toggle_update(model : Model) -> (Cmd, Model) {
  if model.ops_open {
    model_only_update({ ..model, ops_open: false })
  } else {
    town_life_commit(
      track_event(
        {
          ..model,
          ops_open: true,
          phone_open: false,
          square_open: false,
          energy_request_open: false,
          resident_explorer_open: false,
          town_chronicle_open: false,
        },
        "ops_open",
        "",
      ),
    )
  }
}

///|
fn ops_generate_report_update(model : Model) -> (Cmd, Model) {
  let reported = town_life_append_ops_report(model, ops_report_line(model))
  let next = {
    ..reported,
    last_report_tick: model.tick,
    life_toast: "📝 今日运营日报已生成",
    life_toast_tick: model.tick,
  }
  town_life_commit(track_event(next, "ops_report", ""))
}

///|
fn daily_checkin_update(model : Model) -> (Cmd, Model) {
  let today = energy_valley_sim_day(model)
  if model.checkin_day == today {
    return model_only_update({
      ..model,
      life_toast: "今天已经签过到啦，明天再来",
      life_toast_tick: model.tick,
    })
  }
  let rewarded = town_life_add_spark_award(
    model,
    "checkin:\{active_energy_valley_seed()}:\{today}",
    20,
  )
  let next = {
    ..rewarded,
    checkin_day: today,
    life_toast: "🌅 签到成功 +20 谷光值，能源谷新的一天开始了",
    life_toast_tick: model.tick,
  }
  town_life_commit(track_event(next, "checkin", ""))
}

///|
/// Canvas click router: walk mode sends the player to the clicked tile;
/// otherwise the normal tool pipeline runs, with the knowledge-building
/// topic prompt chained onto successful placements.
fn energy_canvas_click_routed(
  model : Model,
  screen_x : Int,
  screen_y : Int,
) -> (Cmd, Model) {
  let current = town_life_refresh_model_from_storage(model)
  if current.walk_mode && current.player is Some(_) {
    let (tx, ty) = golden_valley_screen_to_tile(screen_x, screen_y)
    let (cmd, next) = player_step_to_update(current, tx, ty)
    let next = persist_town_life_model(next)
    return (cmd, next)
  }
  if current.energy_tool == InspectTool {
    match
      golden_valley_runtime_agent_at_canvas_point(current, screen_x, screen_y) {
      Some(agent_id) =>
        return model_only_update({
          ..current,
          selection: Agent(agent_id),
          energy_board_open: false,
          energy_selected_building: None,
          energy_first_agent_open: false,
          resident_explorer_open: false,
          town_chronicle_open: false,
          energy_toast: "",
        })
      None => ()
    }
  }
  let placed = energy_valley_canvas_click_model(current, screen_x, screen_y)
  let world_changed = ToJson::to_json(current.town_life_world_states).stringify() !=
    ToJson::to_json(placed.town_life_world_states).stringify()
  // Arrays are mutable references, so compare against scalar lengths captured
  // before either enrichment step appends analytics or quest records.
  let events_before = placed.analytics.length()
  let quests_before = placed.quest_done.length()
  let placed = if current.energy_tool == InspectTool {
    town_life_record_canvas_inspection(placed)
  } else {
    placed
  }
  let next = knowledge_maybe_prompt_for_new_building(current, placed)
  if world_changed ||
    next.analytics.length() != events_before ||
    next.quest_done.length() != quests_before {
    return model_only_update(persist_town_life_model(next))
  }
  model_only_update(next)
}

///|
/// Canvas inspection selects a building inside the canvas interaction model,
/// so it does not pass through `OpenEnergyBuilding`. Keep both entry paths
/// behaviorally identical: a real selection records the visit and advances the
/// ordered onboarding chain.
fn town_life_record_canvas_inspection(model : Model) -> Model {
  match model.energy_selected_building {
    None => model
    Some(building) => {
      let visited = track_event(model, "building_visit", building.name)
      complete_quest(visited, "visit-building")
    }
  }
}

///|
fn open_building_update(model : Model, building_id : String) -> (Cmd, Model) {
  let opened = energy_valley_open_registered_building_model(model, building_id)
  match opened.energy_selected_building {
    Some(building) =>
      if golden_valley_building_for_identity([building], building_id) is Some(_) {
        let next = {
          ..close_town_transient_surfaces(opened),
          selection: Overview,
          energy_selected_building: Some(building),
        }
        let next = track_event(next, "building_visit", building_id)
        town_life_commit(complete_quest(next, "visit-building"))
      } else {
        model_only_update(opened)
      }
    None => model_only_update(opened)
  }
}
