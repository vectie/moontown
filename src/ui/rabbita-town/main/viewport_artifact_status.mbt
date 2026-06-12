///|
priv enum ArtifactStatusTone {
  Ready
  Live
  Simple
  Reference
  Review
  Alert
  Neutral
}

///|
fn artifact_status_tone_class(tone : ArtifactStatusTone) -> String {
  match tone {
    Ready => "artifact-status-ready"
    Live => "artifact-status-live"
    Simple => "artifact-status-simple"
    Reference => "artifact-status-reference"
    Review => "artifact-status-review"
    Alert => "artifact-status-alert"
    Neutral => "artifact-status-neutral"
  }
}
