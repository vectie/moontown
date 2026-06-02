///|
async test "planbook autonomy doctor writes self-healing evidence" {
  let root = "/tmp/moontown-planbook-autonomy-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let catalog_path = "\{root}/catalog.json"
  let message = write_moontown_planbook_autonomy(
    snapshot_path~,
    workspace_root~,
    book_catalog_path=catalog_path,
  )
  assert_true(message.contains("PlanBook autonomy status"))
  let status_text = read_text_or_empty(
    default_planbook_autonomy_path(snapshot_path~),
  )
  let evidence = read_text_or_empty(
    "\{workspace_root}/wiki/planning/execution-evidence.md",
  )
  let review = read_text_or_empty(
    "\{workspace_root}/wiki/reviews/active-plan-review.md",
  )
  let backlog = read_text_or_empty(
    "\{workspace_root}/wiki/planning/implementation-backlog.md",
  )
  let change_log = read_text_or_empty(
    "\{workspace_root}/wiki/history/change-log.md",
  )
  let engineering_digest = read_text_or_empty(
    "\{workspace_root}/wiki/history/daily-engineering-digest.md",
  )
  let progress = read_text_or_empty(
    "\{workspace_root}/wiki/planning/backlog-progress.md",
  )
  let stop_policy = read_text_or_empty(
    "\{workspace_root}/wiki/planning/stop-policy.md",
  )
  let role_model = read_text_or_empty(
    "\{workspace_root}/wiki/planning/role-model.md",
  )
  let operating_architecture = read_text_or_empty(
    "\{workspace_root}/wiki/planning/operating-architecture.md",
  )
  assert_true(status_text.contains("\"status\": \"self-healing-open\""))
  assert_true(status_text.contains("editor-mode-real-pipeline"))
  assert_true(status_text.contains("planbook-source-patch-loop"))
  assert_true(status_text.contains("planbook-software-engineering-loop"))
  assert_true(status_text.contains("backlog-live-change-log-projection"))
  assert_true(status_text.contains("moonbook-native-planbook-provider"))
  assert_true(evidence.contains("PlanBook autonomy doctor"))
  assert_true(review.contains("needs-fix"))
  assert_true(backlog.contains("live-change-log-projection"))
  assert_true(change_log.contains("autonomy doctor"))
  assert_true(engineering_digest.contains("Daily Engineering Digest"))
  assert_true(engineering_digest.contains("Source-Control Policy"))
  assert_true(progress.contains("next_check_interval_ms"))
  assert_true(progress.contains("take the next bounded task immediately"))
  assert_true(stop_policy.contains("The town should stop implementing"))
  assert_true(stop_policy.contains("already complete"))
  assert_true(role_model.contains("Mayor"))
  assert_true(role_model.contains("MoonBook Bookkeeper"))
  assert_true(role_model.contains("MoonClaw Worker"))
  assert_true(role_model.contains("freelance executor"))
  assert_true(operating_architecture.contains("Operating Architecture"))
  assert_true(operating_architecture.contains("Growth Contract"))
  assert_true(operating_architecture.contains("Civic Wiring Rule"))
}

///|
async test "planbook validation evidence requires explicit validation contract" {
  assert_true(
    !planbook_validation_evidence_ready(
      "# Latest PlanBook Validation\n\n- moon check passed\n",
    ),
  )
  let root = "/tmp/moontown-planbook-validation-evidence-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let path = write_moontown_planbook_validation_evidence(
    snapshot_path="\{root}/town.json",
    note="test validation record",
  )
  let text = read_text_or_empty(path)
  assert_true(planbook_validation_evidence_ready(text))
  assert_true(text.contains("contract: planbook.validation.v1"))
  assert_true(text.contains("validation_status: passed"))
}

///|
async test "planbook autonomy doctor repairs missing seed architecture page" {
  let root = "/tmp/moontown-planbook-seed-repair-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  write_text_file(
    "\{workspace_root}/wiki/index.md",
    "# Existing PlanBook\n\nDo not overwrite existing operator-authored content.",
  )
  ignore(
    write_moontown_planbook_autonomy(
      snapshot_path~,
      workspace_root~,
      book_catalog_path="\{root}/catalog.json",
    ),
  )
  let index = read_text_or_empty("\{workspace_root}/wiki/index.md")
  let operating_architecture = read_text_or_empty(
    "\{workspace_root}/wiki/planning/operating-architecture.md",
  )
  assert_true(index.contains("Do not overwrite existing"))
  assert_true(operating_architecture.contains("Operating Architecture"))
  assert_true(operating_architecture.contains("Stable Watch State"))
}

