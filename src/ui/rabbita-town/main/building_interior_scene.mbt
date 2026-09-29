///|
fn indoor_scene_actor_sprite(
  snapshot : @energy_valley_contract.TownSnapshot,
  presence : @energy_valley_contract.ActorPresence,
) -> String {
  match snapshot.find_actor_profile(presence.actor_id) {
    Some(profile) => {
      let family = profile.avatar_family.to_lower()
      if family.contains("mayor") {
        "/tilemap/actors/mayor_walk_1.png"
      } else if family.contains("keeper") {
        "/tilemap/actors/keeper_walk_1.png"
      } else if family.contains("worker") {
        "/tilemap/actors/worker_walk_1.png"
      } else {
        "/tilemap/actors/roster/resident_\{profile.avatar_variant.abs() % 3}.png"
      }
    }
    None => "/tilemap/actors/roster/resident_0.png"
  }
}

///|
fn indoor_scene_kind_key(
  kind : @energy_valley_contract.InteractionKind,
) -> String {
  match kind {
    @energy_valley_contract.Workstation => "workstation"
    @energy_valley_contract.MeetingPoint => "meeting"
    @energy_valley_contract.ExchangeDesk => "exchange"
    @energy_valley_contract.Exhibit => "exhibit"
    @energy_valley_contract.Bench => "bench"
    @energy_valley_contract.Stage => "stage"
    @energy_valley_contract.TransitGate => "gate"
    @energy_valley_contract.ServicePoint => "service"
    @energy_valley_contract.Custom(_) => "workstation"
  }
}

///|
fn indoor_scene_kind_asset_index(
  kind : @energy_valley_contract.InteractionKind,
) -> Int {
  match kind {
    @energy_valley_contract.Workstation | @energy_valley_contract.Custom(_) => 0
    @energy_valley_contract.MeetingPoint => 1
    @energy_valley_contract.ExchangeDesk => 2
    @energy_valley_contract.ServicePoint => 3
    @energy_valley_contract.Exhibit => 4
    @energy_valley_contract.Bench => 5
    @energy_valley_contract.Stage => 6
    @energy_valley_contract.TransitGate => 7
  }
}

///|
fn indoor_scene_kind_asset_size(
  kind : @energy_valley_contract.InteractionKind,
) -> Double {
  match kind {
    @energy_valley_contract.Workstation
    | @energy_valley_contract.MeetingPoint => 220.0
    @energy_valley_contract.ExchangeDesk | @energy_valley_contract.Stage =>
      232.0
    @energy_valley_contract.TransitGate => 224.0
    _ => 196.0
  }
}

///|
/// Cell contact points differ because the atlas keeps generous equal padding.
/// These ratios align each real prop's lowest connected pixel with its floor
/// anchor instead of pretending every cell has the same baseline.
fn indoor_scene_kind_asset_baseline(
  kind : @energy_valley_contract.InteractionKind,
) -> Double {
  match kind {
    @energy_valley_contract.Workstation | @energy_valley_contract.Custom(_) =>
      0.91
    @energy_valley_contract.MeetingPoint => 0.90
    @energy_valley_contract.ExchangeDesk => 0.92
    @energy_valley_contract.ServicePoint => 0.87
    @energy_valley_contract.Exhibit => 0.74
    @energy_valley_contract.Bench => 0.72
    @energy_valley_contract.Stage => 0.77
    @energy_valley_contract.TransitGate => 0.76
  }
}

///|
fn indoor_scene_kind_accent(
  kind : @energy_valley_contract.InteractionKind,
) -> String {
  match kind {
    @energy_valley_contract.MeetingPoint => "#e5b840"
    @energy_valley_contract.ExchangeDesk
    | @energy_valley_contract.ServicePoint
    | @energy_valley_contract.TransitGate => "#35a8ce"
    @energy_valley_contract.Exhibit | @energy_valley_contract.Stage => "#efb6bf"
    @energy_valley_contract.Bench => "#b8895b"
    _ => "#6fa653"
  }
}

///|
fn indoor_scene_slot_normalized_position(
  place : @energy_valley_contract.Place,
  slot : @energy_valley_contract.InteractionSlot,
) -> (Double, Double) {
  match town_canvas_place_bounds(place) {
    None => (0.5, 0.5)
    Some((x, y, width, depth)) =>
      (
        ((slot.position.x - x.to_double()) / width.to_double().max(1.0)).clamp(
          min=0.12,
          max=0.88,
        ),
        ((slot.position.y - y.to_double()) / depth.to_double().max(1.0)).clamp(
          min=0.12,
          max=0.88,
        ),
      )
  }
}

