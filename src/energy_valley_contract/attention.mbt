///|
pub(all) enum AttentionTargetKind {
  Place
  InteractionSlot
  Landmark
  Agent
  Event
  AmbientDetail
  Custom(String)
} derive(Debug, Eq)

///|
/// A persistent semantic point that may attract an actor's attention. Targets
/// exist independently of temporary signals, so UI and simulation share IDs.
pub(all) struct AttentionTarget {
  id : StableId
  owner_id : StableId?
  kind : AttentionTargetKind
  label : String
  position : WorldPoint
  base_salience_per_mille : Int
  tags : ReadOnlyArray[String]
} derive(Debug, Eq)

///|
pub fn attention_target(
  id : StableId,
  owner_id : StableId?,
  kind : AttentionTargetKind,
  label : String,
  position : WorldPoint,
  base_salience_per_mille : Int,
  tags : ArrayView[String],
) -> AttentionTarget {
  {
    id,
    owner_id,
    kind,
    label,
    position,
    base_salience_per_mille,
    tags: freeze(tags),
  }
}

///|
pub(all) enum AttentionSignalKind {
  Motion
  Sound
  Social
  Work
  Novelty
  Need
  Reward
  Ambient
  Custom(String)
} derive(Debug, Eq)

///|
pub(all) struct AttentionSignal {
  id : StableId
  target_id : StableId
  source_id : StableId?
  kind : AttentionSignalKind
  intensity_per_mille : Int
  started_tick : Int
  expires_tick : Int?
} derive(Debug, Eq)

///|
pub fn attention_signal(
  id : StableId,
  target_id : StableId,
  source_id : StableId?,
  kind : AttentionSignalKind,
  intensity_per_mille : Int,
  started_tick : Int,
  expires_tick : Int?,
) -> AttentionSignal {
  {
    id,
    target_id,
    source_id,
    kind,
    intensity_per_mille,
    started_tick,
    expires_tick,
  }
}

///|
pub fn AttentionSignal::is_active(self : AttentionSignal, tick : Int) -> Bool {
  if self.started_tick > tick {
    false
  } else {
    match self.expires_tick {
      Some(expires) => tick < expires
      None => true
    }
  }
}

///|
/// The currently tracked focus of one actor. `actor_id` deliberately remains a
/// stable semantic link rather than embedding runtime-owned agent state.
pub(all) struct AttentionFocus {
  actor_id : StableId
  target_id : StableId
  strength_per_mille : Int
  since_tick : Int
} derive(Debug, Eq)

///|
pub fn attention_focus(
  actor_id : StableId,
  target_id : StableId,
  strength_per_mille : Int,
  since_tick : Int,
) -> AttentionFocus {
  { actor_id, target_id, strength_per_mille, since_tick }
}
