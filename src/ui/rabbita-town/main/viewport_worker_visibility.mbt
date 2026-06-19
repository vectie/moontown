///|
fn is_working_worker(worker : WorkerSim) -> Bool {
  match worker.status {
    Running | Blocked => true
    _ => false
  }
}

///|
fn is_on_duty_watcher(worker : WorkerSim) -> Bool {
  worker.role.contains("Watcher")
}

///|
fn visible_overworld_workers(workers : Array[WorkerSim]) -> Array[WorkerSim] {
  workers.filter(worker => {
    is_working_worker(worker) || is_on_duty_watcher(worker)
  })
}

///|
priv enum WorkerNodeOwnership {
  DirectZone
  BookNode
  BookKeyMention
  WorkerYardIdle
  NotOwned
}

///|
fn worker_node_ownership(
  node : @ui.SceneRenderNode,
  worker : WorkerSim,
) -> WorkerNodeOwnership {
  worker_node_ownership_for_key(node.key, worker)
}

///|
fn worker_node_ownership_for_key(
  node_key : String,
  worker : WorkerSim,
) -> WorkerNodeOwnership {
  if worker.zone_key == node_key {
    DirectZone
  } else if node_key == "book-\{worker.book_id}" {
    BookNode
  } else if node_key.contains(worker.book_id) {
    BookKeyMention
  } else if node_key == "worker-yard" && !is_working_worker(worker) {
    WorkerYardIdle
  } else {
    NotOwned
  }
}

///|
fn node_owns_worker(node : @ui.SceneRenderNode, worker : WorkerSim) -> Bool {
  match worker_node_ownership(node, worker) {
    DirectZone | BookNode | BookKeyMention | WorkerYardIdle => true
    NotOwned => false
  }
}

///|
fn workers_inside_node(
  node : @ui.SceneRenderNode,
  workers : Array[WorkerSim],
) -> Array[WorkerSim] {
  workers.filter(worker => node_owns_worker(node, worker))
}
