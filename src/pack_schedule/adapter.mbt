///|
/// A generic schedule registration owned by a pack, not by a domain runtime.
pub(all) struct ScheduleBinding {
  pack_id : String
  product_id : String
  schedule_id : String
  cadence : String
  timezone : String
  workflow_id : String
} derive(Debug, Eq, ToJson, FromJson)

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
