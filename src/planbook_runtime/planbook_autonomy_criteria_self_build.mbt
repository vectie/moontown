///|
async fn planbook_workspace_criterion(
  workspace_root : String,
) -> PlanbookCriterionStatus {
  let ready = @fs.exists("\{workspace_root}/plans/index.md") &&
    @fs.exists("\{workspace_root}/skills/code-plan/SKILL.md") &&
    @fs.exists("\{workspace_root}/wiki/planning/quality-gates.md")
  planbook_criterion(
    "planbook-workspace",
    "2026-05-29-book-quality-upgrade",
    "PlanBook exists as a durable MoonBook workspace",
    "moontown",
    ready,
    if ready {
      "workspace has plans index, planning skill, and quality gates"
    } else {
      "workspace is missing required planbook files"
    },
    "run `moon run src/cmd/main -- planbook bootstrap`",
  )
}

///|
async fn planbook_live_spine_criterion() -> PlanbookCriterionStatus {
  let ready = text_file_contains(
      "src/live_autonomy_runtime/live_autonomy_types.mbt", "planbook_open_count",
    ) &&
    text_file_contains(
      "src/live_autonomy_runtime/live_autonomy_digest_header.mbt", "planbook_open_gaps",
    ) &&
    text_file_contains(
      "src/live_autonomy_runtime/live_autonomy_render.mbt", "PlanBook open gaps",
    ) &&
    text_file_contains(
      "src/live_autonomy_runtime/live_autonomy_planbook_sync.mbt", "planbook_open_count",
    )
  planbook_criterion(
    "planbook-live-spine",
    "2026-05-29-live-autonomy-spine",
    "Live autonomy spine exposes PlanBook self-build gaps",
    "moontown",
    ready,
    if ready {
      "live autonomy type, digest, render, and PlanBook sync paths carry PlanBook open-gap count"
    } else {
      "live autonomy split modules do not yet expose PlanBook gaps end-to-end"
    },
    "add PlanBook gap fields to the live spine and digest",
  )
}

///|
async fn planbook_ui_operator_criterion() -> PlanbookCriterionStatus {
  let ready = text_file_contains(
      "src/ui/rabbita-town/runtime_snapshot_manifest.js", "live-autonomy.json",
    ) &&
    text_file_contains(
      "src/ui/rabbita-town/main/bootstrap_live_autonomy.mbt", "planbook_open_count",
    ) &&
    text_file_contains(
      "src/ui/rabbita-town/main/viewport_live_autonomy_status.mbt", "planbook_open_count",
    ) &&
    text_file_contains(
      "src/ui/rabbita-town/main/viewport_operator_metrics.mbt", "live_autonomy_operator_view",
    )
  planbook_criterion(
    "ui-live-spine-operator-panel",
    "2026-05-29-live-autonomy-spine",
    "Operator UI consumes the live spine instead of static demo state",
    "moontown-ui",
    ready,
    if ready {
      "UI runtime references live-autonomy state"
    } else {
      "UI does not yet reference live-autonomy state"
    },
    "bind the operator message panel to `.moontown/live-autonomy.json`",
  )
}

///|
async fn planbook_result_contract_criterion() -> PlanbookCriterionStatus {
  let standing_ready = text_file_contains(
      "src/standing_watch_policy/task.mbt", "standing_goal_decision",
    ) &&
    text_file_contains(
      "src/standing_watch_policy/task.mbt", "accepted_facts_count",
    ) &&
    text_file_contains("src/standing_watch_policy/task.mbt", "book_changed") &&
    text_file_contains(
      "src/standing_watch_policy/history_rendering.mbt", "accepted_facts_count",
    ) &&
    text_file_contains("src/standing_watch_policy/markers.mbt", "needs_review")
  let generic_ready = text_file_contains(
      "src/adapters/moonclaw/packet_types.mbt", "result_decision",
    ) &&
    text_file_contains(
      "src/adapters/moonclaw/run_polling.mbt", "result_decision",
    ) &&
    text_file_contains("src/town_runtime/goal_execution.mbt", "result_decision") &&
    text_file_contains("src/core/execution_types.mbt", "result_decision")
  planbook_criterion(
    "strict-moonclaw-result-contract",
    "2026-05-29-live-autonomy-spine",
    "Every MoonClaw result is classified before projection",
    "moontown+moonclaw",
    standing_ready && generic_ready,
    if standing_ready && generic_ready {
      "standing watch and generic execution paths expose strict result classification"
    } else if standing_ready {
      "standing watch path has a strict contract; generic execution path still needs the same contract"
    } else {
      "MoonClaw result classification remains incomplete"
    },
    "extend generic MoonClaw execution reconciliation to accepted/no-change/review/blocked",
  )
}