///|
async test "live autonomy includes planbook repair action" {
  let root = "/tmp/moontown-planbook-live-action-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  ignore(
    write_moontown_planbook_autonomy(
      snapshot_path~,
      workspace_root~,
      book_catalog_path="\{root}/catalog.json",
    ),
  )
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    tick_summary="planbook action check",
  )
  assert_true(spine.planbook_open_count > 0)
  assert_true(spine.next_actions.join("\n").contains("PlanBook has"))
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(status.contains("PlanBook open gaps"))
}

///|
async test "editor pipeline refresh writes runtime contract" {
  let root = "/tmp/moontown-editor-pipeline-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  ignore(
    bootstrap_moontown_planbook(
      book_catalog_path="\{root}/catalog.json",
      workspace_root~,
    ),
  )
  let path = write_editor_pipeline_state(snapshot_path~, workspace_root~)
  let text = read_text_or_empty(path)
  let digest = read_text_or_empty(
    default_editor_pipeline_markdown_path(snapshot_path~),
  )
  assert_true(text.contains("moontown.editor_pipeline.v1"))
  assert_true(text.contains("command-contract"))
  assert_true(text.contains("feature-selection"))
  assert_true(text.contains("viewport-binding"))
  assert_true(text.contains("movement-loop-evidence"))
  assert_true(text.contains("placement-diff-preview"))
  assert_true(text.contains("terrain-label-map"))
  assert_true(text.contains("style-comparison-workbench"))
  assert_true(text.contains("\"movement_loops\""))
  assert_true(text.contains("\"placement_diffs\""))
  assert_true(text.contains("\"terrain_layers\""))
  assert_true(text.contains("\"terrain_reasons\""))
  assert_true(text.contains("\"style_candidates\""))
  assert_true(text.contains("\"style_selection\""))
  assert_true(text.contains("\"lifecycle_status\": \"planned\""))
  assert_true(text.contains("\"selected_feature\": \"none\""))
  assert_true(digest.contains("Editor Pipeline Status"))
  assert_true(digest.contains("Movement Loop Evidence"))
  assert_true(digest.contains("Placement Diff Preview"))
  assert_true(digest.contains("Terrain Label Map"))
  assert_true(digest.contains("Style Comparison Workbench"))
  write_text_file(
    "\{workspace_root}/raw/editor-pipeline/next-feature.json",
    "{\"contract\":\"moontown.editor_feature_selection.v1\",\"selected_feature\":\"output-readiness-lifecycle\",\"title\":\"Output Readiness Lifecycle\",\"score\":1,\"implementation_hint\":\"add lifecycle\",\"acceptance\":[\"ready-to-export visible\"]}",
  )
  write_text_file(
    "\{workspace_root}/raw/editor-pipeline/selected-feature-implementation.md",
    "contract: moontown.editor_selected_feature_implementation.v1\nselected_feature: output-readiness-lifecycle\nimplementation_status: accepted\nvalidation: test",
  )
  let ready_path = write_editor_pipeline_state(snapshot_path~, workspace_root~)
  let ready_text = read_text_or_empty(ready_path)
  assert_true(ready_text.contains("\"status\": \"ready\""))
  assert_true(ready_text.contains("\"lifecycle_status\": \"ready-to-export\""))
  assert_true(
    ready_text.contains("\"selected_feature\": \"output-readiness-lifecycle\""),
  )
  write_text_file(
    "\{workspace_root}/raw/editor-pipeline/next-feature.json",
    "{\"contract\":\"moontown.editor_feature_selection.v1\",\"selected_feature\":\"movement-loop-evidence\",\"title\":\"Movement Loop Evidence\",\"score\":1,\"implementation_hint\":\"add route proof\",\"acceptance\":[\"home to entrance to output to home visible\"]}",
  )
  write_text_file(
    "\{workspace_root}/raw/editor-pipeline/selected-feature-implementation.md",
    "contract: moontown.editor_selected_feature_implementation.v1\nselected_feature: movement-loop-evidence\nimplementation_status: accepted\nvalidation: test",
  )
  let movement_path = write_editor_pipeline_state(
    snapshot_path~,
    workspace_root~,
  )
  let movement_text = read_text_or_empty(movement_path)
  assert_true(movement_text.contains("\"status\": \"ready\""))
  assert_true(
    movement_text.contains("\"selected_feature\": \"movement-loop-evidence\""),
  )
  assert_true(movement_text.contains("\"home_ref\": \"book:"))
  assert_true(movement_text.contains("\"entrance_ref\": \"tile:"))
  assert_true(movement_text.contains("\"output_ref\": \"viewport:output#"))
  write_text_file(
    "\{workspace_root}/raw/editor-pipeline/next-feature.json",
    "{\"contract\":\"moontown.editor_feature_selection.v1\",\"selected_feature\":\"placement-diff-preview\",\"title\":\"Placement Diff Preview\",\"score\":1,\"implementation_hint\":\"add reviewable placement diff\",\"acceptance\":[\"placement diff visible before export\"]}",
  )
  write_text_file(
    default_editor_placement_proposal_path(workspace_root~),
    "{\"version\":2,\"description\":\"test placement proposal\",\"modules\":[{\"id\":\"town-shell\",\"enabled\":true,\"title\":\"Town Shell\",\"book_id\":\"wenyu-town-shell\",\"district\":\"civic-core\",\"building_kind\":\"town-shell\",\"grid_x\":130,\"grid_y\":74,\"footprint_w\":8,\"footprint_h\":6,\"display_w\":230,\"display_h\":170,\"entrance_x\":130,\"entrance_y\":81,\"interior_kind\":\"mayor\",\"style_family\":\"white-tech-pavilion\",\"asset_base\":\"tilemap/buildings/white-tech-pavilion/alpha/town-shell.png\",\"asset_roof\":\"\",\"protocol_pattern\":\"mayor-supervision\",\"use_case\":\"Mayor supervision\",\"agent_flow\":\"Agents route through mayor\",\"summary\":\"Mayor supervision\"}]}",
  )
  write_text_file(
    "\{workspace_root}/raw/editor-pipeline/selected-feature-implementation.md",
    "contract: moontown.editor_selected_feature_implementation.v1\nselected_feature: placement-diff-preview\nimplementation_status: accepted\nvalidation: test",
  )
  let placement_path = write_editor_pipeline_state(
    snapshot_path~,
    workspace_root~,
  )
  let placement_text = read_text_or_empty(placement_path)
  assert_true(placement_text.contains("\"status\": \"ready\""))
  assert_true(
    placement_text.contains("\"selected_feature\": \"placement-diff-preview\""),
  )
  assert_true(placement_text.contains("\"change_kind\": \"moved\""))
  assert_true(placement_text.contains("\"terrain_status\":"))
  assert_true(placement_text.contains("\"before_ref\": \"tile:"))
  assert_true(placement_text.contains("\"after_ref\": \"tile:130,74/8x6\""))
  write_text_file(
    "\{workspace_root}/raw/editor-pipeline/next-feature.json",
    "{\"contract\":\"moontown.editor_feature_selection.v1\",\"selected_feature\":\"terrain-label-map\",\"title\":\"Terrain Label Map Layers\",\"score\":1,\"implementation_hint\":\"add terrain label evidence\",\"acceptance\":[\"terrain labels visible before export\"]}",
  )
  write_text_file(
    "\{workspace_root}/raw/editor-pipeline/selected-feature-implementation.md",
    "contract: moontown.editor_selected_feature_implementation.v1\nselected_feature: terrain-label-map\nimplementation_status: accepted\nvalidation: test",
  )
  let terrain_path = write_editor_pipeline_state(
    snapshot_path~,
    workspace_root~,
  )
  let terrain_text = read_text_or_empty(terrain_path)
  let terrain_digest = read_text_or_empty(
    default_editor_pipeline_markdown_path(snapshot_path~),
  )
  assert_true(terrain_text.contains("\"status\": \"ready\""))
  assert_true(
    terrain_text.contains("\"selected_feature\": \"terrain-label-map\""),
  )
  assert_true(terrain_text.contains("\"layer_id\": \"water\""))
  assert_true(terrain_text.contains("\"layer_id\": \"roads\""))
  assert_true(terrain_text.contains("\"layer_id\": \"farms\""))
  assert_true(terrain_text.contains("\"layer_id\": \"forests\""))
  assert_true(terrain_text.contains("\"terrain_layer\":"))
  assert_true(terrain_text.contains("\"placement_ref\": \"tile:"))
  assert_true(terrain_digest.contains("Module Terrain Reasons"))
  write_text_file(
    "\{workspace_root}/raw/editor-pipeline/next-feature.json",
    "{\"contract\":\"moontown.editor_feature_selection.v1\",\"selected_feature\":\"style-comparison-workbench\",\"title\":\"Building Style Comparison Workbench\",\"score\":2,\"implementation_hint\":\"compare visual styles\",\"acceptance\":[\"three style candidates visible\"]}",
  )
  write_text_file(
    "\{workspace_root}/raw/editor-pipeline/selected-feature-implementation.md",
    "contract: moontown.editor_selected_feature_implementation.v1\nselected_feature: style-comparison-workbench\nimplementation_status: accepted\nvalidation: test",
  )
  let style_path = write_editor_pipeline_state(snapshot_path~, workspace_root~)
  let style_text = read_text_or_empty(style_path)
  let style_digest = read_text_or_empty(
    default_editor_pipeline_markdown_path(snapshot_path~),
  )
  assert_true(style_text.contains("\"status\": \"ready\""))
  assert_true(
    style_text.contains("\"selected_feature\": \"style-comparison-workbench\""),
  )
  assert_true(style_text.contains("\"style_id\": \"white-tech-pavilion\""))
  assert_true(style_text.contains("\"style_id\": \"wenyu-pixel-backup\""))
  assert_true(style_text.contains("\"style_id\": \"shape-label-workbench\""))
  assert_true(style_text.contains("\"selected\": true"))
  assert_true(
    style_text.contains("\"selected_style_id\": \"white-tech-pavilion\""),
  )
  assert_true(style_digest.contains("Style Comparison Workbench"))
}

