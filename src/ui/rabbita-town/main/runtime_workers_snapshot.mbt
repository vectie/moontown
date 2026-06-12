///|
fn snapshot_worker_sims(model : Model) -> Array[WorkerSim] {
  match model.projection_snapshot {
    Some(snapshot) =>
      if snapshot.town.workers.is_empty() {
        fallback_snapshot_worker_sims()
      } else {
        snapshot.town.workers.map(worker => {
          let profile = snapshot_worker_profile(worker.status)
          {
            id: worker.id,
            title: worker.name,
            role: "\{worker.role}",
            book_id: worker.book_id,
            status: worker.status,
            zone_key: worker_zone_key(worker.book_id, worker.status),
            energy: profile.energy,
            load: profile.load,
            summary: snapshot_worker_summary(worker),
          }
        })
      }
    None => fallback_snapshot_worker_sims()
  }
}

///|
fn fallback_snapshot_worker_sims() -> Array[WorkerSim] {
  [
    {
      id: "snapshot-bridge",
      title: "Snapshot Bridge",
      role: "Watcher",
      book_id: "snapshot",
      status: @core.WorkerStatus::Waiting,
      zone_key: "worker-yard",
      energy: 100,
      load: 12,
      summary: "Waiting for a static or local endpoint bridge into `.moontown/town.json`.",
    },
  ]
}

///|
priv struct SnapshotWorkerProfile {
  load : Int
  energy : Int
}

///|
fn snapshot_worker_profile(
  status : @core.WorkerStatus,
) -> SnapshotWorkerProfile {
  match status {
    @core.WorkerStatus::Running => { load: 74, energy: 64 }
    @core.WorkerStatus::Waiting => { load: 28, energy: 79 }
    @core.WorkerStatus::Idle => { load: 16, energy: 88 }
    @core.WorkerStatus::Blocked => { load: 91, energy: 38 }
    @core.WorkerStatus::Offline => { load: 0, energy: 0 }
  }
}

///|
fn snapshot_worker_summary(worker : @core.WorkerRef) -> String {
  let capability_count = worker.capabilities.length()
  let capability_text = if capability_count == 0 {
    "no declared capabilities yet"
  } else if capability_count == 1 {
    "1 declared capability"
  } else {
    "\{capability_count} declared capabilities"
  }
  if worker.role.to_string() == "Watcher" &&
    worker.status == @core.WorkerStatus::Idle {
    return "\{worker.name} is on duty for the 30-minute standing-watch loop. Idle means waiting between checks, not offline; the mayor message feed shows the latest check result."
  }
  "\{worker.name} is projected from persisted town state with status \{worker.status}, role \{worker.role}, and \{capability_text}."
}
