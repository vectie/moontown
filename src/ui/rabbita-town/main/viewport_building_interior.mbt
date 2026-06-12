///|
fn furniture_for_node(node : @ui.SceneRenderNode) -> Array[@rabbita.Html] {
  if node.key == "city-hall" {
    [
      div(class="furniture furniture-map-table", [span("Dispatch Map")]),
      div(class="furniture furniture-radio", [span("Mayor Radio")]),
      div(class="furniture furniture-policy-board", [span("Policy Board")]),
      div(class="furniture furniture-archive", [span("Town Ledger")]),
    ]
  } else if node.key == "worker-yard" {
    [
      div(class="furniture furniture-bench", [span("Ready Bench")]),
      div(class="furniture furniture-tool-rack", [span("Tool Rack")]),
      div(class="furniture furniture-queue-board", [span("Queue Board")]),
      div(class="furniture furniture-rest-mat", [span("Rest Mat")]),
    ]
  } else if node.key.contains("book") {
    [
      div(class="furniture furniture-desk", [span("Keeper Desk")]),
      div(class="furniture furniture-bookshelf", [span("Wiki Shelf")]),
      div(class="furniture furniture-memory-crystal", [span("Memory Core")]),
      div(class="furniture furniture-review-table", [span("Review Table")]),
    ]
  } else {
    [
      div(class="furniture furniture-signal-post", [span("Signal Post")]),
      div(class="furniture furniture-repair-box", [span("Repair Box")]),
      div(class="furniture furniture-log-wall", [span("Event Wall")]),
    ]
  }
}

///|
fn render_interior_agent(
  dispatch : Dispatch[Msg],
  worker : WorkerSim,
) -> @rabbita.Html {
  button(
    class="interior-agent \{worker_status_class(worker.status)}",
    on_click=dispatch(SelectWorker(worker.id)),
    [
      span(class="worker-badge", worker_avatar_initials(worker.title)),
      span(class="worker-label", worker.title),
      span(class="worker-meta", "\{worker.role} / \{worker.status.to_string()}"),
    ],
  )
}

///|
fn render_building_interior(
  dispatch : Dispatch[Msg],
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  node_key : String,
) -> @rabbita.Html {
  let node = scene_node_by_key(scene, node_key)
  let residents = workers_inside_node(node, workers)
  section(class="interior-shell", [
    header(class="interior-header", [
      div([
        p(class="eyebrow", "Interior View"),
        h2(node.title),
        p(class="scene-node-key", node.key),
      ]),
      button(
        class="control-button",
        on_click=dispatch(SelectOverview),
        "Back To Town",
      ),
    ]),
    div(class="interior-room", [
      div(class="interior-floor", furniture_for_node(node)),
      div(
        class="interior-agent-grid",
        if residents.is_empty() {
          [p(class="interior-empty", "No visible agents inside this room.")]
        } else {
          residents.map(worker => render_interior_agent(dispatch, worker))
        },
      ),
    ]),
  ])
}