///|
async test "editor feature selection packet asks ai to choose from course evidence" {
  let root = "/tmp/moontown-editor-feature-selection-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let message = write_editor_feature_selection_task(
    snapshot_path~,
    workspace_root~,
  )
  let task_text = read_text_or_empty(
    default_editor_feature_selection_path(snapshot_path~),
  )
  let packet_text = read_text_or_empty(
    "\{workspace_root}/raw/editor-pipeline/editor-feature-selection.packet.json",
  )
  let skill_text = read_text_or_empty(
    "\{workspace_root}/skills/editor-feature-rater/SKILL.md",
  )
  let profile_text = read_text_or_empty("\{workspace_root}/moonclaw.jobs.json")
  assert_true(message.contains("Editor feature selection task"))
  assert_true(task_text.contains("\"status\": \"queued\""))
  assert_true(packet_text.contains("moontown.editor_feature_selection.v1"))
  assert_true(packet_text.contains("course-wenyu-game-design"))
  assert_true(packet_text.contains("\"best_effort_on_timeout\":false"))
  assert_true(packet_text.contains("Do not rely on a hardcoded candidate list"))
  assert_true(skill_text.contains("Editor Feature Rater Skill"))
  assert_true(skill_text.contains("Scoring Rubric"))
  assert_true(profile_text.contains("editor_feature_rater"))
  assert_true(
    read_text_or_empty(
      "\{workspace_root}/plans/2026-05-31-editor-mode-real-pipeline/plan.md",
    ).contains("Editor Mode Real Pipeline"),
  )
  assert_true(
    packet_text.contains(
      "Write JSON to `\{workspace_root}/raw/editor-pipeline/next-feature.json`",
    ),
  )
  assert_true(
    !packet_text.contains(
      "Write JSON to `.moontown/books/plan-moontown-quality/raw/editor-pipeline/next-feature.json`",
    ),
  )
  assert_true(!editor_feature_selection_ready(workspace_root~))
  write_text_file(
    "\{workspace_root}/raw/editor-pipeline/next-feature.json",
    "{\"contract\":\"moontown.editor_feature_selection.v1\",\"selected_feature\":\"x\",\"score\":1,\"implementation_hint\":\"small\",\"acceptance\":[\"visible\"]}",
  )
  assert_true(editor_feature_selection_ready(workspace_root~))
  let status = inspect_moontown_planbook_autonomy(
    snapshot_path~,
    workspace_root~,
    book_catalog_path="\{root}/catalog.json",
  )
  assert_true(
    status.criteria.any(fn(item) {
      item.id == "editor-selected-feature-implementation" &&
      !item.satisfied &&
      item.evidence.contains("AI selected `x`")
    }),
  )
  write_text_file(
    "\{workspace_root}/raw/editor-pipeline/selected-feature-implementation.md",
    "contract: moontown.editor_selected_feature_implementation.v1\nselected_feature: x\nimplementation_status: accepted\nvalidation: test",
  )
  assert_true(editor_selected_feature_implementation_ready(workspace_root))
  ignore(write_editor_feature_selection_task(snapshot_path~, workspace_root~))
  let repeat_packet_text = read_text_or_empty(
    "\{workspace_root}/raw/editor-pipeline/editor-feature-selection.packet.json",
  )
  let repeat_context = read_text_or_empty(
    "\{workspace_root}/raw/editor-pipeline/FEATURE_SELECTION_CONTEXT.md",
  )
  let ledger = read_text_or_empty(
    "\{workspace_root}/raw/editor-pipeline/implemented-features.md",
  )
  assert_true(repeat_packet_text.contains("Already Implemented Features"))
  assert_true(repeat_packet_text.contains("exclude every feature"))
  assert_true(repeat_context.contains("## Already Implemented Features"))
  assert_true(repeat_context.contains("- `x`"))
  assert_true(ledger.contains("- `x`"))
  assert_true(
    @fs.exists(
      "\{workspace_root}/raw/editor-pipeline/implemented-features/x.selection.json",
    ),
  )
}

