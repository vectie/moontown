///|
priv struct ViewportStageDimensions {
  width : Int
  height : Int
}

///|
fn render_town_viewport(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
  selected_node_key : String?,
  selected_worker_id : String?,
  shell_class : String,
  frame_class : String,
) -> @rabbita.Html {
  let standalone = standalone_viewport_requested()
  let dimensions = viewport_stage_dimensions(standalone, scene)
  let scene_style = viewport_stage_style(dimensions)
  let scene_frame_style = viewport_frame_style(dimensions)
  let worker_avatars = render_viewport_worker_avatars(
    dispatch, model, scene, workers, selected_worker_id, standalone,
  )
  let scene_nodes = render_viewport_scene_nodes(
    dispatch, scene, selected_node_key, standalone,
  )
  section(class=shell_class, [
    div(class="scene-stage-rail", execution_stage_cards(executions)),
    p(
      class="scene-hint",
      "Scroll the viewport on smaller screens, then select a zone or worker to inspect the live pipeline state.",
    ),
    div(class=frame_class, style=scene_frame_style, [
      div(class="scene-stage", style=scene_style, [
        img(
          class="scene-background",
          src=scene.background_path,
          alt="\{scene.title} background",
          loading="eager",
          no_children(),
        ),
        render_tilemap_layer(),
        render_water_effect_layer(),
        render_wenyu_module_road_layer(),
        render_wenyu_module_building_layer(
          dispatch, model, executions, selected_node_key,
        ),
        div(class="scene-overlay", [
          div(class="scene-nodes-layer", scene_nodes),
          div(class="scene-workers-layer", worker_avatars),
        ]),
      ]),
    ]),
  ])
}

///|
fn viewport_stage_dimensions(
  standalone : Bool,
  scene : @ui.SceneRenderModel,
) -> ViewportStageDimensions {
  if standalone {
    {
      width: tilemap_scene_width(),
      height: tilemap_scene_height(),
    }
  } else {
    { width: scene.width, height: scene.height }
  }
}

///|
fn viewport_stage_style(dimensions : ViewportStageDimensions) -> Array[String] {
  ["width: \{dimensions.width}px", "height: \{dimensions.height}px"]
}

///|
fn viewport_frame_style(dimensions : ViewportStageDimensions) -> Array[String] {
  ["--scene-width: \{dimensions.width}px"]
}

///|
fn render_viewport_worker_avatars(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  selected_worker_id : String?,
  standalone : Bool,
) -> Array[@rabbita.Html] {
  if standalone {
    render_standalone_worker_avatars(dispatch, model, selected_worker_id)
  } else {
    render_dashboard_worker_avatars(dispatch, scene, workers, selected_worker_id)
  }
}

///|
fn render_standalone_worker_avatars(
  dispatch : Dispatch[Msg],
  model : Model,
  selected_worker_id : String?,
) -> Array[@rabbita.Html] {
  match model.visual_projection {
    Some(_) => {
      let worker_avatars : Array[@rabbita.Html] = []
      let visual_agents = visual_overworld_agents(model)
      for i in 0..<visual_agents.length() {
        let agent = visual_agents[i]
        worker_avatars.push(
          render_visual_agent_avatar(
            dispatch,
            agent,
            i,
            selected_worker_id == Some(agent.worker_id),
          ),
        )
      }
      worker_avatars
    }
    None => render_viewport_residents()
  }
}

///|
fn render_dashboard_worker_avatars(
  dispatch : Dispatch[Msg],
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  selected_worker_id : String?,
) -> Array[@rabbita.Html] {
  let worker_avatars : Array[@rabbita.Html] = []
  for i in 0..<workers.length() {
    let worker = workers[i]
    worker_avatars.push(
      render_worker_avatar(
        dispatch,
        scene,
        worker,
        i,
        selected_worker_id == Some(worker.id),
      ),
    )
  }
  worker_avatars
}

///|
fn render_viewport_scene_nodes(
  dispatch : Dispatch[Msg],
  scene : @ui.SceneRenderModel,
  selected_node_key : String?,
  standalone : Bool,
) -> Array[@rabbita.Html] {
  if standalone {
    []
  } else {
    scene.nodes
    .filter(node => !is_mayor_scene_node(node))
    .map(node => {
      render_node(dispatch, node, selected_node_key == Some(node.key))
    })
  }
}
