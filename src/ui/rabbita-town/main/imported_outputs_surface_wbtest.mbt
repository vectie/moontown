///|
struct ImportedSurfaceScheduler {
  mut effects : Int
}

///|
impl @cmd.Scheduler for ImportedSurfaceScheduler with fn run_effect(
  self,
  _kind,
  _effect,
) {
  self.effects += 1
}

///|
impl @cmd.Scheduler for ImportedSurfaceScheduler with fn queue_message(
  _self,
  _path,
  _message,
) {

}

///|
impl @cmd.Scheduler for ImportedSurfaceScheduler with fn drain_message(_self) {

}

///|
impl @cmd.Scheduler for ImportedSurfaceScheduler with fn hooks(_self) {
  { url_request: None, url_changed: None, }
}

///|
extern "js" fn imported_surface_verified_download() -> ImportedOutputDownload =
  #| () => ({ ok: true, message: "", bytes: new TextEncoder().encode("x".repeat(42)) })

///|
fn imported_surface_pending_model() -> Model {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let (_, opened) = update(
    dispatch,
    ImportedOutputsEvent(OpenImportedOutputs),
    init_model(),
  )
  let (file, _) = imported_outputs_transition(
    imported_fixture_ready(),
    ChooseImportedFile("portable/outputs/result/one 学习.txt"),
  )
  let (pending, _) = imported_outputs_transition(file, DownloadImportedFile)
  { ..opened, imported_outputs: pending, }
}

///|
fn imported_surface_save_effects(before : Model, after : Model) -> Int {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let (command, _) = update_non_form_message(
    dispatch,
    ImportedDownloadReceived(
      before.imported_outputs.generation,
      before.imported_outputs.download_generation,
      before.imported_outputs.selection.unwrap(),
      imported_surface_verified_download(),
    ),
    after,
  )
  let scheduler = ImportedSurfaceScheduler::{ effects: 0, }
  @cmd.Scheduler::add(scheduler, command)
  scheduler.effects
}

///|
fn imported_surface_assert_fenced(before : Model, after : Model) -> Unit raise {
  assert_false(after.imported_outputs.open)
  assert_true(
    after.imported_outputs.generation > before.imported_outputs.generation,
  )
  assert_eq(after.imported_outputs.selection, None)
  assert_eq(after.imported_outputs.text, TextIdle)
  assert_eq(after.imported_outputs.download, DownloadIdle)
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let key = before.imported_outputs.selection.unwrap()
  for
    event in [
      ImportedCatalogLoaded(
        before.imported_outputs.generation,
        imported_fixture_catalog().to_json().stringify(),
      ),
      ImportedTextLoaded(
        before.imported_outputs.generation,
        key,
        imported_fixture_reply(key, "x".repeat(42)),
      ),
    ] {
    let (_, late) = update(dispatch, ImportedOutputsEvent(event), after)
    assert_eq(late.imported_outputs, after.imported_outputs)
  }
  assert_eq(imported_surface_save_effects(before, after), 0)
}

///|
test "imported outputs actual ordinary primary openers invalidate pending reads and saves" {
  let before = imported_surface_pending_model()
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  for
    event in [
      TogglePhone,
      ToggleSquare,
      ToggleOps,
      OpenEnergyGuide,
      OpenEnergyReset,
      ToggleEnergyBoard,
      OpenMoonclawGuide,
      AvatarOpenEditor,
      ToggleMapLab,
      OpenEnergyRequest,
      ToggleResidentExplorer,
      ToggleTownChronicle,
      SelectAgent("runtime:chosen"),
      OpenSecretComputeRoom,
      StartIndoorWork,
    ] {
    let (_, after) = update_non_form_message(dispatch, event, before)
    assert_true(
      match event {
        TogglePhone | OpenMoonclawGuide => after.phone_open
        ToggleSquare => after.square_open
        ToggleOps => after.ops_open
        OpenEnergyGuide => after.energy_guide_open
        OpenEnergyReset => after.energy_reset_open
        ToggleEnergyBoard => after.energy_board_open
        AvatarOpenEditor => after.energy_intro_open
        ToggleMapLab => after.map_lab_open
        OpenEnergyRequest | StartIndoorWork => after.energy_request_open
        ToggleResidentExplorer => after.resident_explorer_open
        ToggleTownChronicle => after.town_chronicle_open
        SelectAgent(_) => after.selection is Agent("runtime:chosen")
        OpenSecretComputeRoom => after.town_spatial_layer is Underground(_)
        _ => false
      },
    )
    imported_surface_assert_fenced(before, after)
  }
}

