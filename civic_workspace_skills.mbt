///|
fn service_skill_path(
  root : String,
  service : @civic.CivicServiceDefinition,
) -> String {
  "\{root}/\{service.skill_path}"
}

///|
fn wenyu_civic_service_skill_text() -> String {
  [
    civic_skill_frontmatter(
      "wenyu-civic-service", "Operate one Wenyu Valley civic module as a MoonBook-backed service with review gates and projection-safe output.",
    ),
    "# Wenyu Civic Service Skill",
    "",
    "Use this generic skill with the module-specific skill pack in the same workspace.",
    civic_generic_service_rules_section(),
    moonbook_skill_quality_contract_section(),
    civic_required_output_shape_section(),
    civic_generic_service_example_section(),
  ].join("\n")
}

///|
fn civic_module_skill_text(service : @civic.CivicServiceDefinition) -> String {
  [
    civic_skill_frontmatter(
      service.skill_pack,
      "Role-specific MoonClaw skill pack for Wenyu Valley \{service.title}.",
    ),
    "",
    "# \{service.title} Skill Pack",
    "",
    "You are operating the `\{service.title}` module for Wenyu Valley.",
    civic_module_mode_section(service),
    civic_module_purpose_section(service),
    civic_module_decision_section(),
    moonbook_skill_quality_contract_section(),
    civic_module_work_section("Agent Work", service.agent_work),
    civic_module_work_section("Place / Exchange Work", service.place_work),
    civic_module_work_section("Workflow Hints", service.workflow),
    civic_module_output_contract_section(service),
    civic_module_mode_output_section(service),
    civic_module_work_section("Durable Pages", service.target_pages),
    civic_module_work_section("Acceptance", service.acceptance),
    "## Concrete Example\n",
    civic_skill_example(service),
  ].join("\n")
}
