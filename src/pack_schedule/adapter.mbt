///|
/// A generic schedule registration owned by a pack, not by a domain runtime.
pub(all) struct ScheduleBinding {
  pack_id : String
  product_id : String
  version : String
  schedule_id : String
  cadence : String
  timezone : String
  workflow_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ScheduleRegistry {
  schedules : Array[ScheduleBinding]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn empty_registry() -> ScheduleRegistry {
  { schedules: [] }
}

///|
pub fn bindings(
  projection : @host.HostActivationProjection,
) -> Array[ScheduleBinding] raise {
  if projection.contract != "moonsuite.pack-host-activation.v1" {
    fail("unsupported pack host projection")
  }
  projection.schedules.map(fn(schedule) {
    {
      pack_id: projection.pack_id,
      product_id: projection.product_id,
      version: projection.version,
      schedule_id: schedule.id,
      cadence: schedule.cadence,
      timezone: schedule.timezone,
      workflow_id: schedule.workflow_id,
    }
  })
}

///|
pub fn resolve(
  projected : Array[ScheduleBinding],
  schedule_id : String,
) -> ScheduleBinding? {
  for binding in projected {
    if binding.schedule_id == schedule_id {
      return Some(binding)
    }
  }
  None
}

///|
/// Reconcile is idempotent by stable pack/schedule identity. Activating a new
/// version replaces registrations but does not own or erase run history.
pub fn reconcile(
  registry : ScheduleRegistry,
  projection : @host.HostActivationProjection,
) -> ScheduleRegistry raise {
  let incoming = bindings(projection)
  let ids = incoming.map(binding => binding.schedule_id)
  let retained = registry.schedules.filter(binding =>
    binding.pack_id != projection.pack_id || !ids.contains(binding.schedule_id)
  )
  { schedules: retained + incoming }
}

///|
pub fn remove_pack(
  registry : ScheduleRegistry,
  pack_id : String,
) -> ScheduleRegistry {
  { schedules: registry.schedules.filter(binding => binding.pack_id != pack_id) }
}