///|
async test "planbook repair queues bounded packet without marking it active before dispatch" {
  let root = "/tmp/moontown-planbook-repair-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  ignore(
    write_moontown_planbook_autonomy(
      snapshot_path~,
      workspace_root~,
      book_catalog_path="\{root}/catalog.json",
    ),
  )
  let message = write_moontown_planbook_repair_task(
    snapshot_path~,
    workspace_root~,
    book_catalog_path="\{root}/catalog.json",
  )
  assert_true(message.contains("PlanBook repair task"))
  let task_text = read_text_or_empty(
    default_planbook_repair_path(snapshot_path~),
  )
  let semantic_packet_text = read_text_or_empty(
    "\{workspace_root}/raw/repair/planbook-repair-semantic-ai-review-results.packet.json",
  )
  let runtime_packet_text = read_text_or_empty(
    "\{workspace_root}/raw/repair/planbook-repair-runtime-books-in-quality-audit.packet.json",
  )
  let packet_text = if semantic_packet_text.is_empty() {
    runtime_packet_text
  } else {
    semantic_packet_text
  }
  let skill_text = read_text_or_empty(
    "\{workspace_root}/skills/planbook-repair/SKILL.md",
  )
  let profile_text = read_text_or_empty("\{workspace_root}/moonclaw.jobs.json")
  assert_true(task_text.contains("\"status\": \"queued\""))
  assert_true(
    task_text.contains("semantic-ai-review-results") ||
    task_text.contains("runtime-books-in-quality-audit"),
  )
  assert_true(packet_text.contains("planbook.repair.result.v1"))
  assert_true(packet_text.contains("\"target_files\""))
  assert_true(
    packet_text.contains("\"execution_mode\":\"acp\"") ||
    packet_text.contains("\"execution_mode\": \"acp\""),
  )
  assert_true(
    packet_text.contains("\"execution_target\":\"codex-main\"") ||
    packet_text.contains("\"execution_target\": \"codex-main\""),
  )
  assert_true(packet_text.contains("required_engineering_steps"))
  assert_true(packet_text.contains("required_validation_commands"))
  assert_true(packet_text.contains("git_policy"))
  assert_true(packet_text.contains("commit_after_validation"))
  assert_true(packet_text.contains("push_after_commit"))
  assert_true(packet_text.contains("\"best_effort_on_timeout\":false"))
  assert_true(skill_text.contains("PlanBook Repair Skill"))
  assert_true(skill_text.contains("Use exact `target_files`"))
  assert_true(skill_text.contains("configured Codex ACP target"))
  assert_true(skill_text.contains("repository source root"))
  assert_true(skill_text.contains("diff_summary"))
  assert_true(skill_text.contains("commit_status"))
  assert_true(skill_text.contains("git diff --check"))
  assert_true(skill_text.contains("git status --short"))
  assert_true(profile_text.contains("planbook_repair_worker"))
  assert_true(profile_text.contains("repair_planbook_gap"))
  assert_true(profile_text.contains("\"execution_mode\": \"acp\""))
  assert_true(profile_text.contains("\"execution_target\": \"codex-main\""))
  assert_eq(planbook_repair_active_count(snapshot_path~), 0)
}

