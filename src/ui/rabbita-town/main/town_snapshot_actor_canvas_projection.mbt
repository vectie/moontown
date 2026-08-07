///|
/// Canvas-facing wrapper keeps semantic identity beside the existing sprite
/// record so hit testing and selection do not need to rebuild runtime routes.
priv struct TownSnapshotCanvasActor {
  actor_id : @energy_valley_contract.StableId
  agent : GoldenValleyCanvasAgent
}

///|
fn town_snapshot_actor_activity_glyph(
  activity : @energy_valley_contract.ActorActivityKind,
) -> String {
  match activity {
    @energy_valley_contract.ActorCoordinate => "◎"
    @energy_valley_contract.ActorResearch => "⌕"
    @energy_valley_contract.ActorReview => "✓"
    @energy_valley_contract.ActorExchange => "↔"
    @energy_valley_contract.ActorObserve => "◌"
    @energy_valley_contract.ActorLearn => "✦"
    @energy_valley_contract.ActorBrowse => "◇"
    @energy_valley_contract.ActorWalk => "→"
    @energy_valley_contract.ActorRest => "☕"
    @energy_valley_contract.ActorDeliver => "⇢"
    @energy_valley_contract.ActorCelebrate => "✺"
    @energy_valley_contract.ActorRevise => "↺"
    @energy_valley_contract.ActorReturn => "⇠"
    @energy_valley_contract.ActorBlocked
    | @energy_valley_contract.ActorFailed => "!"
    @energy_valley_contract.ActorIdle
    | @energy_valley_contract.ActorCustom(_) => "•"
  }
}

///|
fn town_snapshot_ambient_activity_color(
  activity : @energy_valley_contract.ActorActivityKind,
) -> String {
  match activity {
    @energy_valley_contract.ActorCoordinate => "#f6c85f"
    @energy_valley_contract.ActorResearch
    | @energy_valley_contract.ActorLearn => "#a5b4fc"
    @energy_valley_contract.ActorReview => "#fcd34d"
    @energy_valley_contract.ActorExchange
    | @energy_valley_contract.ActorCelebrate => "#f9a8d4"
    @energy_valley_contract.ActorObserve
    | @energy_valley_contract.ActorBrowse => "#67e8f9"
    @energy_valley_contract.ActorWalk
    | @energy_valley_contract.ActorDeliver
    | @energy_valley_contract.ActorReturn => "#7dd3fc"
    @energy_valley_contract.ActorRest => "#fdba74"
    @energy_valley_contract.ActorBlocked
    | @energy_valley_contract.ActorFailed => "#fda4af"
    @energy_valley_contract.ActorRevise => "#fcd34d"
    @energy_valley_contract.ActorIdle
    | @energy_valley_contract.ActorCustom(_) => "#94a3b8"
  }
}

///|
fn town_snapshot_runtime_state_color(
  state : @energy_valley_contract.ActorStateKind,
) -> String {
  match state {
    @energy_valley_contract.ActorStateActive => "#6ee7b7"
    @energy_valley_contract.ActorStateWaitingReview => "#fcd34d"
    @energy_valley_contract.ActorStateBlocked => "#fdba74"
    @energy_valley_contract.ActorStateFailed => "#fda4af"
    @energy_valley_contract.ActorStateCompleted => "#86efac"
    @energy_valley_contract.ActorStateAssigned => "#7dd3fc"
    @energy_valley_contract.ActorStateIdle => "#94a3b8"
  }
}

///|
fn town_snapshot_player_palette(variant : Int) -> String {
  let colors = [
    "#f2c94c", "#34d399", "#38bdf8", "#f472b6", "#a78bfa", "#fb923c",
  ]
  colors[variant.clamp(min=0, max=colors.length() - 1)]
}

///|
fn town_snapshot_actor_work_color(
  profile : @energy_valley_contract.ActorProfile,
  activity : @energy_valley_contract.ActorActivityKind,
) -> String {
  match profile.source_kind {
    @energy_valley_contract.AmbientSimulation =>
      town_snapshot_ambient_activity_color(activity)
    @energy_valley_contract.RuntimeEvidence =>
      town_snapshot_runtime_state_color(profile.state)
    @energy_valley_contract.LocalEmbodiment =>
      town_snapshot_player_palette(profile.palette_variant)
  }
}

