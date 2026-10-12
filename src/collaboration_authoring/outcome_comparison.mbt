///|
/// Read two pinned historical dossiers under the existing read-only store lock.
/// This never calls the one-off collector or uses the live Book catalog.
pub async fn Store::compare_outcomes(
  self : Store,
  before : @contract.OutcomeKey,
  after : @contract.OutcomeKey,
) -> @contract.OutcomeComparison {
  self.read_locked(() => {
    let (left, _) = self.outcome_snapshot(before)
    let (right, _) = self.outcome_snapshot(after)
    @contract.compare_outcomes(left, right)
  })
}
