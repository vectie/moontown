///|
/// The town owns selection and work context; the renderer only emits inspection
/// events. Design entities never acquire runtime identity through visual proximity.
priv struct SpatialSceneSelection {
  key : String
  view : String
  id : String
  title : String
  detail : String
  scope : String
  visit : String
} derive(Debug, Eq, FromJson, ToJson)

///|
fn spatial_scene_key(model : Model) -> String {
  match model.town_spatial_layer {
    Underground(_) => "compute"
    Indoor(building) => "indoor:" + golden_valley_building_civic_id(building)
    ReferenceInterior => "center-g3"
    Outdoor => ""
  }
}

///|
fn spatial_scene_selected(model : Model) -> SpatialSceneSelection? {
  model.spatial_scene_selections.get(spatial_scene_key(model))
}

///|
fn spatial_scene_select(model : Model, raw : String) -> Model {
  let json = @json.parse(raw) catch { _ => return model }
  let selected : SpatialSceneSelection = @json.from_json(json) catch {
    _ => return model
  }
  guard selected.key == spatial_scene_key(model) &&
    !selected.key.is_empty() &&
    selected.id.length() <= 256 &&
    selected.title.length() <= 256 &&
    selected.detail.length() <= 4096 &&
    ["runtime", "design"].contains(selected.scope) &&
    ["hall", "site", "rack", "server", "board", "room", "g3"].contains(
      selected.view,
    ) else {
    return model
  }
  guard ["", "hall", "rack", "server", "board"].contains(selected.visit) else {
    return model
  }
  if selected.scope == "runtime" {
    let valid = match model.town_spatial_layer {
      Underground(_) => {
        let projection = parse_bootstrap_secret_compute_room_projection()
        selected.id == "moongate" ||
        projection.local_cluster.machines.any(m => m.id == selected.id) ||
        projection.remote_routes.any(r => r.id == selected.id)
      }
      Indoor(building) => {
        let snapshot = ecosystem_contract_town_snapshot(
          model,
          active_energy_valley_seed(),
        )
        match town_snapshot_place_for_building_view(model, snapshot, building) {
          Some(place) =>
            place.interaction_slots.any(slot => {
              slot.id.local_key() == selected.id
            })
          None => false
        }
      }
      _ => false
    }
    guard valid else { return model }
  }
  let selections = model.spatial_scene_selections.copy()
  selections[selected.key] = selected
  let next = { ..model, spatial_scene_selections: selections, }
  if selected.scope == "runtime" {
    match model.town_spatial_layer {
      Underground(_) =>
        { ..next, secret_compute_room_selected_id: selected.id, }
      Indoor(_) => { ..next, indoor_selected_slot_id: selected.id, }
      _ => next
    }
  } else {
    next
  }
}

///|
fn spatial_scene_clear_design(model : Model) -> Model {
  let selections = model.spatial_scene_selections.copy()
  selections.remove(spatial_scene_key(model))
  { ..model, spatial_scene_selections: selections, }
}

///|
extern "js" fn spatial_scene_install(deliver : (String) -> Unit) -> Unit =
  #| deliver => {
  #|   if (typeof document === 'undefined') return;
  #|   globalThis.__moonTownSpaceDeliver = deliver;
  #|   if (globalThis.__moonTownSpaceLoader) return;
  #|   globalThis.__moonTownSpaceLoader = true;
  #|   const base = globalThis.__MOONTOWN_BASE_PATH || '';
  #|   import(`${base}/landmark-studio/town-space-loader.js`).catch(error => {
  #|     globalThis.__moonTownSpaceLoader = false;
  #|     console.warn('3D scene unavailable', error);
  #|   });
  #| }

///|
fn install_spatial_scene_bridge(dispatch : Dispatch[Msg]) -> Cmd {
  @cmd.custom_cmd(
    scheduler => {
      spatial_scene_install(raw => {
        scheduler.add(dispatch(SpatialSceneEvent(raw)))
      })
    },
    kind=@cmd.after_render,
  )
}

///|
fn render_spatial_stage(payload : Json) -> @rabbita.Html {
  div(
    class="town-space-host",
    attrs=@html.Attrs::build().data_set("space", payload.stringify()),
    no_children(),
  )
}