///|
async fn planbook_source_patch_loop_criterion(
  workspace_root : String,
) -> PlanbookCriterionStatus {
  let repair_workspace_file = "src/planbook_runtime/planbook_repair_workspace.mbt"
  let profile_file = "src/planbook_runtime/planbook_repair_profile.mbt"
  let acp_file = "src/planbook_runtime/planbook_repair_acp.mbt"
  let codex_target_file = "src/adapters/codex/targets.mbt"
  let codex_defaults_file = "src/adapters/codex/defaults.mbt"
  let acp_ready = text_file_contains(
      repair_workspace_file, "write_planbook_repair_acp_target",
    ) &&
    text_file_contains(profile_file, "execution_mode=\"acp\"") &&
    text_file_contains(profile_file, "@codex.codex_main_target_id()") &&
    text_file_contains(profile_file, "tool_access=\"codex-acp-repo-patch\"") &&
    text_file_contains(acp_file, "@codex.upsert_codex_main_target_json") &&
    text_file_contains(acp_file, "source_root") &&
    text_file_contains(codex_target_file, "codex_main_target_json") &&
    text_file_contains(codex_target_file, "\"codex-main\"") &&
    text_file_contains(codex_defaults_file, "\"--model\"")
  let skill_ready = text_file_contains(
    "src/planbook_policy/request_rules.mbt", "Codex ACP source-patching target",
  )
  let receipt_ready = planbook_latest_repair_patch_receipt_ready(workspace_root)
  planbook_criterion(
    "planbook-source-patch-loop",
    "2026-05-31-editor-mode-real-pipeline",
    "PlanBook repair can patch repository source through Codex ACP",
    "moontown+moonclaw+codex-acp",
    acp_ready && skill_ready && receipt_ready,
    if acp_ready && skill_ready && receipt_ready {
      "PlanBook repair has accepted `\{@planbook_policy.repair_patch_receipt_contract()}` evidence from a Codex ACP source-root patch run"
    } else if acp_ready && skill_ready {
      "PlanBook repair ACP wiring exists, but no accepted `\{@planbook_policy.repair_patch_receipt_contract()}` source patch receipt has been consumed yet"
    } else {
      "PlanBook repair still cannot prove a source-patching ACP route; it may only plan or validate without editing repository code"
    },
    "route PlanBook repair packets through Codex ACP with source-root cwd/workspace, then require repair-result evidence after validation",
  )
}

///|
async fn planbook_engineering_loop_criterion(
  workspace_root : String,
) -> PlanbookCriterionStatus {
  let metadata_file = "src/planbook_runtime/planbook_repair_packet_metadata.mbt"
  let policy_file = "src/planbook_runtime/planbook_repair_policy.mbt"
  let policy_package_file = "src/planbook_policy/repair_commands.mbt"
  let skill_file = "src/planbook_policy/skill_text.mbt"
  let metadata_ready = text_file_contains(
      metadata_file, "required_engineering_steps",
    ) &&
    text_file_contains(metadata_file, "git_policy") &&
    text_file_contains(metadata_file, "commit_after_validation") &&
    text_file_contains(metadata_file, "push_after_commit")
  let skill_ready = text_file_contains(skill_file, "diff_summary") &&
    text_file_contains(skill_file, "commit_status") &&
    text_file_contains(skill_file, "git diff --check") &&
    text_file_contains(skill_file, "git status --short")
  let validation_ready = text_file_contains(
      policy_file, "planbook_repair_required_commands",
    ) &&
    text_file_contains(policy_package_file, "moon test --no-render") &&
    text_file_contains(policy_package_file, "moon info")
  let receipt_ready = planbook_latest_repair_patch_receipt_ready(workspace_root)
  planbook_criterion(
    "planbook-software-engineering-loop",
    "2026-05-31-editor-mode-real-pipeline",
    "PlanBook repair uses a full software-engineering loop, not patch-only execution",
    "moontown+moonclaw+codex-acp",
    metadata_ready && skill_ready && validation_ready && receipt_ready,
    if metadata_ready && skill_ready && validation_ready && receipt_ready {
      "Accepted PlanBook repair receipt proves validation commands, git diff hygiene, local commit evidence, and no push by policy"
    } else if metadata_ready && skill_ready && validation_ready {
      "PlanBook repair packets request validation, diff hygiene, and commit evidence, but PlanBook has not consumed accepted ACP patch evidence yet"
    } else {
      "PlanBook repair can patch source but does not yet prove testing, diff hygiene, and commit discipline"
    },
    "extend PlanBook repair packets and skills with required validation, diff inspection, commit policy, and durable engineering evidence",
  )
}

///|
async fn planbook_implementation_backlog_criterion(
  workspace_root : String,
) -> PlanbookCriterionStatus {
  match first_open_planbook_backlog_item(workspace_root) {
    Some(item) => planbook_backlog_criterion_for_item(item, workspace_root)
    None =>
      planbook_criterion(
        "planbook-implementation-backlog", "docs/PLANBOOK.md", "PlanBook implementation backlog is clear",
        "moontown+planbook", true, "No open implementation backlog item is waiting for self-build dispatch",
        "add future implementation work to `raw/backlog/implementation-backlog.json` instead of hardcoding feature selection in MoonBit",
      )
  }
}
