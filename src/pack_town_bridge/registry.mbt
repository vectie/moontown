///|
pub fn empty_registry() -> PackProjectionRegistry {
  { projections: [] }
}

///|
/// Reconcile is idempotent by activated pack identity. The registry stores only
/// the latest read projection and never owns the underlying domain records.
pub fn reconcile_projection(
  registry : PackProjectionRegistry,
  activation : @host.HostActivationProjection,
  projection : PackTownProjection,
) -> Result[PackProjectionRegistry, Array[PackTownBridgeIssue]] {
  let issues = projection_conformance_issues(activation, projection)
  if !issues.is_empty() {
    return Err(issues)
  }
  let retained = registry.projections.filter(existing => {
    existing.pack_id != projection.pack_id
  })
  Ok({ projections: retained + [projection] })
}

///|
pub fn remove_pack_projection(
  registry : PackProjectionRegistry,
  pack_id : String,
) -> PackProjectionRegistry {
  {
    projections: registry.projections.filter(projection => {
      projection.pack_id != pack_id
    }),
  }
}

///|
pub fn projection_for_pack(
  registry : PackProjectionRegistry,
  pack_id : String,
) -> PackTownProjection? {
  for projection in registry.projections {
    if projection.pack_id == pack_id {
      return Some(projection)
    }
  }
  None
}

///|
pub fn subject_for_pack(
  registry : PackProjectionRegistry,
  pack_id : String,
  subject_ref : String,
) -> PackTownSubject? {
  guard projection_for_pack(registry, pack_id) is Some(projection) else {
    return None
  }
  for subject in projection.subjects {
    if subject.subject_ref == subject_ref {
      return Some(subject)
    }
  }
  None
}

///|
pub fn all_projected_subjects(
  registry : PackProjectionRegistry,
) -> Array[(String, PackTownSubject)] {
  let subjects : Array[(String, PackTownSubject)] = []
  for projection in registry.projections {
    for subject in projection.subjects {
      subjects.push((projection.pack_id, subject))
    }
  }
  subjects
}
