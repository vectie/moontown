///|
/// Compiler stages shared by Map Lab. These are semantic stages rather than
/// renderer passes, so diagnostics remain useful to CLI and test consumers.
pub(all) enum WorldCompileStage {
  ReferenceEvidence
  TerrainCompilation
  RoadCompilation
  BlockCompilation
  ParcelCompilation
  PlacementCompilation
  AccessCompilation
  DeltaApplication
  RuntimeProjection
  Custom(String)
} derive(Debug, Eq)

///|
pub(all) enum WorldDiagnosticSeverity {
  Information
  Caution
  Failure
} derive(Debug, Eq)

///|
pub(all) enum WorldDiagnosticCode {
  EvidenceAccepted
  EvidenceMissing
  GeometryAdjusted
  GeometryConflict
  AccessAdjusted
  AccessConflict
  DeltaConflict
  UnsupportedSchema
  PlacementRejected
  Custom(String)
} derive(Debug, Eq)

///|
/// A compiler explanation suitable for Map Lab overlays and build reports.
pub(all) struct WorldDiagnostic {
  id : StableId
  stage : WorldCompileStage
  severity : WorldDiagnosticSeverity
  code : WorldDiagnosticCode
  entity_id : StableId?
  message : String
  position : WorldPoint?
  evidence_id : String?
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn world_diagnostic(
  id : StableId,
  stage : WorldCompileStage,
  severity : WorldDiagnosticSeverity,
  code : WorldDiagnosticCode,
  message : String,
  provenance : Provenance,
  entity_id? : StableId? = None,
  position? : WorldPoint? = None,
  evidence_id? : String? = None,
) -> WorldDiagnostic {
  {
    id,
    stage,
    severity,
    code,
    entity_id,
    message,
    position,
    evidence_id,
    provenance,
  }
}

///|
pub(all) enum PlacementKind {
  BuildingPlacement
  ParkPlacement
  InstallationPlacement
  CustomPlacement(String)
} derive(Debug, Eq)

///|
pub(all) enum PlacementRejectionReason {
  OutsideWorld
  OutsideParcel
  IntersectsWater
  IntersectsRoad
  Occupied
  NoReachableEntrance
  ProgramMismatch
  DeltaConflictReason
  CustomReason(String)
} derive(Debug, Eq)

///|
/// Rejections are first-class compiler output, not discarded log messages.
/// They let Map Lab show the candidate footprint and the exact failed rule.
pub(all) struct RejectedPlacement {
  id : StableId
  candidate_id : StableId
  kind : PlacementKind
  parcel_id : StableId?
  grid_anchor : GridPosition
  footprint : Polygon
  reason : PlacementRejectionReason
  message : String
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn rejected_placement(
  id : StableId,
  candidate_id : StableId,
  kind : PlacementKind,
  grid_anchor : GridPosition,
  footprint : Polygon,
  reason : PlacementRejectionReason,
  message : String,
  provenance : Provenance,
  parcel_id? : StableId? = None,
) -> RejectedPlacement {
  {
    id,
    candidate_id,
    kind,
    parcel_id,
    grid_anchor,
    footprint,
    reason,
    message,
    provenance,
  }
}
