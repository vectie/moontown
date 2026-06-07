///|
fn task_specs(model : Model) -> Array[@core.TownTask] {
  [
    @core.TownTask::new(
      id="task-town-shell-implementation-backlog",
      book_id="wenyu-town-shell",
      title="Materialize Town Shell implementation backlog",
      prompt="Turn the Wenyu Valley PRD and evidence lane into codex-ready files, acceptance checks, and projection tasks.",
      domain=@core.WorkDomain::Coding,
      required_role=Some(@core.WorkerRole::Planner),
      required_capabilities=["planning", "projection"],
      status=task_status_for(model, 0),
    ),
    @core.TownTask::new(
      id="task-town-shell-code-patch",
      book_id="wenyu-town-shell",
      title="Patch Town Shell live district slice",
      prompt="Replace hardcoded module framing with live Town Shell projection signals and reviewable district status.",
      domain=@core.WorkDomain::Coding,
      required_role=Some(@core.WorkerRole::Harness),
      required_capabilities=["projection", "ui-state", "testing"],
      status=task_status_for(model, 1),
    ),
    @core.TownTask::new(
      id="task-town-shell-image-asset-pack",
      book_id="wenyu-town-shell",
      title="Generate Town Shell asset pack",
      prompt="Produce tile, icon, worker sprite, and vignette prompts that fit the warm civic Wenyu district style.",
      domain=@core.WorkDomain::Coding,
      required_role=Some(@core.WorkerRole::Reviewer),
      required_capabilities=["asset-generation", "design", "projection"],
      status=task_status_for(model, 2),
    ),
    @core.TownTask::new(
      id="task-resident-twins-code-patch",
      book_id="wenyu-resident-twins",
      title="Project Resident Twins live district state",
      prompt="Replace generic Resident Twins framing with live worker, queue, health, and next-action status while keeping memory projection-safe.",
      domain=@core.WorkDomain::Coding,
      required_role=Some(@core.WorkerRole::MemoryKeeper),
      required_capabilities=["resident-memory", "reflection", "projection"],
      status=task_status_for(model, 3),
    ),
    @core.TownTask::new(
      id="task-policy-quest",
      book_id="policy-hall",
      title="Explain rental subsidy quest",
      prompt="Convert a policy into a scenario quest, checklist, and resident-facing reward path.",
      domain=@core.WorkDomain::Operations,
      required_role=Some(@core.WorkerRole::Specialist),
      required_capabilities=["policy", "checklist"],
      status=task_status_for(model, 4),
    ),
    @core.TownTask::new(
      id="task-contest-readiness",
      book_id="wenyu-contest-express",
      title="Coach resident contest readiness",
      prompt="Analyze contest rules, review the deck intro, score readiness gaps, and stage the next mock roadshow action.",
      domain=@core.WorkDomain::Operations,
      required_role=Some(@core.WorkerRole::Planner),
      required_capabilities=["contest", "mock-judge", "readiness"],
      status=task_status_for(model, 5),
    ),
    @core.TownTask::new(
      id="task-cafe-match",
      book_id="social-square",
      title="Match two complementary OPCs",
      prompt="Detect business complementarity and stage a low-pressure cafe introduction.",
      domain=@core.WorkDomain::SocialExperiment,
      required_role=Some(@core.WorkerRole::Operator),
      required_capabilities=["matching", "community"],
      status=task_status_for(model, 6),
    ),
    @core.TownTask::new(
      id="task-talent-graph",
      book_id="talent-avenue",
      title="Refresh talent heatmap",
      prompt="Update resident skills, achievements, and tour-ready showcase cards.",
      domain=@core.WorkDomain::Research,
      required_role=Some(@core.WorkerRole::MemoryKeeper),
      required_capabilities=["talent-graph", "projection"],
      status=task_status_for(model, 7),
    ),
    @core.TownTask::new(
      id="task-ai-tip",
      book_id="ai-garden",
      title="Publish daily AI tool trial",
      prompt="Turn one practical AI workflow into a five-minute resident tutorial.",
      domain=@core.WorkDomain::Research,
      required_role=Some(@core.WorkerRole::Planner),
      required_capabilities=["tutorial", "tool-trial"],
      status=task_status_for(model, 8),
    ),
    @core.TownTask::new(
      id="task-physical-bridge-sync",
      book_id="wenyu-physical-bridge",
      title="Project Physical Bridge live district state",
      prompt="Bridge virtual requests into room availability, robot confirmation, proxy attendance, and live district telemetry.",
      domain=@core.WorkDomain::Operations,
      required_role=Some(@core.WorkerRole::Watcher),
      required_capabilities=["robot", "venue", "digital-twin"],
      status=task_status_for(model, 9),
    ),
  ]
}

///|
fn task_status_for(model : Model, offset : Int) -> @core.TownTaskStatus {
  let cycle = (model.tick + offset) % 8
  if mayor_recovery_active(model) {
    match cycle {
      0 => @core.TownTaskStatus::Assigned
      1 => @core.TownTaskStatus::Running
      2 => @core.TownTaskStatus::Running
      3 => @core.TownTaskStatus::Planned
      4 => @core.TownTaskStatus::Assigned
      5 => @core.TownTaskStatus::Running
      6 => @core.TownTaskStatus::Pending
      _ => @core.TownTaskStatus::Running
    }
  } else if model.pressure > 80 && (cycle == 3 || cycle == 6) {
    @core.TownTaskStatus::Assigned
  } else {
    match cycle {
      0 => @core.TownTaskStatus::Pending
      1 => @core.TownTaskStatus::Assigned
      2 => @core.TownTaskStatus::Running
      3 => @core.TownTaskStatus::Running
      4 => @core.TownTaskStatus::Assigned
      5 => @core.TownTaskStatus::Planned
      6 => @core.TownTaskStatus::Pending
      _ => @core.TownTaskStatus::Running
    }
  }
}
