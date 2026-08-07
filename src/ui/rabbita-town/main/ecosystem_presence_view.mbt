///|
/// One provenance class represented in the place-now surface. Counts include
/// every active presence phase at the place, while occupancy itself remains a
/// stricter `Inside`-only claim.
priv struct EcosystemPresenceProvenanceGroup {
  label : String
  tone : String
  count : Int
} derive(Debug, Eq)

///|
/// Renderer-facing projection of the authoritative actor-presence ledger.
/// This deliberately contains no assigned-building or schedule fallback: if
/// the snapshot does not place an actor here, the UI must not claim they are
/// here.
priv struct EcosystemPlacePresenceView {
  place_id : String
  occupant_names : Array[String]
  arriving_names : Array[String]
  departing_names : Array[String]
  activity_label : String
  activity_glyph : String
  attention_boost : Int
  runtime_inside_count : Int
  runtime_arriving_count : Int
  provenance_groups : Array[EcosystemPresenceProvenanceGroup]
} derive(Debug, Eq)

///|
fn ecosystem_presence_actor_name(
  model : Model?,
  snapshot : @energy_valley_contract.TownSnapshot,
  presence : @energy_valley_contract.ActorPresence,
) -> String {
  match snapshot.find_actor_profile(presence.actor_id) {
    Some(profile) => return profile.display_name
    None => ()
  }
  guard model is Some(compatibility_model) else {
    return presence.actor_id.local_key()
  }
  match presence.provenance.kind {
    @energy_valley_contract.RuntimeProjection =>
      match compatibility_model.energy_valley_runtime.projection {
        Some(projection) =>
          for agent in projection.agents {
            if ecosystem_contract_scoped_id("runtime-agent", agent.id) ==
              presence.actor_id {
              return agent.name
            }
          }
        None => ()
      }
    @energy_valley_contract.Derived =>
      for profile in ecosystem_preview_resident_profiles() {
        if ecosystem_contract_scoped_id("resident", profile.id) ==
          presence.actor_id {
          return profile.name
        }
      }
    _ => ()
  }
  presence.actor_id.local_key()
}

///|
fn ecosystem_presence_phase_rank(
  phase : @energy_valley_contract.PresencePhase,
) -> Int {
  match phase {
    @energy_valley_contract.Inside => 40
    @energy_valley_contract.AtEntrance => 30
    @energy_valley_contract.Approaching => 20
    @energy_valley_contract.Departing => 10
    @energy_valley_contract.Away => 0
  }
}

///|
fn ecosystem_presence_provenance_rank(
  kind : @energy_valley_contract.ProvenanceKind,
) -> Int {
  match kind {
    @energy_valley_contract.RuntimeProjection => 5
    @energy_valley_contract.UserDelta => 4
    @energy_valley_contract.WenyuReference => 3
    @energy_valley_contract.Procedural => 2
    @energy_valley_contract.Derived => 1
  }
}

///|
fn ecosystem_presence_activity_glyph(
  kind : @energy_valley_contract.ProvenanceKind,
) -> String {
  match kind {
    @energy_valley_contract.RuntimeProjection => "●"
    @energy_valley_contract.UserDelta => "◆"
    @energy_valley_contract.WenyuReference => "◇"
    @energy_valley_contract.Procedural => "✦"
    @energy_valley_contract.Derived => "·"
  }
}

///|
fn ecosystem_presence_provenance_groups(
  runtime_count : Int,
  ambient_count : Int,
  local_count : Int,
  wenyu_count : Int,
  procedural_count : Int,
) -> Array[EcosystemPresenceProvenanceGroup] {
  let groups : Array[EcosystemPresenceProvenanceGroup] = []
  if runtime_count > 0 {
    groups.push({
      label: "RUNTIME · LIVE",
      tone: "is-live",
      count: runtime_count,
    })
  }
  if ambient_count > 0 {
    groups.push({
      label: "AMBIENT · PREVIEW",
      tone: "is-ambient",
      count: ambient_count,
    })
  }
  if local_count > 0 {
    groups.push({ label: "LOCAL · USER", tone: "is-local", count: local_count })
  }
  if wenyu_count > 0 {
    groups.push({
      label: "PLACE · WENYU",
      tone: "is-authored",
      count: wenyu_count,
    })
  }
  if procedural_count > 0 {
    groups.push({
      label: "WORLD · PROCEDURAL",
      tone: "is-place",
      count: procedural_count,
    })
  }
  groups
}

