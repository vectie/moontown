///|
pub fn demo_state_snapshot() -> String {
  @storage.describe_snapshot(@storage.snapshot_of(demo_state()))
}
