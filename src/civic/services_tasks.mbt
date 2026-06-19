///|
pub fn wenyu_civic_book_entry(
  service : CivicServiceDefinition,
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id=service.book_id,
    name="Wenyu Valley / \{service.title}",
    purpose=service.purpose,
    workspace_root=@moonbook.default_workspace_root(service.book_id),
    memory_scope=BookPrivate,
    tags=[
      "wenyu-valley",
      "civic-service",
      service.id,
      service.service_kind,
      "module-mode:\{service.module_mode}",
      "persistence-mode:\{service.persistence_mode}",
      "book-role:\{service.book_role}",
      "parallel-lane",
    ],
    skills=[
      "civic-service",
      service.skill_pack,
      service.service_kind,
      service.skill_mode,
      service.module_mode,
      "memory",
      "review",
      "projection",
    ],
  )
}

///|
pub fn wenyu_civic_service_task(
  service : CivicServiceDefinition,
  objective : String,
) -> @moonbook.BookTask {
  @moonbook.BookTask::new(
    id="goal-\{service.book_id}-civic-service",
    goal=Some(objective),
    title="Operate civic service workflow for \{service.title}",
    kind="civic-service-workflow",
    prompt=civic_service_task_prompt(service, objective),
    priority=138,
    requires_review=true,
    target_pages=service.target_pages,
    required_role=Some(service.worker_role),
  )
}

///|
pub fn civic_service_task_prompt(
  service : CivicServiceDefinition,
  objective : String,
) -> String {
  [
    "Operate the Wenyu Valley civic module `\{service.title}` as a module-native civic service lane.",
    "",
    "This is not a marketing-card task and not a generic research task. Use the module skill pack and decide the best next action from the module mode, current place state, current MoonBook memory, user goal, and review gates.",
    "",
    "## Service Purpose",
    "",
    service.purpose,
    "",
    "## Module Mode",
    "",
    "- Module mode: `\{service.module_mode}`.",
    "- Persistence mode: `\{service.persistence_mode}`.",
    "- MoonBook role: `\{service.book_role}`.",
    "- Skill mode: `\{service.skill_mode}`.",
    "- The building is the civic protocol boundary. MoonBook is only the durable support surface named by the persistence mode.",
    "- Do not force this module into a generic research-report workflow; perform the module-native work described by the skill pack.",
    "",
    "## Agent Work",
    "",
    bullet_lines(service.agent_work),
    "",
    "## Place / Exchange Work",
    "",
    bullet_lines(service.place_work),
    "",
    "## Workflow Hints",
    "",
    bullet_lines(service.workflow),
    "",
    "## Required Contract",
    "",
    "- Output contract: `\{service.output_contract}`.",
    "- Skill pack: `\{service.skill_path}`.",
    "- Building protocol contract: `raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md`.",
    "- Use MoonBook according to its role for this module: `\{service.book_role}`.",
    "- Queue review when the action touches external publication, application advice, bookings, redemptions, personal data, or uncertain evidence.",
    "- Do not hard-code the exact workflow; choose the next useful service action from the current book state and the skill rules.",
    "",
    "## Required Artifacts",
    "",
    bullet_lines(service.target_pages),
    "",
    "## Acceptance",
    "",
    bullet_lines(service.acceptance),
    "",
    "Town objective: \{objective}",
  ].join("\n")
}