///|
/// Projects exactly one place from `TownSnapshot.actor_presences`. `Inside`
/// is the only phase that contributes to building occupancy; approaching and
/// entrance phases remain visible as arrivals but never inflate the in-building
/// count.
fn ecosystem_place_presence_view(
  model : Model,
  snapshot : @energy_valley_contract.TownSnapshot,
  place_id : @energy_valley_contract.StableId,
) -> EcosystemPlacePresenceView {
  ecosystem_place_presence_view_resolved(Some(model), snapshot, place_id)
}

///|
/// Canvas and other migrated surfaces resolve names and activities from the
/// same actor profile ledger as positions and occupancy. The model-backed
/// wrapper above remains only for compatibility fixtures without profiles.
fn ecosystem_place_presence_view_from_snapshot(
  snapshot : @energy_valley_contract.TownSnapshot,
  place_id : @energy_valley_contract.StableId,
) -> EcosystemPlacePresenceView {
  ecosystem_place_presence_view_resolved(None, snapshot, place_id)
}

///|
fn ecosystem_place_presence_view_resolved(
  model : Model?,
  snapshot : @energy_valley_contract.TownSnapshot,
  place_id : @energy_valley_contract.StableId,
) -> EcosystemPlacePresenceView {
  let occupants : Array[String] = []
  let arriving : Array[String] = []
  let departing : Array[String] = []
  let mut dominant_rank = -1
  let mut activity_label = "安静运行"
  let mut activity_glyph = "·"
  let mut runtime_count = 0
  let mut runtime_inside_count = 0
  let mut runtime_arriving_count = 0
  let mut ambient_count = 0
  let mut local_count = 0
  let mut wenyu_count = 0
  let mut procedural_count = 0
  for presence in snapshot.presences_at(place_id) {
    let actor_name = ecosystem_presence_actor_name(model, snapshot, presence)
    match presence.phase {
      @energy_valley_contract.Inside => occupants.push(actor_name)
      @energy_valley_contract.AtEntrance
      | @energy_valley_contract.Approaching => arriving.push(actor_name)
      @energy_valley_contract.Departing => departing.push(actor_name)
      @energy_valley_contract.Away => ()
    }
    match presence.provenance.kind {
      @energy_valley_contract.RuntimeProjection => {
        runtime_count += 1
        if presence.phase is @energy_valley_contract.Inside {
          runtime_inside_count += 1
        } else if presence.phase is @energy_valley_contract.Approaching ||
          presence.phase is @energy_valley_contract.AtEntrance {
          runtime_arriving_count += 1
        }
      }
      @energy_valley_contract.Derived => ambient_count += 1
      @energy_valley_contract.UserDelta => local_count += 1
      @energy_valley_contract.WenyuReference => wenyu_count += 1
      @energy_valley_contract.Procedural => procedural_count += 1
    }
    let rank = ecosystem_presence_phase_rank(presence.phase) * 10 +
      ecosystem_presence_provenance_rank(presence.provenance.kind)
    if rank > dominant_rank {
      dominant_rank = rank
      activity_label = if presence.intention.trim().is_empty() {
        actor_name
      } else {
        "\{actor_name} · \{presence.intention}"
      }
      activity_glyph = ecosystem_presence_activity_glyph(
        presence.provenance.kind,
      )
    }
  }
  let attention = occupants.length() * 18 +
    arriving.length() * 12 +
    departing.length() * 6
  {
    place_id: place_id.to_string(),
    occupant_names: occupants,
    arriving_names: arriving,
    departing_names: departing,
    activity_label,
    activity_glyph,
    attention_boost: attention.min(100),
    runtime_inside_count,
    runtime_arriving_count,
    provenance_groups: ecosystem_presence_provenance_groups(
      runtime_count, ambient_count, local_count, wenyu_count, procedural_count,
    ),
  }
}

///|
fn ecosystem_place_presence_summary(
  view : EcosystemPlacePresenceView,
) -> String {
  let parts : Array[String] = []
  if !view.occupant_names.is_empty() {
    parts.push("在内 \{view.occupant_names.join("、")}")
  }
  if !view.arriving_names.is_empty() {
    parts.push("将到 \{view.arriving_names.join("、")}")
  }
  if !view.departing_names.is_empty() {
    parts.push("离开 \{view.departing_names.join("、")}")
  }
  if parts.is_empty() {
    "此刻无人入内；到达与在场仅以语义快照为准。"
  } else {
    "\{view.activity_label} · \{parts.join(" · ")}"
  }
}
