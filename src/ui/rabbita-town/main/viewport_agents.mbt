///|
fn render_worker_avatar(
  dispatch : Dispatch[Msg],
  scene : @ui.SceneRenderModel,
  worker : WorkerSim,
  index : Int,
  selected : Bool,
) -> @rabbita.Html {
  let zone = scene_node_by_key(scene, worker.zone_key)
  let style = [
    "left: \{worker_avatar_left(zone, index)}px",
    "top: \{worker_avatar_top(zone, index)}px",
    "--wander-x1: \{worker_wander_x1(index)}px",
    "--wander-y1: \{worker_wander_y1(index)}px",
    "--wander-x2: \{worker_wander_x2(index)}px",
    "--wander-y2: \{worker_wander_y2(index)}px",
    "--wander-x3: \{worker_wander_x3(index)}px",
    "--wander-y3: \{worker_wander_y3(index)}px",
    "--wander-duration: \{worker_wander_duration(index)}ms",
    "--worker-image: url('\{worker_roster_asset(index)}')",
  ]
  let class_name = "worker-avatar \{worker_status_class(worker.status)}" +
    " worker-sprite-roster" +
    class_suffix_when(selected, " selected")
  button(class=class_name, style~, on_click=dispatch(SelectWorker(worker.id)), [
    span(class="worker-sprite", no_children()),
    span(class="worker-badge", worker_avatar_initials(worker.title)),
    span(class="worker-label", worker.title),
    span(class="worker-meta", "\{worker.role} / \{worker.status.to_string()}"),
  ])
}