///|
fn town_snapshot_actor_faces_left(
  route : @energy_valley_contract.ActorRoutePosition,
) -> Bool {
  match route.heading_degrees {
    Some(heading) => {
      let normalized = if heading < 0.0 {
        heading + 360.0
      } else if heading >= 360.0 {
        heading - 360.0
      } else {
        heading
      }
      normalized >= 45.0 && normalized < 225.0
    }
    None => false
  }
}

///|
fn town_snapshot_actor_label(
  profile : @energy_valley_contract.ActorProfile,
  presence : @energy_valley_contract.ActorPresence,
) -> String {
  match profile.source_kind {
    @energy_valley_contract.AmbientSimulation =>
      "\{profile.display_name} · \{presence.intention}"
    @energy_valley_contract.RuntimeEvidence => presence.intention
    @energy_valley_contract.LocalEmbodiment => profile.display_name
  }
}

///|
fn town_snapshot_canvas_actor_records(
  snapshot : @energy_valley_contract.TownSnapshot,
  animation_seconds : Double,
  reduced_motion : Bool,
  selected_actor_id : @energy_valley_contract.StableId?,
) -> Array[TownSnapshotCanvasActor] {
  let result : Array[TownSnapshotCanvasActor] = []
  let mut ambient_index = 0
  let mut runtime_index = 0
  for presence in snapshot.outdoor_presences() {
    guard snapshot.find_actor_profile(presence.actor_id) is Some(profile) else {
      continue
    }
    if profile.source_kind is @energy_valley_contract.RuntimeEvidence &&
      runtime_index >= 24 {
      continue
    }
    guard presence.route_position is Some(route) else { continue }
    let source_index = match profile.source_kind {
      @energy_valley_contract.AmbientSimulation => {
        let current = ambient_index
        ambient_index += 1
        current
      }
      @energy_valley_contract.RuntimeEvidence => {
        let current = runtime_index
        runtime_index += 1
        current
      }
      @energy_valley_contract.LocalEmbodiment => 0
    }
    let bob_speed = if profile.source_kind
      is @energy_valley_contract.LocalEmbodiment {
      10.0
    } else {
      9.0
    }
    result.push({
      actor_id: presence.actor_id,
      agent: {
        x: route.position.x,
        y: route.position.y,
        sprite_path: golden_valley_agent_sprite_path(
          profile.avatar_family,
          profile.avatar_variant,
        ),
        facing_left: town_snapshot_actor_faces_left(route),
        bob: if reduced_motion {
          0.0
        } else {
          animation_seconds * bob_speed + source_index.to_double()
        },
        work_color: town_snapshot_actor_work_color(
          profile,
          presence.activity_kind,
        ),
        activity_glyph: if profile.source_kind
          is @energy_valley_contract.LocalEmbodiment {
          "★"
        } else {
          town_snapshot_actor_activity_glyph(presence.activity_kind)
        },
        activity_label: town_snapshot_actor_label(profile, presence),
        preview: profile.source_kind
        is @energy_valley_contract.AmbientSimulation,
        selected: selected_actor_id == Some(presence.actor_id),
      },
    })
  }
  result
}

///|
fn town_snapshot_canvas_agents(
  snapshot : @energy_valley_contract.TownSnapshot,
  animation_seconds : Double,
  reduced_motion : Bool,
  selected_actor_id : @energy_valley_contract.StableId?,
) -> Array[GoldenValleyCanvasAgent] {
  town_snapshot_canvas_actor_records(
    snapshot, animation_seconds, reduced_motion, selected_actor_id,
  ).map(record => record.agent)
}

///|
fn town_snapshot_selected_actor_id(
  selection : Selection,
) -> @energy_valley_contract.StableId? {
  match selection {
    Agent(agent_id) =>
      Some(
        ecosystem_contract_scoped_id(
          "runtime-agent",
          strip_prefix_once(agent_id, "runtime:"),
        ),
      )
    _ => None
  }
}