///|
/// A building contract may intentionally give several slots one civic map
/// point. Inside the room those objects still need separate, stable footprints.
/// Civic coordinates are not room-local furniture positions. Use furnishing
/// bays with enough separation for the matching pointer targets.
fn indoor_scene_slot_visual_position(
  place : @energy_valley_contract.Place,
  slot : @energy_valley_contract.InteractionSlot,
  index : Int,
) -> (Double, Double) {
  let repeated_kind = place.interaction_slots
    .iter()
    .filter(other => other.kind == slot.kind)
    .count() >
    1
  if repeated_kind {
    let column = index % 3
    let row = index / 3
    let row_count = (place.interaction_slots.length() + 2) / 3
    return (
      0.15 + column.to_double() * 0.32,
      0.20 + row.to_double() * 0.65 / (row_count - 1).max(1).to_double(),
    )
  }
  let (bay_x, bay_y) = match slot.kind {
    @energy_valley_contract.ServicePoint => (0.25, 0.15)
    @energy_valley_contract.TransitGate => (0.88, 0.16)
    @energy_valley_contract.Workstation => (0.12, 0.68)
    @energy_valley_contract.ExchangeDesk => (0.86, 0.70)
    @energy_valley_contract.MeetingPoint => (0.50, 0.65)
    @energy_valley_contract.Exhibit => (0.77, 0.32)
    @energy_valley_contract.Bench => (0.45, 0.77)
    @energy_valley_contract.Stage => (0.52, 0.30)
    @energy_valley_contract.Custom(_) =>
      match index % 4 {
        0 => (0.31, 0.42)
        1 => (0.69, 0.42)
        2 => (0.31, 0.62)
        _ => (0.69, 0.62)
      }
  }
  (bay_x, bay_y)
}

///|
fn indoor_scene_slots_in_draw_order(
  place : @energy_valley_contract.Place,
) -> Array[(Int, @energy_valley_contract.InteractionSlot)] {
  let ordered : Array[(Int, @energy_valley_contract.InteractionSlot)] = []
  for index, slot in place.interaction_slots {
    ordered.push((index, slot))
  }
  ordered.sort_by((left, right) => {
    let (left_index, left_slot) = left
    let (right_index, right_slot) = right
    let (left_x, left_y) = indoor_scene_slot_visual_position(
      place, left_slot, left_index,
    )
    let (right_x, right_y) = indoor_scene_slot_visual_position(
      place, right_slot, right_index,
    )
    let left_depth = left_x * 0.24 + left_y * 0.36
    let right_depth = right_x * 0.24 + right_y * 0.36
    if left_depth < right_depth {
      -1
    } else if left_depth > right_depth {
      1
    } else {
      left_index - right_index
    }
  })
  ordered
}

///|
fn draw_town_snapshot_indoor_world_canvas(
  snapshot : @energy_valley_contract.TownSnapshot,
  place : @energy_valley_contract.Place,
  selected_id : String,
) -> Unit {
  let canvas_id = "indoor-world-canvas"
  prepare_golden_valley_canvas(canvas_id)
  let width = golden_valley_canvas_width(canvas_id)
  let height = golden_valley_canvas_height(canvas_id)
  match @canvas.get_context2d(canvas_id) {
    None => ()
    Some(context) => {
      context.clear_rect(0.0, 0.0, width.to_double(), height.to_double())
      let (xx, yx, yy, tx, ty) = spatial_scene_plate_registration(false)
      ignore(
        spatial_world_canvas_draw_plate(
          context, canvas_id, "/tilemap/rooms/moontown-spatial-v3/indoor-room.jpg",
          width, height, "#f5f2e9", xx, yx, yy, tx, ty,
        ),
      )
      let scale = spatial_scene_scale(width)
      for _, indexed_slot in indoor_scene_slots_in_draw_order(place) {
        let (index, slot) = indexed_slot
        let (normalized_x, normalized_y) = indoor_scene_slot_visual_position(
          place, slot, index,
        )
        let (x, y) = spatial_scene_anchor(
          width, height, normalized_x, normalized_y, false,
        )
        let occupants = town_snapshot_slot_presences(
          snapshot,
          place.id,
          slot.id,
        )
        let authored = spatial_world_canvas_draw_atlas_prop(
          context,
          canvas_id,
          "/tilemap/props/moontown-spatial-v2/indoor-furniture-atlas.png?composite-v1",
          4,
          2,
          indoor_scene_kind_asset_index(slot.kind),
          x,
          y,
          scale,
          indoor_scene_kind_asset_size(slot.kind),
          indoor_scene_kind_asset_baseline(slot.kind),
          selected_id == slot.id.local_key(),
          "",
        )
        if !authored {
          spatial_world_canvas_draw_indoor_prop(
            context,
            indoor_scene_kind_key(slot.kind),
            x,
            y,
            scale,
            indoor_scene_kind_accent(slot.kind),
            !occupants.is_empty(),
          )
        }
        for occupant_index, presence in occupants {
          let offset = (
              occupant_index.to_double() -
              (occupants.length() - 1).to_double() / 2.0
            ) *
            28.0 *
            scale
          spatial_world_canvas_draw_agent(
            context,
            canvas_id,
            indoor_scene_actor_sprite(snapshot, presence),
            x + offset,
            y + 22.0 * scale,
            scale,
            presence.provenance.kind
            is @energy_valley_contract.RuntimeProjection,
          )
        }
      }
    }
  }
}

