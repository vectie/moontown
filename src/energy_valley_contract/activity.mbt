///|
/// Spatial lifecycle of an actor relative to a semantic place. A renderer may
/// animate between these states, but it must not invent a separate occupancy
/// truth.
pub(all) enum PresencePhase {
  Approaching
  AtEntrance
  Inside
  Departing
  Away
} derive(Debug, Eq)

///|
/// Semantic activity carried by a presence. Renderers may choose their own
/// glyphs and colors, while every surface consumes the same activity meaning.
pub(all) enum ActorActivityKind {
  ActorCoordinate
  ActorResearch
  ActorReview
  ActorExchange
  ActorObserve
  ActorLearn
  ActorBrowse
  ActorWalk
  ActorRest
  ActorDeliver
  ActorCelebrate
  ActorRevise
  ActorReturn
  ActorBlocked
  ActorFailed
  ActorIdle
  ActorCustom(String)
} derive(Debug, Eq)

///|
/// Evidence class of an actor descriptor. This keeps ambient simulation,
/// runtime evidence, and the local embodied player visibly distinguishable
/// without putting renderer-specific badges into the contract.
pub(all) enum ActorSourceKind {
  AmbientSimulation
  RuntimeEvidence
  LocalEmbodiment
} derive(Debug, Eq)

///|
/// Semantic state used by status-aware surfaces. Activity explains what an
/// actor is doing; state explains whether the backing work is active, waiting,
/// blocked, failed, completed, or merely available.
pub(all) enum ActorStateKind {
  ActorStateActive
  ActorStateWaitingReview
  ActorStateBlocked
  ActorStateFailed
  ActorStateCompleted
  ActorStateAssigned
  ActorStateIdle
} derive(Debug, Eq)

///|
/// Renderer-neutral identity and appearance hints for an actor. `avatar_family`
/// and the two variants are stable theme inputs rather than asset paths or CSS
/// colors, so Canvas, DOM, and future renderers can resolve them independently.
pub(all) struct ActorProfile {
  actor_id : StableId
  display_name : String
  role_label : String
  avatar_family : String
  avatar_variant : Int
  palette_variant : Int
  source_kind : ActorSourceKind
  state : ActorStateKind
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn actor_profile(
  actor_id : StableId,
  display_name : String,
  role_label : String,
  avatar_family : String,
  avatar_variant : Int,
  palette_variant : Int,
  source_kind : ActorSourceKind,
  state : ActorStateKind,
  provenance : Provenance,
) -> ActorProfile {
  {
    actor_id,
    display_name,
    role_label,
    avatar_family,
    avatar_variant,
    palette_variant,
    source_kind,
    state,
    provenance,
  }
}

///|
/// Exact outdoor position of an actor along the authoritative road graph. The
/// optional node endpoints make a movement leg inspectable while supporting a
/// point fixture such as a plaza path or boardwalk.
pub(all) struct ActorRoutePosition {
  position : WorldPoint
  road_segment_id : StableId?
  origin_node_id : StableId?
  destination_node_id : StableId?
  progress_per_mille : Int
  heading_degrees : Double?
} derive(Debug, Eq)

///|
pub fn actor_route_position(
  position : WorldPoint,
  progress_per_mille : Int,
  road_segment_id? : StableId? = None,
  origin_node_id? : StableId? = None,
  destination_node_id? : StableId? = None,
  heading_degrees? : Double? = None,
) -> ActorRoutePosition {
  {
    position,
    road_segment_id,
    origin_node_id,
    destination_node_id,
    progress_per_mille,
    heading_degrees,
  }
}

///|
/// One actor's current relationship to a place and, when known, the exact
/// portal or interaction slot being used.
pub(all) struct ActorPresence {
  actor_id : StableId
  place_id : StableId
  portal_id : StableId?
  interaction_slot_id : StableId?
  phase : PresencePhase
  intention : String
  since_tick : Int
  until_tick : Int?
  provenance : Provenance
  route_position : ActorRoutePosition?
  activity_kind : ActorActivityKind
} derive(Debug, Eq)

///|
pub fn actor_presence(
  actor_id : StableId,
  place_id : StableId,
  portal_id : StableId?,
  interaction_slot_id : StableId?,
  phase : PresencePhase,
  intention : String,
  since_tick : Int,
  until_tick : Int?,
  provenance : Provenance,
  route_position? : ActorRoutePosition? = None,
  activity_kind? : ActorActivityKind = ActorIdle,
) -> ActorPresence {
  {
    actor_id,
    place_id,
    portal_id,
    interaction_slot_id,
    phase,
    intention,
    since_tick,
    until_tick,
    provenance,
    route_position,
    activity_kind,
  }
}

///|
pub fn ActorPresence::is_outdoor(self : ActorPresence) -> Bool {
  self.route_position is Some(_) ||
  self.phase is Approaching ||
  self.phase is AtEntrance ||
  self.phase is Departing
}

///|
/// Resolves the single renderer-neutral position for an active presence. A
/// route position wins outdoors; exact portal and slot anchors cover threshold
/// and interior phases without leaking Canvas geometry into the contract.
pub fn ActorPresence::render_position(
  self : ActorPresence,
  world : CompiledTownWorld,
) -> WorldPoint? {
  match self.route_position {
    Some(route) => Some(route.position)
    None =>
      match world.find_place(self.place_id) {
        None => None
        Some(place) => {
          let portal_position = match self.portal_id {
            Some(portal_id) =>
              place.entrances
              .search_by(portal => portal.id == portal_id)
              .map(index => place.entrances[index].position)
            None => None
          }
          let slot_position = match self.interaction_slot_id {
            Some(slot_id) => place.find_slot(slot_id).map(slot => slot.position)
            None => None
          }
          if self.phase is Inside {
            match slot_position {
              Some(position) => Some(position)
              None => portal_position
            }
          } else {
            match portal_position {
              Some(position) => Some(position)
              None => slot_position
            }
          }
        }
      }
  }
}

///|
pub fn ActorPresence::is_active(self : ActorPresence, tick : Int) -> Bool {
  if self.since_tick > tick || self.phase is Away {
    false
  } else {
    match self.until_tick {
      Some(until) => tick < until
      None => true
    }
  }
}

///|
pub(all) enum ExchangeKind {
  Knowledge
  Social
  Delivery
  Service
  Mobility
  Care
  Custom(String)
} derive(Debug, Eq)

///|
/// A temporary, evidence-labelled relationship between two semantic places.
/// It represents the reason activity moves through town, not a decorative
/// line drawn by the canvas.
pub(all) struct PlaceExchange {
  id : StableId
  source_place_id : StableId
  target_place_id : StableId
  actor_id : StableId?
  kind : ExchangeKind
  label : String
  intensity_per_mille : Int
  started_tick : Int
  expires_tick : Int?
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn place_exchange(
  id : StableId,
  source_place_id : StableId,
  target_place_id : StableId,
  actor_id : StableId?,
  kind : ExchangeKind,
  label : String,
  intensity_per_mille : Int,
  started_tick : Int,
  expires_tick : Int?,
  provenance : Provenance,
) -> PlaceExchange {
  {
    id,
    source_place_id,
    target_place_id,
    actor_id,
    kind,
    label,
    intensity_per_mille,
    started_tick,
    expires_tick,
    provenance,
  }
}

///|
pub fn PlaceExchange::is_active(self : PlaceExchange, tick : Int) -> Bool {
  if self.started_tick > tick {
    false
  } else {
    match self.expires_tick {
      Some(expires) => tick < expires
      None => true
    }
  }
}
