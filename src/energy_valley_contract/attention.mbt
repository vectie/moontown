///|
#derive(Debug, Eq)
pub(all) enum AttentionTargetKind {
  Place
  InteractionSlot
  Landmark
  Agent
  Event
  AmbientDetail
  Custom(String)
}

///|
/// A persistent semantic point that may attract an actor's attention. Targets
/// exist independently of temporary signals, so UI and simulation share IDs.
#derive(Debug, Eq)
pub(all) struct AttentionTarget {
  id : StableId
  owner_id : StableId?
  kind : AttentionTargetKind
  label : String
  position : WorldPoint
  base_salience_per_mille : Int32
  tags : ReadOnlyArray[String]
}

///|
pub fn attention_target(
  id : StableId,
  owner_id : StableId?,
  kind : AttentionTargetKind,
  label : String,
  position : WorldPoint,
  base_salience_per_mille : Int32,
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
#derive(Debug, Eq)
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
}

///|
#derive(Debug, Eq)
pub(all) struct AttentionSignal {
  id : StableId
  target_id : StableId
  source_id : StableId?
  kind : AttentionSignalKind
  intensity_per_mille : Int32
  started_tick : Int32
  expires_tick : Int32?
}

///|
pub fn attention_signal(
  id : StableId,
  target_id : StableId,
  source_id : StableId?,
  kind : AttentionSignalKind,
  intensity_per_mille : Int32,
  started_tick : Int32,
  expires_tick : Int32?,
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
pub fn AttentionSignal::is_active(self : AttentionSignal, tick : Int32) -> Bool {
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
#derive(Debug, Eq)
pub(all) struct AttentionFocus {
  actor_id : StableId
  target_id : StableId
  strength_per_mille : Int32
  since_tick : Int32
}

///|
pub fn attention_focus(
  actor_id : StableId,
  target_id : StableId,
  strength_per_mille : Int32,
  since_tick : Int32,
) -> AttentionFocus {
  { actor_id, target_id, strength_per_mille, since_tick, }
}
