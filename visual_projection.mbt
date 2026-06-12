///|
pub type VisualAgentProjection = @visual_projection.VisualAgentProjection

///|
pub type VisualBuildingProjection = @visual_projection.VisualBuildingProjection

///|
pub type VisualModuleProjection = @visual_projection.VisualModuleProjection

///|
pub type VisualProjection = @visual_projection.VisualProjection

///|
pub fn build_visual_projection(
  state : @core.TownState,
  tick? : Int = @visual_projection.visual_projection_tick(state),
) -> @visual_projection.VisualProjection {
  @visual_projection.build_visual_projection(state, tick~)
}

///|
pub fn default_visual_projection_path(snapshot_path : String) -> String {
  @visual_projection.default_visual_projection_path(snapshot_path)
}

///|
pub async fn persist_visual_projection(
  state : @core.TownState,
  snapshot_path : String,
  tick? : Int = @visual_projection.visual_projection_tick(state),
) -> Unit {
  @visual_projection.persist_visual_projection(state, snapshot_path, tick~)
}