///|
async test "planbook backlog item can drive bounded repair packet from json" {
  let root = "/tmp/moontown-planbook-backlog-repair-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  ignore(
    bootstrap_moontown_planbook(
      book_catalog_path="\{root}/catalog.json",
      workspace_root~,
    ),
  )
  let item = match first_open_planbook_backlog_item(workspace_root) {
    Some(item) => item
    None => fail("expected open backlog item")
  }
  let criterion = planbook_backlog_criterion_for_item(item, workspace_root)
  let task = materialize_planbook_repair_task(
    criterion,
    snapshot_path,
    workspace_root,
    "\{root}/catalog.json",
    false,
    false,
  )
  let packet_text = read_text_or_empty(task.packet_path)
  let skill_text = read_text_or_empty(
    "\{workspace_root}/skills/planbook-repair/SKILL.md",
  )
  assert_true(task.criterion_id.contains("backlog-"))
  assert_true(packet_text.contains("implementation-backlog.json"))
  assert_true(packet_text.contains("raw/backlog/completed"))
  assert_true(skill_text.contains("For `backlog-*` criteria"))
  assert_true(skill_text.contains("already done"))
  assert_true(skill_text.contains("plan_update_status"))
  assert_eq(planbook_repair_active_count(snapshot_path~), 0)
}

