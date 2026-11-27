///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct VisualAgentProjection {
  worker_id : String
  worker_name : String
  book_id : String
  book_title : String
  role : String
  status : String
  phase : String
  task_id : String?
  task_title : String?
  run_id : String?
  sprite_key : String
  zone_key : String
  location : String
  destination : String
  behavior : String
  effect : String
  visible_on_overworld : Bool
  message : String
  grid_x : Int32
  grid_y : Int32
  z : Int32
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct VisualBuildingProjection {
  book_id : String
  title : String
  zone_key : String
  running_count : Int32
  waiting_count : Int32
  review_count : Int32
  blocked_count : Int32
  completed_count : Int32
  effect : String
  message : String
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct VisualModuleProjection {
  module_id : String
  book_id : String
  title : String
  status : String
  source : String
  running_count : Int32
  waiting_count : Int32
  review_count : Int32
  blocked_count : Int32
  completed_count : Int32
  active_agent_count : Int32
  effect : String
  message : String
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct VisualProjection {
  tick : Int32
  agents : Array[VisualAgentProjection]
  buildings : Array[VisualBuildingProjection]
  modules : Array[VisualModuleProjection]
  messages : Array[String]
}

///|
pub fn build_visual_projection(
  state : @core.TownState,
  tick~ : Int32 = visual_projection_tick(state),
) -> VisualProjection {
  build_visual_projection_with_decorator(
    state,
    VisualDecoratorConfig::empty(),
    tick~,
  )
}

///|
pub fn build_visual_projection_with_decorator(
  state : @core.TownState,
  decorator : VisualDecoratorConfig,
  tick~ : Int32 = visual_projection_tick(state),
) -> VisualProjection {
  let agents : Array[VisualAgentProjection] = []
  for worker in state.workers {
    agents.push(visual_agent_projection(state, worker, decorator))
  }
  let buildings : Array[VisualBuildingProjection] = []
  for book in state.books {
    buildings.push(visual_building_projection(state, book))
  }
  let modules : Array[VisualModuleProjection] = []
  for building in buildings {
    modules.push(visual_module_projection(building, agents))
  }
  {
    tick,
    agents,
    buildings,
    modules,
    messages: visual_projection_messages(state, agents, buildings),
  }
}

///|
pub fn default_visual_projection_path(snapshot_path : String) -> String {
  let base = @storage.snapshot_base_dir(snapshot_path)
  if base == @storage.moontown_product_state_dir() {
    @storage.moontown_product_artifact("visual-projection.json")
  } else {
    "\{base}/visual-projection.json"
  }
}
