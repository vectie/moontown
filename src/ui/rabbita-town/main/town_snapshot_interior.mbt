///|
fn town_snapshot_interior_kind_label(
  kind : @energy_valley_contract.InteractionKind,
) -> String {
  match kind {
    @energy_valley_contract.Workstation => "工作台"
    @energy_valley_contract.MeetingPoint => "协作位"
    @energy_valley_contract.ExchangeDesk => "交换台"
    @energy_valley_contract.Exhibit => "展示位"
    @energy_valley_contract.Bench => "休息位"
    @energy_valley_contract.Stage => "发布台"
    @energy_valley_contract.TransitGate => "通行口"
    @energy_valley_contract.ServicePoint => "服务位"
    @energy_valley_contract.Custom(label) => label
  }
}

///|
fn town_snapshot_presence_label(
  presence : @energy_valley_contract.ActorPresence,
) -> String {
  let prefix = match presence.provenance.kind {
    @energy_valley_contract.RuntimeProjection => "LIVE"
    @energy_valley_contract.UserDelta => "YOU"
    _ => "PREVIEW"
  }
  "\{prefix} · \{presence.actor_id.local_key()}"
}

///|
fn town_snapshot_presence_phase_label(
  phase : @energy_valley_contract.PresencePhase,
) -> String {
  match phase {
    @energy_valley_contract.Approaching => "在路上"
    @energy_valley_contract.AtEntrance => "已到入口"
    @energy_valley_contract.Inside => "正在室内"
    @energy_valley_contract.Departing => "正在离开"
    @energy_valley_contract.Away => "不在场"
  }
}

///|
fn town_snapshot_slot_position_style(
  place : @energy_valley_contract.Place,
  slot : @energy_valley_contract.InteractionSlot,
) -> Array[String] {
  match town_canvas_place_bounds(place) {
    None => ["left: 50%", "top: 50%"]
    Some((x, y, width, depth)) => {
      let left = (10.0 +
      (slot.position.x - x.to_double()) / width.to_double().max(1.0) * 80.0).clamp(
        min=8.0,
        max=92.0,
      )
      let top = (12.0 +
      (slot.position.y - y.to_double()) / depth.to_double().max(1.0) * 72.0).clamp(
        min=10.0,
        max=88.0,
      )
      ["left: \{left}%", "top: \{top}%"]
    }
  }
}

///|
fn town_snapshot_slot_presences(
  snapshot : @energy_valley_contract.TownSnapshot,
  place_id : @energy_valley_contract.StableId,
  slot_id : @energy_valley_contract.StableId,
) -> Array[@energy_valley_contract.ActorPresence] {
  let result : Array[@energy_valley_contract.ActorPresence] = []
  for presence in snapshot.active_presences() {
    if presence.place_id == place_id &&
      presence.interaction_slot_id == Some(slot_id) &&
      presence.phase is @energy_valley_contract.Inside {
      result.push(presence)
    }
  }
  result
}

///|
fn render_town_snapshot_slot(
  snapshot : @energy_valley_contract.TownSnapshot,
  place : @energy_valley_contract.Place,
  slot : @energy_valley_contract.InteractionSlot,
) -> @rabbita.Html {
  let occupants = town_snapshot_slot_presences(snapshot, place.id, slot.id)
  div(
    class="semantic-interior-slot",
    style=town_snapshot_slot_position_style(place, slot),
    attrs=@html.Attrs::build().aria_label(
      "\{slot.label}，容量 \{slot.capacity}，当前 \{occupants.length()} 位",
    ),
    [
      span(
        class=if occupants.is_empty() {
          "semantic-interior-slot-dot"
        } else {
          "semantic-interior-slot-dot is-occupied"
        },
        occupants.length().to_string(),
      ),
      span(
        class="semantic-interior-slot-label",
        town_snapshot_interior_kind_label(slot.kind),
      ),
    ],
  )
}

///|
fn render_town_snapshot_inside_presence(
  presence : @energy_valley_contract.ActorPresence,
) -> @rabbita.Html {
  div(class="semantic-interior-presence", [
    span(
      class=if presence.provenance.kind
        is @energy_valley_contract.RuntimeProjection {
        "semantic-interior-presence-mark is-live"
      } else {
        "semantic-interior-presence-mark"
      },
      no_children(),
    ),
    div([
      span(
        class="semantic-interior-presence-name",
        town_snapshot_presence_label(presence),
      ),
      span(
        "\{town_snapshot_presence_phase_label(presence.phase)} · \{presence.intention}",
      ),
    ]),
  ])
}

///|
/// The compact procedural interior is a direct view of Place slots and the
/// ActorPresence ledger. A visible resident therefore cannot be placed at a
/// decorative workstation that the scheduler did not allocate.
fn render_town_snapshot_place_interior(
  snapshot : @energy_valley_contract.TownSnapshot,
  place : @energy_valley_contract.Place,
) -> @rabbita.Html {
  if place.building is None {
    return @html.nothing
  }
  let slot_nodes : Array[@rabbita.Html] = []
  for slot in place.interaction_slots {
    slot_nodes.push(render_town_snapshot_slot(snapshot, place, slot))
  }
  let floor_nodes : Array[@rabbita.Html] = [
    div(class="semantic-interior-corridor", no_children()),
  ]
  for node in slot_nodes {
    floor_nodes.push(node)
  }
  let inside : Array[@rabbita.Html] = []
  for presence in snapshot.presences_at(place.id) {
    if presence.phase is @energy_valley_contract.Inside {
      inside.push(render_town_snapshot_inside_presence(presence))
    }
  }
  section(class="semantic-interior", [
    header(class="semantic-interior-header", [
      div([
        p(class="eyebrow", "TownSnapshot interior"),
        h3("程序化工作楼层"),
      ]),
      span(
        class="semantic-interior-count",
        "\{inside.length()} / \{place.interaction_slots.length()} 在场",
      ),
    ]),
    div(class="semantic-interior-floor", floor_nodes),
    if inside.is_empty() {
      p(
        class="semantic-interior-empty",
        "当前没有 Agent 被真实分配到这些交互位。",
      )
    } else {
      div(class="semantic-interior-presences", inside)
    },
  ])
}

///|
fn town_snapshot_place_for_building_view(
  _model : Model,
  snapshot : @energy_valley_contract.TownSnapshot,
  building : GoldenValleyBuilding,
) -> @energy_valley_contract.Place? {
  town_snapshot_place_for_visual_building(snapshot, building)
}