///|
async test "editor pipeline repair packet keeps course source context bounded" {
  let root = "/tmp/moontown-editor-pipeline-repair-packet-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let criterion : PlanbookCriterionStatus = {
    id: "editor-mode-real-pipeline",
    plan_id: "2026-05-31-editor-mode-real-pipeline",
    title: "Editor mode creates a real PlanBook-to-MoonClaw implementation pipeline",
    owner: "moontown+planbook+moonclaw",
    satisfied: false,
    evidence: "PlanBook has the editor pipeline plan, but Moontown still lacks the command/state/UI integration",
    next_action: "use the Wenyu course book as source context, then implement a restartable editor-pipeline contract, command surface, UI binding, and validation evidence through PlanBook repair",
  }
  ignore(
    materialize_planbook_repair_task(
      criterion,
      "\{root}/town.json",
      workspace_root,
      "\{root}/catalog.json",
      false,
      false,
    ),
  )
  let packet_text = read_text_or_empty(
    "\{workspace_root}/raw/repair/planbook-repair-editor-mode-real-pipeline.packet.json",
  )
  assert_true(packet_text.contains("planbook.repair.result.v1"))
  assert_true(packet_text.contains("\"target_files\""))
  assert_true(packet_text.contains("\"best_effort_on_timeout\":false"))
  assert_true(packet_text.contains("course-wenyu-game-design"))
  assert_true(packet_text.contains("2026-05-31-editor-mode-real-pipeline"))
}

///|
async test "selected editor feature repair packet is driven by ai selection artifact" {
  let root = "/tmp/moontown-selected-editor-feature-repair-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let workspace_root = "\{root}/books/plan-moontown-quality"
  write_text_file(
    "\{workspace_root}/raw/editor-pipeline/next-feature.json",
    "{\"contract\":\"moontown.editor_feature_selection.v1\",\"selected_feature\":\"building-protocol-history\",\"title\":\"Building Protocol History\",\"score\":1,\"current_gap\":\"history missing\",\"implementation_hint\":\"render protocol history\",\"acceptance\":[\"visible history\"]}",
  )
  let criterion : PlanbookCriterionStatus = {
    id: "editor-selected-feature-implementation",
    plan_id: "2026-05-31-editor-mode-real-pipeline",
    title: "Implement the AI-selected editor-mode feature",
    owner: "moontown+planbook+moonclaw",
    satisfied: false,
    evidence: editor_selected_feature_implementation_evidence(workspace_root),
    next_action: editor_selected_feature_implementation_next_action(
      workspace_root,
    ),
  }
  ignore(
    materialize_planbook_repair_task(
      criterion,
      "\{root}/town.json",
      workspace_root,
      "\{root}/catalog.json",
      false,
      false,
    ),
  )
  let packet_text = read_text_or_empty(
    "\{workspace_root}/raw/repair/planbook-repair-editor-selected-feature-implementation.packet.json",
  )
  let skill_text = read_text_or_empty(
    "\{workspace_root}/skills/planbook-repair/SKILL.md",
  )
  assert_true(packet_text.contains("editor-selected-feature-implementation"))
  assert_true(packet_text.contains("building-protocol-history"))
  assert_true(packet_text.contains("next-feature.json"))
  assert_true(packet_text.contains("selected-feature-implementation.md"))
  assert_true(skill_text.contains("do not choose a different feature"))
}