///|
fn spatial_scene_context(model : Model) -> Json {
  {
    "key": spatial_scene_key(model),
    "work": model.spatial_selected_work_id,
    "request": model.spatial_request_id,
    "selection": match spatial_scene_selected(model) {
      Some(selected) => ToJson::to_json(selected)
      None => Json::null()
    },
  }
}

///|
fn render_spatial_design_inspector(model : Model) -> @rabbita.Html {
  match spatial_scene_selected(model) {
    Some(selected) if selected.scope == "design" =>
      section(class="building-interior-panel spatial-design-inspector", [
        span(class="spatial-data-badge", "设计示意 · 未绑定"),
        h2(
          if selected.title.is_empty() {
            "选择空间对象"
          } else {
            selected.title
          },
        ),
        p(selected.detail),
      ])
    _ => @html.nothing
  }
}

///|
fn render_compute_spatial_stage(
  model : Model,
  projection : SecretComputeRoomProjection,
) -> @rabbita.Html {
  let nodes : Array[Json] = [
    {
      "id": "moongate",
      "name": "MoonGate",
      "kind": "gateway",
      "state": secret_compute_state_label(projection.gateway.state),
    },
  ]
  for machine in projection.local_cluster.machines {
    nodes.push({
      "id": machine.id,
      "name": machine.label,
      "kind": "machine",
      "state": secret_compute_state_label(machine.state),
      "memory": secret_compute_memory_label(machine),
      "workloads": if machine.metrics_reported == Some(false) {
        Json::null()
      } else {
        machine.running_workloads.to_json()
      },
      "observed_at": machine.observed_at_unix_ms,
    })
  }
  for route in projection.remote_routes {
    nodes.push({
      "id": route.id,
      "name": route.label,
      "kind": "route",
      "state": secret_compute_state_label(route.state),
    })
  }
  render_spatial_stage({
    "kind": "compute",
    "context": spatial_scene_context(model),
    "selected": model.secret_compute_room_selected_id,
    "nodes": nodes,
    "observed_at": projection.observed_at,
  })
}

///|
fn render_indoor_spatial_stage(
  model : Model,
  snapshot : @energy_valley_contract.TownSnapshot,
  place : @energy_valley_contract.Place,
) -> @rabbita.Html {
  let slots : Array[Json] = []
  for index, slot in place.interaction_slots {
    let (x, z) = indoor_scene_slot_visual_position(place, slot, index)
    let people = town_snapshot_slot_presences(snapshot, place.id, slot.id)
    slots.push({
      "id": slot.id.local_key(),
      "name": slot.label,
      "kind": indoor_scene_kind_key(slot.kind),
      "x": x,
      "z": z,
      "capacity": slot.capacity,
      "actors": people.map(person => {
        let actor : Json = {
          "id": person.actor_id.local_key(),
          "name": snapshot
          .find_actor_profile(person.actor_id)
          .map(p => p.display_name)
          .unwrap_or("居民"),
          "sprite": indoor_scene_actor_sprite(snapshot, person),
          "live": person.provenance.kind
          is @energy_valley_contract.RuntimeProjection,
        }
        actor
      }),
    })
  }
  render_spatial_stage({
    "kind": "indoor",
    "context": spatial_scene_context(model),
    "title": place.name,
    "slots": slots,
    "selected": model.indoor_selected_slot_id,
  })
}

///|
fn render_reference_interior(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  @html.main_(class="building-interior-layer", [
    header(class="building-interior-header", [
      div(class="building-interior-title", [
        p("小镇 / 未来中心 / 室内"),
        h1("G 座 · 三层"),
      ]),
      button(
        on_click=dispatch(ExitEnergyBuilding),
        class="building-interior-exit",
        town_ui_label("back", "小镇"),
      ),
    ]),
    div(class="building-interior-grid", [
      render_spatial_stage({
        "kind": "g3",
        "context": spatial_scene_context(model),
      }),
      div(class="building-interior-side", [
        render_spatial_design_inspector(model),
        section(class="building-interior-panel", [
          render_advanced_details(
            "空间来源与绑定",
            compact_label="空间来源",
            [
              p(
                "这是未来中心 G 座三层的设计方案，尚未绑定实际居民与工作；与政策大厅的语义工作空间独立。",
              ),
            ],
          ),
        ]),
        render_indoor_compute_lift(dispatch),
      ]),
    ]),
  ])
}