///|
test "imported outputs reopening clears competing profile map lab and avatar only for this feature" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let old = {
    ..init_model(),
    selection: Agent("keep-avatar-draft"),
    map_lab_open: true,
    energy_intro_open: true,
    avatar_draft_name: "Keep my draft",
    avatar_wizard_step: 2,
    energy_status_open: true,
  }
  let (_, opened) = update(
    dispatch,
    ImportedOutputsEvent(OpenImportedOutputs),
    old,
  )
  assert_true(opened.imported_outputs.open)
  assert_true(opened.selection is Overview)
  assert_false(opened.map_lab_open)
  assert_false(opened.energy_intro_open)
  assert_eq(opened.avatar_draft_name, "Keep my draft")
  assert_eq(opened.avatar_wizard_step, 2)
  assert_true(opened.energy_status_open)
  // Do not broaden the shared legacy helper as part of this feature fix.
  let legacy = close_town_transient_surfaces(old)
  assert_true(legacy.selection is Agent("keep-avatar-draft"))
  assert_true(legacy.map_lab_open)
  assert_true(legacy.energy_intro_open)
}

///|
test "imported outputs common boundary preserves legacy state and command" {
  let before = imported_surface_pending_model()
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let (legacy_command, legacy) = update_non_form_message_before_imported_surface_fence(
    dispatch,
    OpenEnergyGuide,
    before,
  )
  let (actual_command, actual) = update_non_form_message(
    dispatch,
    OpenEnergyGuide,
    before,
  )
  let expected = imported_outputs_reconcile_primary_surface(legacy)
  assert_eq(actual.imported_outputs, expected.imported_outputs)
  assert_eq(actual.energy_guide_open, legacy.energy_guide_open)
  assert_eq(actual.energy_board_open, legacy.energy_board_open)
  assert_eq(actual.energy_intro_open, legacy.energy_intro_open)
  assert_eq(actual.resident_explorer_open, legacy.resident_explorer_open)
  assert_eq(actual.town_chronicle_open, legacy.town_chronicle_open)
  assert_eq(actual.analytics, legacy.analytics)
  assert_eq(actual.request_submission_id, legacy.request_submission_id)
  assert_eq(actual.budget, legacy.budget)
  assert_eq(actual.tick, legacy.tick)
  let old_scheduler = ImportedSurfaceScheduler::{ effects: 0, }
  let new_scheduler = ImportedSurfaceScheduler::{ effects: 0, }
  @cmd.Scheduler::add(old_scheduler, legacy_command)
  @cmd.Scheduler::add(new_scheduler, actual_command)
  assert_eq(old_scheduler.effects, new_scheduler.effects)
  // Already conflicting state is fenced before a stale response can emit save.
  assert_eq(
    imported_surface_save_effects(before, { ..before, phone_open: true, }),
    0,
  )
  assert_eq(imported_surface_save_effects(before, before), 1)
}

///|
test "imported outputs ambient controls and invalid targets retain current read and download" {
  let before = imported_surface_pending_model()
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  for
    event in [
      ToggleEnergyStatus,
      SetEnergyWeather(Rain),
      ToggleEnergyWeatherAuto,
      SetEnergyTimeScale(2),
      SetEnergyTool(RoadTool),
      ToggleMetro,
      TogglePause,
      ToggleWalkMode,
      TogglePlayerFollow,
      ViewportControlNoop,
      OpenEnergyBuilding("missing-building"),
      EnterEnergyBuilding("missing-building"),
      OpenEcosystemAttention("missing-signal", "missing-target"),
      OpenKnowledgeDialog("missing-post"),
      MoonclawGuideAsk(""),
      CloseEnergyGuide,
      CloseEnergyReset,
      CloseMapLab,
    ] {
    let (_, after) = update(dispatch, event, before)
    assert_eq(after.imported_outputs, before.imported_outputs)
    assert_eq(imported_surface_save_effects(before, after), 1)
  }
}