///|
test "planbook repair result contract rejects best-effort timeout placeholders" {
  let criterion_id = "editor-mode-real-pipeline"
  assert_true(
    !planbook_repair_result_satisfies_contract(
      "Analysis step repair_planbook_gap timed out after 600000ms; continuing because `best_effort_on_timeout` is enabled.",
      criterion_id,
    ),
  )
  assert_true(
    !planbook_repair_result_satisfies_contract(
      [
        "repair_decision: accepted", "criterion_id: editor-mode-real-pipeline", "files_changed: editor_pipeline.mbt",
        "validation: moon check --no-render passed",
      ].join("\n"),
      criterion_id,
    ),
  )
  assert_true(
    planbook_repair_result_satisfies_contract(
      [
        "repair_decision: accepted", "criterion_id: editor-mode-real-pipeline", "files_changed: editor_pipeline.mbt",
        "validation: moon check --no-render passed", "diff_summary: git diff --check passed",
        "plan_update_status: unchanged", "commit_status: ready_to_commit", "commit_message: Add editor pipeline verification",
        "push_status: not_pushed_by_policy",
      ].join("\n"),
      criterion_id,
    ),
  )
  assert_eq(planbook_task_status_from_run_status(Some("Succeeded")), "failed")
}

///|
async test "planbook repair supersedes stale runtime handoff evidence" {
  let root = "/tmp/moontown-planbook-repair-stale-handoff-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let criterion : PlanbookCriterionStatus = {
    id: "live-runtime-recovery",
    plan_id: "test",
    title: "Live runtime failures are visible to PlanBook repair",
    owner: "moontown+moonclaw",
    satisfied: false,
    evidence: "1 failed/stale executions remain: research-opc/task-opc-watch",
    next_action: "repair the current failure set",
  }
  write_text_file(
    "\{workspace_root}/raw/repair/repair-result.md",
    [
      "repair_decision: needs_external_owner", "criterion_id: live-runtime-recovery",
      "remaining_blockers: 18 failed town executions remain.",
    ].join("\n"),
  )
  let task = materialize_planbook_repair_task(
    criterion,
    "\{root}/town.json",
    workspace_root,
    "\{root}/catalog.json",
    false,
    false,
  )
  let result_text = read_text_or_empty(
    "\{workspace_root}/raw/repair/repair-result.md",
  )
  let superseded = read_text_or_empty(
    "\{workspace_root}/raw/repair/repair-result.superseded.md",
  )
  assert_eq(task.status, "queued")
  assert_true(result_text == "")
  assert_true(superseded.contains("18 failed town executions"))
}

///|
async test "planbook repair acp target uses resolved codex command" {
  let root = "/tmp/moontown-planbook-repair-acp-target-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let criterion : PlanbookCriterionStatus = {
    id: "live-runtime-recovery",
    plan_id: "test",
    title: "Live runtime failures are visible to PlanBook repair",
    owner: "moontown+moonclaw",
    satisfied: false,
    evidence: "1 failed/stale executions remain: research-opc/task-opc-watch",
    next_action: "repair the current failure set",
  }
  ignore(
    materialize_planbook_repair_task(
      criterion,
      "\{root}/town.json",
      workspace_root,
      "\{root}/catalog.json",
      false,
      false,
    ),
  )
  let target = read_text_or_empty("\{workspace_root}/.moonclaw/moonclaw.json")
  let source_root = planbook_repair_source_root()
  assert_true(
    target.contains(
      "\"command\": \"/Users/kq/.nvm/versions/node/v22.22.1/bin/node\"",
    ),
  )
  assert_true(
    target.contains(
      "/Users/kq/.nvm/versions/node/v22.22.1/lib/node_modules/@openai/codex/bin/codex.js",
    ),
  )
  assert_true(!target.contains("\"command\": \"codex\""))
  assert_true(target.contains("\"cwd\": \"\{source_root}\""))
  assert_true(target.contains("\"workspace\": \"\{source_root}\""))
  assert_true(!target.contains("\"cwd\": \"\{workspace_root}\""))
}

