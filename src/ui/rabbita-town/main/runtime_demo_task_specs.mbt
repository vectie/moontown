///|
fn task_specs(model : Model) -> Array[@core.TownTask] {
  [
    @core.TownTask::new(
      id="task-town-shell-implementation-backlog",
      book_id="wenyu-town-shell",
      title="Materialize Town Shell implementation backlog",
      prompt="Turn the Wenyu Valley PRD and evidence lane into codex-ready files, acceptance checks, and projection tasks.",
      domain=Coding,
      required_role=Some(Planner),
      required_capabilities=["planning", "projection"],
      status=task_status_for(model, 0),
    ),
    @core.TownTask::new(
      id="task-town-shell-code-patch",
      book_id="wenyu-town-shell",
      title="Patch Town Shell live district slice",
      prompt="Replace hardcoded module framing with live Town Shell projection signals and reviewable district status.",
      domain=Coding,
      required_role=Some(Harness),
      required_capabilities=["projection", "ui-state", "testing"],
      status=task_status_for(model, 1),
    ),
    @core.TownTask::new(
      id="task-town-shell-image-asset-pack",
      book_id="wenyu-town-shell",
      title="Generate Town Shell asset pack",
      prompt="Produce tile, icon, worker sprite, and vignette prompts that fit the warm civic Wenyu district style.",
      domain=Coding,
      required_role=Some(Reviewer),
      required_capabilities=["asset-generation", "design", "projection"],
      status=task_status_for(model, 2),
    ),
    @core.TownTask::new(
      id="task-resident-twins-code-patch",
      book_id="wenyu-resident-twins",
      title="Project Resident Twins live district state",
      prompt="Replace generic Resident Twins framing with live worker, queue, health, and next-action status while keeping memory projection-safe.",
      domain=Coding,
      required_role=Some(MemoryKeeper),
      required_capabilities=["resident-memory", "reflection", "projection"],
      status=task_status_for(model, 3),
    ),
    @core.TownTask::new(
      id="task-policy-quest",
      book_id="policy-hall",
      title="Explain rental subsidy quest",
      prompt="Convert a policy into a scenario quest, checklist, and resident-facing reward path.",
      domain=Operations,
      required_role=Some(Specialist),
      required_capabilities=["policy", "checklist"],
      status=task_status_for(model, 4),
    ),
    @core.TownTask::new(
      id="task-contest-readiness",
      book_id="wenyu-contest-express",
      title="Coach resident contest readiness",
      prompt="Analyze contest rules, review the deck intro, score readiness gaps, and stage the next mock roadshow action.",
      domain=Operations,
      required_role=Some(Planner),
      required_capabilities=["contest", "mock-judge", "readiness"],
      status=task_status_for(model, 5),
    ),
    @core.TownTask::new(
      id="task-cafe-match",
      book_id="social-square",
      title="Match two complementary OPCs",
      prompt="Detect business complementarity and stage a low-pressure cafe introduction.",
      domain=SocialExperiment,
      required_role=Some(Operator),
      required_capabilities=["matching", "community"],
      status=task_status_for(model, 6),
    ),
    @core.TownTask::new(
      id="task-talent-graph",
      book_id="talent-avenue",
      title="Refresh talent heatmap",
      prompt="Update resident skills, achievements, and tour-ready showcase cards.",
      domain=Research,
      required_role=Some(MemoryKeeper),
      required_capabilities=["talent-graph", "projection"],
      status=task_status_for(model, 7),
    ),
    @core.TownTask::new(
      id="task-ai-tip",
      book_id="ai-garden",
      title="Publish daily AI tool trial",
      prompt="Turn one practical AI workflow into a five-minute resident tutorial.",
      domain=Research,
      required_role=Some(Planner),
      required_capabilities=["tutorial", "tool-trial"],
      status=task_status_for(model, 8),
    ),
    @core.TownTask::new(
      id="task-physical-bridge-sync",
      book_id="wenyu-physical-bridge",
      title="Project Physical Bridge live district state",
      prompt="Bridge virtual requests into room availability, robot confirmation, proxy attendance, and live district telemetry.",
      domain=Operations,
      required_role=Some(Watcher),
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
      0 => Assigned
      1 => Running
      2 => Running
      3 => Planned
      4 => Assigned
      5 => Running
      6 => Pending
      _ => Running
    }
  } else if model.pressure > 80 && (cycle == 3 || cycle == 6) {
    Assigned
  } else {
    match cycle {
      0 => Pending
      1 => Assigned
      2 => Running
      3 => Running
      4 => Assigned
      5 => Planned
      6 => Pending
      _ => Running
    }
  }
}