///|
test "imported outputs valid building attention and pending request targets remain exclusive" {
  let before = imported_surface_pending_model()
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let building = golden_valley_buildings(active_energy_valley_seed())[0]
  let id = golden_valley_building_civic_id(building)
  for event in [OpenEnergyBuilding(id), EnterEnergyBuilding(id)] {
    let (_, after) = update(dispatch, event, before)
    assert_true(
      after.energy_selected_building is Some(_) ||
      after.town_spatial_layer is Indoor(_),
    )
    imported_surface_assert_fenced(before, after)
  }
  let attention_before = { ..before, tick: 12, }
  let signals = ecosystem_attention_candidates(
    attention_before,
    active_energy_valley_seed(),
    "",
  )
  let signal = signals
    .iter()
    .find_first(signal => signal.provenance is AmbientPreview)
    .unwrap()
  let (_, attention) = update(
    dispatch,
    OpenEcosystemAttention(signal.cooldown_key, signal.interaction_target),
    attention_before,
  )
  assert_true(attention.energy_selected_building is Some(_))
  imported_surface_assert_fenced(attention_before, attention)
  let pending = {
    ..before,
    request_submitting: true,
    request_submission_id: 73,
    request_title: "Keep pending work",
    request_prompt: "Keep pending intent",
  }
  for event in [OpenEnergyRequestForAgent("any-contact"), StartIndoorWork] {
    let (_, after) = update(dispatch, event, pending)
    assert_true(after.energy_request_open)
    assert_true(after.request_submitting)
    assert_eq(after.request_submission_id, 73)
    assert_eq(after.request_title, pending.request_title)
    assert_eq(after.request_prompt, pending.request_prompt)
    imported_surface_assert_fenced(pending, after)
  }
}

///|
test "imported outputs canvas agent and building inspection fence late downloads" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let pending = imported_surface_pending_model().imported_outputs
  // Fixture construction installs its own camera and accepted canvas frame.
  // Build each immediately before its click instead of overwriting both first.
  for agent_first in [true, false] {
    let (base, x, y) = if agent_first {
      runtime_map_routing_agent_click_fixture()
    } else {
      runtime_map_routing_building_fallback_fixture()
    }
    let before = {
      ..close_town_transient_surfaces(base),
      imported_outputs: pending,
      selection: Overview,
      energy_intro_open: false,
      map_lab_open: false,
    }
    let (_, after) = update(dispatch, EnergyCanvasClick(x, y), before)
    assert_true(
      after.selection is Agent(_) || after.energy_selected_building is Some(_),
    )
    imported_surface_assert_fenced(before, after)
  }
}

///|
test "imported outputs actual knowledge and guide question openers fence pending downloads" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let building = golden_valley_buildings(active_energy_valley_seed())[0]
  let before = knowledge_posts_with_draft(
    imported_surface_pending_model(),
    building,
  )
  let post = before.posts[before.posts.length() - 1]
  for
    event in [
      OpenKnowledgeDialog(post.id),
      PublishBuilding(post.id),
      ConfirmKnowledgeTopic,
    ] {
    let (_, after) = update(dispatch, event, before)
    assert_true(after.knowledge_dialog_open)
    imported_surface_assert_fenced(before, after)
  }
  let (_, guide) = update(
    dispatch,
    MoonclawGuideAsk("Read-only guide question"),
    before,
  )
  assert_true(guide.phone_open)
  assert_true(guide.moonclaw_guide_pending)
  imported_surface_assert_fenced(before, guide)
}

///|
test "imported outputs competing-surface guard covers every primary surface without legacy mutation" {
  let before = imported_surface_pending_model()
  for
    competing in [
      { ..before, energy_first_agent_open: true, },
      { ..before, knowledge_dialog_open: true, },
      { ..before, town_spatial_layer: Underground(None), },
    ] {
    let after = imported_outputs_reconcile_primary_surface(competing)
    imported_surface_assert_fenced(before, after)
    assert_eq(after.energy_first_agent_open, competing.energy_first_agent_open)
    assert_eq(after.knowledge_dialog_open, competing.knowledge_dialog_open)
    assert_eq(
      after.energy_world_delta.to_json(),
      competing.energy_world_delta.to_json(),
    )
    assert_eq(after.posts.to_json(), competing.posts.to_json())
  }
}