///|
async test "planbook repair does not treat orphaned pending run as active" {
  let root = "/tmp/moontown-planbook-repair-pending-active-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let task : PlanbookRepairTask = {
    id: "planbook-repair-live-runtime-recovery",
    criterion_id: "live-runtime-recovery",
    title: "Live runtime failures are visible to PlanBook repair",
    status: "dispatched",
    owner: "moontown+moonclaw",
    workspace_root,
    packet_path: "\{workspace_root}/raw/repair/planbook-repair-live-runtime-recovery.packet.json",
    proposal_id: Some("proposal"),
    run_id: Some("run-pending"),
    summary: "Pending repair",
    validation_command: "moon test",
    generated_at_ms: 1,
  }
  write_text_file(
    default_planbook_repair_path(snapshot_path~),
    task.to_json().stringify(indent=2),
  )
  write_text_file(
    "\{workspace_root}/.moonclaw/jobs/index/runs.json",
    "{\"runs\":[{\"id\":\"run-pending\",\"status\":\"Pending\"}]}",
  )
  assert_eq(planbook_repair_active_count(snapshot_path~), 0)
}

///|
async test "planbook repair does not treat orphaned waiting-for-input run as active" {
  let root = "/tmp/moontown-planbook-repair-waiting-active-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let task : PlanbookRepairTask = {
    id: "planbook-repair-live-runtime-recovery",
    criterion_id: "live-runtime-recovery",
    title: "Live runtime failures are visible to PlanBook repair",
    status: "dispatched",
    owner: "moontown+moonclaw",
    workspace_root,
    packet_path: "\{workspace_root}/raw/repair/planbook-repair-live-runtime-recovery.packet.json",
    proposal_id: Some("proposal"),
    run_id: Some("run-waiting"),
    summary: "Waiting repair",
    validation_command: "moon test",
    generated_at_ms: 1,
  }
  write_text_file(
    default_planbook_repair_path(snapshot_path~),
    task.to_json().stringify(indent=2),
  )
  write_text_file(
    "\{workspace_root}/.moonclaw/jobs/index/runs.json",
    "{\"runs\":[{\"id\":\"run-waiting\",\"status\":\"WaitingForInput\"}]}",
  )
  assert_eq(planbook_repair_active_count(snapshot_path~), 0)
}

///|
async test "planbook repair does not treat orphaned running run as active" {
  let root = "/tmp/moontown-planbook-repair-orphaned-active-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let task : PlanbookRepairTask = {
    id: "planbook-repair-live-runtime-recovery",
    criterion_id: "live-runtime-recovery",
    title: "Live runtime failures are visible to PlanBook repair",
    status: "dispatched",
    owner: "moontown+moonclaw",
    workspace_root,
    packet_path: "\{workspace_root}/raw/repair/planbook-repair-live-runtime-recovery.packet.json",
    proposal_id: Some("proposal"),
    run_id: Some("run-orphaned"),
    summary: "Orphaned repair",
    validation_command: "moon test",
    generated_at_ms: 1,
  }
  write_text_file(
    default_planbook_repair_path(snapshot_path~),
    task.to_json().stringify(indent=2),
  )
  write_text_file(
    "\{workspace_root}/.moonclaw/jobs/index/runs.json",
    "{\"runs\":[{\"id\":\"run-orphaned\",\"status\":\"Running\"}]}",
  )
  assert_eq(planbook_repair_active_count(snapshot_path~), 0)
}

///|
test "planbook repair treats temporary dispatch contention as retryable" {
  assert_true(
    planbook_repair_transient_dispatch_error(
      "MoonClaw repair dispatch failed: Resource temporarily unavailable",
    ),
  )
  assert_true(
    planbook_repair_transient_dispatch_error(
      "MoonClaw repair dispatch failed: {bad request}",
    ),
  )
  assert_true(
    planbook_repair_transient_dispatch_error(
      "Error: Failed to resolve the module dependency graph\nUnable to lock folder `/Users/kq/Workspace/moonclaw/.mooncakes` for downloading dependencies\nOperation not permitted (os error 1)",
    ),
  )
  assert_true(
    planbook_repair_transient_dispatch_error(
      "RUNTIME ERROR: abort() called\nStringBuilder::grow_if_necessary\n@vectie/moonclaw/job.SystemStore::save_job_proposals",
    ),
  )
  assert_true(
    !planbook_repair_transient_dispatch_error(
      "MoonClaw repair dispatch failed: schema violation",
    ),
  )
}
