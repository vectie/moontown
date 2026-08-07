///|
pub(all) enum ProvenanceKind {
  WenyuReference
  Procedural
  UserDelta
  RuntimeProjection
  Derived
} derive(Debug, Eq)

///|
/// How strongly compilation must preserve a piece of the Wenyu plan.
pub(all) enum PreservationLevel {
  Fixed
  Bounded
  Statistical
  Free
} derive(Debug, Eq)

///|
pub(all) struct Provenance {
  source_id : String
  source_version : String
  kind : ProvenanceKind
  preservation : PreservationLevel
  confidence_per_mille : Int
} derive(Debug, Eq)

///|
pub fn provenance(
  source_id : String,
  source_version : String,
  kind : ProvenanceKind,
  preservation : PreservationLevel,
  confidence_per_mille? : Int = 1000,
) -> Provenance {
  { source_id, source_version, kind, preservation, confidence_per_mille }
}

///|
pub fn Provenance::has_valid_confidence(self : Provenance) -> Bool {
  self.confidence_per_mille >= 0 && self.confidence_per_mille <= 1000
}
