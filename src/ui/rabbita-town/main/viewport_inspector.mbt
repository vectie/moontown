///|
fn selection_title(selection : Selection) -> String {
  match selection {
    Overview => "Town Overview"
    Node(_) => "Zone Inspector"
    Worker(_) => "Worker Inspector"
  }
}

///|
fn find_worker(workers : Array[WorkerSim], worker_id : String) -> WorkerSim? {
  for worker in workers {
    if worker.id == worker_id {
      return Some(worker)
    }
  }
  None
}

///|
fn render_worker_choice_button(
  dispatch : Dispatch[Msg],
  worker : WorkerSim,
) -> @rabbita.Html {
  button(
    class="inspector-action worker-choice",
    on_click=dispatch(SelectWorker(worker.id)),
    "\{worker.title} - \{worker.status.to_string()}",
  )
}

///|
fn render_worker_roster(
  dispatch : Dispatch[Msg],
  workers : Array[WorkerSim],
) -> @rabbita.Html {
  if workers.is_empty() {
    div(class="worker-roster", [p("No workers are visible in this scope.")])
  } else {
    let controls : Array[@rabbita.Html] = [
      p(class="worker-roster-title", "Workers"),
    ]
    for worker in workers {
      controls.push(render_worker_choice_button(dispatch, worker))
    }
    div(class="worker-roster", controls)
  }
}

///|
fn selection_body(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> Array[@rabbita.Html] {
  match model.selection {
    Overview =>
      [
        p(
          "Select a zone or worker to inspect live state. Use town actions to redirect the simulation.",
        ),
        p(
          "Packet-ready: \{count_execution_status(executions, @core.TaskExecutionStatus::PacketReady)}",
        ),
        p(
          "Imported proposals: \{count_execution_status(executions, @core.TaskExecutionStatus::ProposalImported)}",
        ),
        p("Active runs: \{running_execution_count(executions)}"),
        render_worker_roster(dispatch, workers),
        button(
          class="inspector-action",
          on_click=dispatch(InjectBudget),
          "Inspector Inject Budget",
        ),
        button(
          class="inspector-action",
          on_click=dispatch(RelieveQueue),
          "Inspector Relieve Queue",
        ),
        button(
          class="inspector-action",
          on_click=dispatch(StabilityDrill),
          "Inspector Stability Drill",
        ),
      ]
    Node(node_key) => {
      let node = scene_node_by_key(scene, node_key)
      let related_workers = workers.filter(fn(worker) {
        worker.zone_key == node_key
      })
      let related_executions = executions.filter(fn(execution) {
        node_matches_execution(node_key, execution.book_id, execution.status)
      })
      [
        p("Zone: \{node.title}"),
        p("Footprint: \{node.width}x\{node.height}"),
        p("Assets: \{node.asset_paths.length()}"),
        p("Workers present: \{related_workers.length()}"),
        p("Execution records: \{related_executions.length()}"),
        render_worker_roster(dispatch, related_workers),
        button(
          class="inspector-action",
          on_click=dispatch(SelectOverview),
          "Back To Overview",
        ),
      ]
    }
    Worker(worker_id) =>
      match find_worker(workers, worker_id) {
        Some(worker) => {
          let book_execution = find_book_execution(executions, worker.book_id)
          let lifecycle = match book_execution {
            Some(execution) =>
              "Book lifecycle: \{execution.status.to_string()} / \{execution.summary}"
            None => "Book lifecycle: no execution record visible."
          }
          [
            p("Role: \{worker.role}"),
            p("Status: \{worker.status.to_string()}"),
            p("Zone: \{worker.zone_key}"),
            p("Energy: \{worker.energy}%"),
            p("Load: \{worker.load}%"),
            p(worker.summary),
            p(lifecycle),
            button(
              class="inspector-action",
              on_click=dispatch(RelieveQueue),
              "Worker Relieve Queue",
            ),
            button(
              class="inspector-action",
              on_click=dispatch(StabilityDrill),
              "Worker Stability Drill",
            ),
            button(
              class="inspector-action",
              on_click=dispatch(SelectOverview),
              "Back To Overview",
            ),
          ]
        }
        None => [p("The selected worker is no longer visible in the scene.")]
      }
  }
}

///|
fn render_inspector(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  section(class="inspector-panel", [
    h2(selection_title(model.selection)),
    div(
      class="inspector-body",
      selection_body(dispatch, model, scene, workers, executions),
    ),
  ])
}
