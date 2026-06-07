///|
async fn persist_town_checkpoint(
  state : @core.TownState,
  snapshot_path : String,
) -> Unit {
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  persist_visual_projection(state, snapshot_path)
}