///|
fn render_indoor_world_hotspots(
  dispatch : Dispatch[Msg],
  model : Model,
  snapshot : @energy_valley_contract.TownSnapshot,
  place : @energy_valley_contract.Place,
) -> @rabbita.Html {
  let hotspots : Array[@rabbita.Html] = []
  for index, slot in place.interaction_slots {
    let occupants = town_snapshot_slot_presences(snapshot, place.id, slot.id)
    let (normalized_x, normalized_y) = indoor_scene_slot_visual_position(
      place, slot, index,
    )
    hotspots.push(
      button(
        class="spatial-world-hotspot indoor-world-hotspot" +
          (if model.indoor_selected_slot_id == slot.id.local_key() {
            " is-selected"
          } else {
            ""
          }),
        on_click=dispatch(SelectIndoorSlot(slot.id.local_key())),
        style=spatial_scene_hotspot_style(
          normalized_x, normalized_y, false, 11.0, 14.0,
        ),
        attrs=@html.Attrs::build().aria_label(
          "\{slot.label}，\{town_snapshot_interior_kind_label(slot.kind)}，容量 \{slot.capacity}，当前 \{occupants.length()} 位居民",
        ),
        span(class="sr-only", slot.label),
      ),
    )
  }
  for index, portal in place.entrances {
    if index != 0 {
      continue
    }
    let (xx, yx, yy, tx, ty) = spatial_scene_plate_registration(false)
    let door_left = (0.708 * xx + tx) * 100.0
    let door_top = (0.708 * yx + 0.385 * yy + ty) * 100.0
    hotspots.push(
      button(
        class="spatial-world-hotspot indoor-world-portal-hotspot",
        style=[
          "left: \{door_left}%",
          "top: \{door_top}%",
          "width: 9%",
          "height: 17%",
        ],
        on_click=dispatch(ExitEnergyBuilding),
        attrs=@html.Attrs::build().aria_label(
          if portal.primary {
            "主入口 \{portal.id.local_key()}"
          } else {
            "入口 \{portal.id.local_key()}"
          },
        ),
        span(class="sr-only", portal.id.local_key()),
      ),
    )
  }
  div(class="spatial-world-hotspots", hotspots)
}

///|
fn render_town_snapshot_graphical_interior_scene(
  dispatch : Dispatch[Msg],
  model : Model,
  snapshot : @energy_valley_contract.TownSnapshot,
  place : @energy_valley_contract.Place,
) -> @rabbita.Html {
  guard place.building is Some(building_profile) else { return @html.nothing }
  let inside_count = snapshot
    .presences_at(place.id)
    .fold(init=0, (count, presence) => {
      if presence.phase is @energy_valley_contract.Inside {
        count + 1
      } else {
        count
      }
    })
  schedule_spatial_world_canvas("indoor-world-canvas", () => {
    draw_town_snapshot_indoor_world_canvas(
      snapshot,
      place,
      model.indoor_selected_slot_id,
    )
  })
  section(
    class="indoor-graphical-scene indoor-world-scene",
    attrs=@html.Attrs::build().aria_label(
      "\{place.name} 等距室内世界，共 \{place.interaction_slots.length()} 个真实交互位和 \{inside_count} 位室内 Agent",
    ),
    [
      header(class="indoor-scene-header spatial-world-header", [
        div([
          p(class="building-interior-eyebrow", "房间 · 点击家具开始"),
          h2(place.name),
        ]),
        div(class="indoor-scene-place-facts", [
          span("\{building_profile.floors} 层"),
          span("\{inside_count} Agent"),
        ]),
      ]),
      div(class="spatial-world-stage indoor-world-stage", [
        canvas(
          id="indoor-world-canvas",
          class="spatial-world-canvas",
          attrs=@html.Attrs::build().aria_label(
            "等距室内：家具来自 InteractionSlot，居民来自 ActorPresence",
          ),
          no_children(),
        ),
        render_indoor_world_hotspots(dispatch, model, snapshot, place),
      ]),
      div(class="spatial-world-legend", [
        span("家具可点选 · 门返回小镇"),
        span("实线居民：运行时记录 · 预览居民不代表执行"),
      ]),
    ],
  )
}
