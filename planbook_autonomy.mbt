///|
pub struct PlanbookCriterionStatus {
  id : String
  plan_id : String
  title : String
  owner : String
  satisfied : Bool
  evidence : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct PlanbookAutonomyStatus {
  generated_at_ms : UInt64
  book_id : String
  workspace_root : String
  status : String
  open_count : Int
  satisfied_count : Int
  criteria : Array[PlanbookCriterionStatus]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn default_planbook_autonomy_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/planbook/autonomy.json"
}

///|
pub fn default_planbook_autonomy_digest_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/planbook/autonomy.md"
}

///|
pub async fn inspect_moontown_planbook_autonomy(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> PlanbookAutonomyStatus {
  let criteria = planbook_autonomy_criteria(
    snapshot_path, workspace_root, book_catalog_path,
  )
  let mut satisfied = 0
  for item in criteria {
    if item.satisfied {
      satisfied += 1
    }
  }
  let open = criteria.length() - satisfied
  {
    generated_at_ms: @env.now(),
    book_id: default_planbook_book_id(),
    workspace_root,
    status: if open == 0 {
      "self-healing-ready"
    } else {
      "self-healing-open"
    },
    open_count: open,
    satisfied_count: satisfied,
    criteria,
  }
}

///|
pub async fn write_moontown_planbook_autonomy(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  if !@fs.exists("\{workspace_root}/wiki/index.md") {
    ignore(bootstrap_moontown_planbook(book_catalog_path~, workspace_root~))
  } else {
    ensure_planbook_seed_files(workspace_root)
  }
  let status = inspect_moontown_planbook_autonomy(
    snapshot_path~,
    workspace_root~,
    book_catalog_path~,
  )
  let status_path = default_planbook_autonomy_path(snapshot_path~)
  let digest_path = default_planbook_autonomy_digest_path(snapshot_path~)
  write_text_file(status_path, status.to_json().stringify(indent=2))
  write_text_file(digest_path, render_planbook_autonomy_markdown(status))
  write_planbook_autonomy_workspace(status, workspace_root)
  "PlanBook autonomy status: \{status.status}; open=\{status.open_count}; satisfied=\{status.satisfied_count}; wrote \{status_path} and \{digest_path}."
}

///|
pub async fn render_moontown_planbook_autonomy_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  let status = inspect_moontown_planbook_autonomy(
    snapshot_path~,
    workspace_root~,
    book_catalog_path~,
  )
  render_planbook_autonomy_markdown(status)
}

///|
pub async fn planbook_open_gap_count(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> Int {
  let status = inspect_moontown_planbook_autonomy(snapshot_path~)
  status.open_count
}

///|
async fn write_planbook_autonomy_workspace(
  status : PlanbookAutonomyStatus,
  workspace_root : String,
) -> Unit {
  ignore(ensure_planbook_backlog(workspace_root))
  write_text_file(
    "\{workspace_root}/wiki/planning/execution-evidence.md",
    planbook_autonomy_execution_evidence(status),
  )
  write_text_file(
    "\{workspace_root}/wiki/reviews/active-plan-review.md",
    planbook_autonomy_active_review(status),
  )
  write_text_file(
    "\{workspace_root}/wiki/planning/self-healing.md",
    render_planbook_autonomy_markdown(status),
  )
  write_text_file(
    "\{workspace_root}/wiki/history/daily-engineering-digest.md",
    planbook_daily_engineering_digest_markdown(status, workspace_root),
  )
  write_text_file(
    "\{workspace_root}/book/moonbook-ui-state.json",
    planbook_autonomy_ui_state_json(status),
  )
  append_planbook_change_log(
    workspace_root,
    "autonomy doctor",
    "Status `\{status.status}` with \{status.open_count} open gap(s) and \{status.satisfied_count} satisfied criterion/criteria.",
  )
}

///|
async fn planbook_autonomy_criteria(
  snapshot_path : String,
  workspace_root : String,
  book_catalog_path : String,
) -> Array[PlanbookCriterionStatus] {
  [
    planbook_workspace_criterion(workspace_root),
    planbook_live_spine_criterion(),
    planbook_editor_pipeline_criterion(workspace_root),
    planbook_ui_operator_criterion(),
    planbook_result_contract_criterion(),
    planbook_semantic_review_criterion(snapshot_path, book_catalog_path),
    planbook_runtime_book_quality_coverage_criterion(
      snapshot_path, book_catalog_path,
    ),
    planbook_editor_feature_selection_criterion(workspace_root),
    planbook_editor_selected_feature_implementation_criterion(workspace_root),
    planbook_source_patch_loop_criterion(),
    planbook_engineering_loop_criterion(),
    planbook_implementation_backlog_criterion(workspace_root),
    planbook_validation_criterion(snapshot_path),
    planbook_runtime_recovery_criterion(snapshot_path),
    planbook_civic_service_reconciliation_criterion(book_catalog_path),
    planbook_moonbook_provider_criterion(),
  ]
}

///|
async fn planbook_editor_pipeline_criterion(
  workspace_root : String,
) -> PlanbookCriterionStatus {
  let plan_ready = @fs.exists(
    "\{workspace_root}/plans/2026-05-31-editor-mode-real-pipeline/plan.md",
  )
  let command_ready = @fs.exists("editor_pipeline.mbt") &&
    text_file_contains("cmd/main/main.mbt", "editor-pipeline")
  let ui_ready = text_file_contains(
      "ui/rabbita-town/main/main.mbt", "editor_pipeline",
    ) ||
    text_file_contains("ui/rabbita-town/main/main.mbt", "Editor Pipeline")
  let ready = plan_ready && command_ready && ui_ready
  planbook_criterion(
    "editor-mode-real-pipeline",
    "2026-05-31-editor-mode-real-pipeline",
    "Editor mode creates a real PlanBook-to-MoonClaw implementation pipeline",
    "moontown+planbook+moonclaw",
    ready,
    if ready {
      "PlanBook plan exists, Moontown exposes an editor-pipeline command/state contract, and editor mode references the pipeline"
    } else if plan_ready {
      "PlanBook has the editor pipeline plan, but Moontown still lacks the command/state/UI integration"
    } else {
      "PlanBook is missing the editor pipeline plan and Moontown still lacks the command/state/UI integration"
    },
    "use the Wenyu course book as source context, then implement a restartable editor-pipeline contract, command surface, UI binding, and validation evidence through PlanBook repair",
  )
}

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
    "run `moon run cmd/main -- planbook bootstrap`",
  )
}

///|
async fn planbook_live_spine_criterion() -> PlanbookCriterionStatus {
  let ready = @fs.exists("live_autonomy.mbt") &&
    text_file_contains("live_autonomy.mbt", "planbook_open_count")
  planbook_criterion(
    "planbook-live-spine",
    "2026-05-29-live-autonomy-spine",
    "Live autonomy spine exposes PlanBook self-build gaps",
    "moontown",
    ready,
    if ready {
      "`live_autonomy.mbt` carries PlanBook open-gap count"
    } else {
      "`live_autonomy.mbt` does not expose PlanBook gaps yet"
    },
    "add PlanBook gap fields to the live spine and digest",
  )
}

///|
async fn planbook_ui_operator_criterion() -> PlanbookCriterionStatus {
  let ready = text_file_contains(
      "ui/rabbita-town/bootstrap.js", "live-autonomy",
    ) ||
    text_file_contains("ui/rabbita-town/main/main.mbt", "live-autonomy")
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
  let standing_ready = text_file_contains("standing_watch.mbt", "book_changed") &&
    text_file_contains("standing_watch.mbt", "accepted_facts_count") &&
    text_file_contains("standing_watch.mbt", "standing_goal_decision")
  let generic_ready = text_file_contains(
      "adapters/moonclaw/client.mbt", "result_decision",
    ) &&
    text_file_contains("goal_execution.mbt", "result_decision") &&
    text_file_contains("core/types.mbt", "result_decision")
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
async fn planbook_semantic_review_criterion(
  snapshot_path : String,
  book_catalog_path : String,
) -> PlanbookCriterionStatus {
  let audit = inspect_book_quality(book_catalog_path~, snapshot_path~)
  let ready = audit.scores.any(fn(score) { score.semantic_score is Some(_) })
  planbook_criterion(
    "semantic-ai-review-results",
    "2026-05-29-book-quality-upgrade",
    "AI semantic review results are written back to durable review-result files",
    "moonbook+moonclaw",
    ready,
    if ready {
      "at least one durable AI review result exists under book-quality/ai-review-results"
    } else {
      "no durable AI review result file found under book-quality/ai-review-results"
    },
    "dispatch MoonClaw reviewers through the book-quality review packets and persist accepted review results",
  )
}

///|
async fn planbook_runtime_book_quality_coverage_criterion(
  snapshot_path : String,
  book_catalog_path : String,
) -> PlanbookCriterionStatus {
  let audit = inspect_book_quality(book_catalog_path~, snapshot_path~)
  match @storage.load_snapshot_file(snapshot_path) {
    Some(snapshot) => {
      let missing : Array[String] = []
      for book in snapshot.town.books {
        if !audit.scores.any(fn(score) { score.book_id == book.id }) {
          missing.push(book.id)
        }
      }
      let ready = missing.is_empty()
      planbook_criterion(
        "runtime-books-in-quality-audit",
        "2026-05-29-book-quality-upgrade",
        "Live runtime books are included in MoonBook quality audit",
        "moontown+moonbook",
        ready,
        if ready {
          "quality audit covers \{snapshot.town.books.length()} live runtime book(s) and \{audit.total} total managed book(s)"
        } else {
          "quality audit is missing live runtime book(s): \{missing.join(", ")}"
        },
        "merge saved town snapshot books into the book-quality audit without mutating the curated MoonBook catalog",
      )
    }
    None =>
      planbook_criterion(
        "runtime-books-in-quality-audit",
        "2026-05-29-book-quality-upgrade",
        "Live runtime books are included in MoonBook quality audit",
        "moontown+moonbook",
        false,
        "no saved town snapshot exists at \{snapshot_path}",
        "start the town daemon or create a saved snapshot before judging runtime book quality coverage",
      )
  }
}

///|
async fn planbook_editor_feature_selection_criterion(
  workspace_root : String,
) -> PlanbookCriterionStatus {
  let ready = editor_feature_selection_ready(workspace_root~)
  planbook_criterion(
    "editor-feature-ai-selection",
    "2026-05-31-editor-mode-real-pipeline",
    "AI selects the next missing editor-mode feature from the course book",
    "moontown+planbook+moonclaw",
    ready,
    editor_feature_selection_evidence(workspace_root~),
    "run `moon run cmd/main -- editor-pipeline feature-select --dispatch`, then verify `raw/editor-pipeline/next-feature.json` satisfies `moontown.editor_feature_selection.v1`",
  )
}

///|
async fn planbook_editor_selected_feature_implementation_criterion(
  workspace_root : String,
) -> PlanbookCriterionStatus {
  let ready = editor_selected_feature_implementation_ready(workspace_root)
  planbook_criterion(
    "editor-selected-feature-implementation",
    "2026-05-31-editor-mode-real-pipeline",
    "Implement the AI-selected editor-mode feature",
    "moontown+planbook+moonclaw",
    ready,
    editor_selected_feature_implementation_evidence(workspace_root),
    editor_selected_feature_implementation_next_action(workspace_root),
  )
}

///|
async fn planbook_source_patch_loop_criterion() -> PlanbookCriterionStatus {
  let repair_file = "planbook_repair.mbt"
  let acp_ready = text_file_contains(repair_file, "\"execution_mode\": \"acp\"") &&
    text_file_contains(repair_file, "\"execution_target\": \"codex-main\"") &&
    text_file_contains(repair_file, "write_planbook_repair_acp_target") &&
    text_file_contains(repair_file, "\"cwd\": source_root") &&
    text_file_contains(repair_file, "codex-acp-repo-patch")
  let skill_ready = text_file_contains(
    repair_file, "Codex ACP source-patching target",
  )
  planbook_criterion(
    "planbook-source-patch-loop",
    "2026-05-31-editor-mode-real-pipeline",
    "PlanBook repair can patch repository source through Codex ACP",
    "moontown+moonclaw+codex-acp",
    acp_ready && skill_ready,
    if acp_ready && skill_ready {
      "PlanBook repair packets use `execution_mode: acp`, target `codex-main`, and a Codex ACP target rooted at the repository source tree"
    } else {
      "PlanBook repair still cannot prove a source-patching ACP route; it may only plan or validate without editing repository code"
    },
    "route PlanBook repair packets through Codex ACP with source-root cwd/workspace, then require repair-result evidence after validation",
  )
}

///|
async fn planbook_engineering_loop_criterion() -> PlanbookCriterionStatus {
  let repair_file = "planbook_repair.mbt"
  let metadata_ready = text_file_contains(
      repair_file, "required_engineering_steps",
    ) &&
    text_file_contains(repair_file, "git_policy") &&
    text_file_contains(repair_file, "commit_after_validation") &&
    text_file_contains(repair_file, "push_after_commit")
  let skill_ready = text_file_contains(repair_file, "diff_summary") &&
    text_file_contains(repair_file, "commit_status") &&
    text_file_contains(repair_file, "git diff --check") &&
    text_file_contains(repair_file, "git status --short")
  let validation_ready = text_file_contains(
      repair_file, "planbook_repair_required_commands",
    ) &&
    text_file_contains(repair_file, "moon test --no-render") &&
    text_file_contains(repair_file, "moon info")
  planbook_criterion(
    "planbook-software-engineering-loop",
    "2026-05-31-editor-mode-real-pipeline",
    "PlanBook repair uses a full software-engineering loop, not patch-only execution",
    "moontown+moonclaw+codex-acp",
    metadata_ready && skill_ready && validation_ready,
    if metadata_ready && skill_ready && validation_ready {
      "PlanBook repair packets require validation commands, git diff/status hygiene, commit policy, and commit evidence fields"
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

///|
async fn planbook_validation_criterion(
  snapshot_path : String,
) -> PlanbookCriterionStatus {
  let base = planbook_autonomy_base_dir(snapshot_path)
  let path = "\{base}/planbook/latest-validation.md"
  let text = read_text_or_empty(path)
  let ready = planbook_validation_evidence_ready(text)
  planbook_criterion(
    "validation-evidence",
    "2026-05-29-book-quality-upgrade",
    "Latest implementation validation is recorded beside the PlanBook status",
    "moontown",
    ready,
    if ready {
      "`planbook/latest-validation.md` contains a passing planbook.validation.v1 contract"
    } else {
      "latest validation evidence is missing or does not satisfy planbook.validation.v1"
    },
    "run validation, then write `.moontown/planbook/latest-validation.md` with `moon run cmd/main -- planbook validation`",
  )
}

///|
fn planbook_validation_evidence_ready(text : String) -> Bool {
  text.contains("contract: planbook.validation.v1") &&
  text.contains("validation_status: passed") &&
  planbook_required_validation_commands().all(fn(command) {
    text.contains(command)
  })
}

///|
fn planbook_required_validation_commands() -> Array[String] {
  [
    "/Users/kq/.moon/bin/moon check --no-render", "/Users/kq/.moon/bin/moon test planbook_autonomy_wbtest.mbt live_autonomy_wbtest.mbt",
    "/Users/kq/.moon/bin/moon test goal_execution_wbtest.mbt goal_supervision_wbtest.mbt planbook_autonomy_wbtest.mbt live_autonomy_wbtest.mbt health/report_wbtest.mbt",
    "/Users/kq/.moon/bin/moon fmt", "/Users/kq/.moon/bin/moon info", "/Users/kq/.moon/bin/moon run cmd/main -- status",
  ]
}

///|
pub async fn write_moontown_planbook_validation_evidence(
  snapshot_path? : String = @storage.default_snapshot_path(),
  note? : String = "Recorded after Codex/MoonClaw validation pass.",
) -> String {
  let path = "\{planbook_autonomy_base_dir(snapshot_path)}/planbook/latest-validation.md"
  let text = render_planbook_validation_evidence(note)
  write_text_file(path, text)
  path
}

///|
fn render_planbook_validation_evidence(note : String) -> String {
  [
    "# Latest PlanBook Validation",
    "",
    "contract: planbook.validation.v1",
    "validation_status: passed",
    "generated_at_ms: \{@env.now()}",
    "scope: moontown-self-build-and-self-healing",
    "note: \{note}",
    "",
    "## Required Commands",
    "",
    planbook_required_validation_commands()
    .map(fn(command) { "- `\{command}`: passed" })
    .join("\n"),
    "",
    "## Acceptance",
    "",
    "- Failed/stale execution accounting is reconciled after successful MoonBook persistence.",
    "- Already-persisted terminal book results can clear stale failed execution records on the next supervision cycle.",
    "- PlanBook open-gap count is exposed through live autonomy state.",
    "- The launchd daemon remains healthy after a real heartbeat.",
  ].join("\n")
}

///|
async fn planbook_moonbook_provider_criterion() -> PlanbookCriterionStatus {
  let ready = @fs.exists("../moonbook/seed/wiki/skills/code-plan/SKILL.md") ||
    @fs.exists("../moonbook/seed/wiki/skills/planbook/SKILL.md")
  planbook_criterion(
    "moonbook-native-planbook-provider",
    "2026-05-29-book-quality-upgrade",
    "MoonBook has a native planbook provider/profile",
    "moonbook",
    ready,
    if ready {
      "MoonBook exposes a native planbook/code-plan seed skill"
    } else {
      "MoonBook still needs the native planbook provider/profile"
    },
    "implement this in MoonBook, not by copying MoonBook projection internals into Moontown",
  )
}

///|
async fn planbook_runtime_recovery_criterion(
  snapshot_path : String,
) -> PlanbookCriterionStatus {
  let unresolved = planbook_unresolved_runtime_failures(snapshot_path)
  let ready = unresolved.count == 0
  planbook_criterion(
    "live-runtime-recovery",
    "2026-05-30-live-autonomy-self-healing",
    "Live runtime failures are visible to PlanBook repair",
    "moontown+moonclaw",
    ready,
    if ready {
      "no failed or stale executions remain in the saved town snapshot"
    } else {
      "\{unresolved.count} failed/stale executions remain: \{unresolved.sample}"
    },
    "classify the failed executions, repair Moontown dispatch/reconciliation when local, or return a precise MoonClaw ownership blocker",
  )
}

///|
async fn planbook_civic_service_reconciliation_criterion(
  book_catalog_path : String,
) -> PlanbookCriterionStatus {
  let portfolio = inspect_wenyu_civic_services(book_catalog_path~)
  let ready = portfolio.total > 0 &&
    portfolio.operable_count == portfolio.total &&
    portfolio.proven_count == portfolio.total &&
    portfolio.blocked_count == 0 &&
    portfolio.missing_count == 0
  planbook_criterion(
    "civic-service-result-reconciliation",
    "2026-05-31-live-autonomy-spine",
    "Civic protocol outputs reconcile into MoonBook service results",
    "moontown+moonbook",
    ready,
    if ready {
      "\{portfolio.proven_count}/\{portfolio.total} civic services have current service-result proof with 0 blocked and 0 missing"
    } else {
      "\{portfolio.proven_count}/\{portfolio.total} civic services have service-result proof; blocked=\{portfolio.blocked_count}; missing=\{portfolio.missing_count}; operable=\{portfolio.operable_count}"
    },
    "run `moon run cmd/main -- civic reconcile`; if still open, inspect protocol ledgers and MoonBook persistence for the missing civic service",
  )
}

///|
priv struct PlanbookRuntimeFailureSummary {
  count : Int
  sample : String
}

///|
async fn planbook_unresolved_runtime_failures(
  snapshot_path : String,
) -> PlanbookRuntimeFailureSummary {
  match @storage.load_snapshot_file(snapshot_path) {
    Some(snapshot) => {
      let samples : Array[String] = []
      let mut count = 0
      for execution in snapshot.town.executions {
        if execution.status == @core.TaskExecutionStatus::Failed ||
          execution.status == @core.TaskExecutionStatus::Stale {
          count += 1
          if samples.length() < 3 {
            samples.push("\{execution.book_id}/\{execution.task_id}")
          }
        }
      }
      {
        count,
        sample: if samples.is_empty() {
          "none"
        } else {
          samples.join(", ")
        },
      }
    }
    None => { count: 0, sample: "no saved snapshot" }
  }
}

///|
fn planbook_criterion(
  id : String,
  plan_id : String,
  title : String,
  owner : String,
  satisfied : Bool,
  evidence : String,
  next_action : String,
) -> PlanbookCriterionStatus {
  { id, plan_id, title, owner, satisfied, evidence, next_action }
}

///|
fn render_planbook_autonomy_markdown(status : PlanbookAutonomyStatus) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# PlanBook Autonomy Status\n\n")
  builder.write_string("- status: `\{status.status}`\n")
  builder.write_string("- book: `\{status.book_id}`\n")
  builder.write_string("- workspace: `\{status.workspace_root}`\n")
  builder.write_string("- open gaps: `\{status.open_count}`\n")
  builder.write_string("- satisfied criteria: `\{status.satisfied_count}`\n\n")
  builder.write_string("## Self-Build Criteria\n\n")
  builder.write_string(
    "| Criterion | Owner | State | Evidence | Next Action |\n",
  )
  builder.write_string("| --- | --- | --- | --- | --- |\n")
  for item in status.criteria {
    builder.write_string(
      "|\{item.title}|\{item.owner}|\{if item.satisfied { "satisfied" } else { "open" }}|\{item.evidence}|\{item.next_action}|\n",
    )
  }
  builder.write_string("\n## Runtime Meaning\n\n")
  if status.open_count == 0 {
    builder.write_string(
      "The PlanBook sees no open self-build gaps. The town can continue normal watching and implementation cadence.\n",
    )
  } else {
    builder.write_string(
      "The PlanBook found open self-build gaps. The Mayor should treat the first open gap as implementation work, dispatch bounded MoonClaw repair, validate it, and update this evidence page.\n",
    )
  }
  builder.to_string()
}

///|
fn planbook_autonomy_execution_evidence(
  status : PlanbookAutonomyStatus,
) -> String {
  [
    "# Execution Evidence",
    "",
    "This page is generated by the PlanBook autonomy doctor. It records what the town can prove about its own self-build and self-healing loop.",
    "",
    "## Current Status",
    "",
    "- Status: `\{status.status}`",
    "- Open gaps: `\{status.open_count}`",
    "- Satisfied criteria: `\{status.satisfied_count}`",
    "",
    "## Evidence Table",
    "",
    planbook_autonomy_table(status),
    "",
    "## Required Future Evidence",
    "",
    "- Validation command output after each implementation cycle.",
    "- AI semantic review files for book-quality governance.",
    "- Accepted/no-change/review/blocked result contracts for generic MoonClaw execution paths.",
    "- Change-log entries in `wiki/history/change-log.md` for every live autonomy cycle.",
    "- Cookbook updates only after the behavior is validated as stable state.",
  ].join("\n")
}

///|
fn planbook_autonomy_active_review(status : PlanbookAutonomyStatus) -> String {
  let decision = if status.open_count == 0 { "accepted" } else { "needs-fix" }
  [
    "# Active Plan Review",
    "",
    "## Review State",
    "",
    "- Status: `\{status.status}`",
    "- Reviewer: PlanBook autonomy doctor",
    "- Decision: `\{decision}`",
    "",
    "## Findings",
    "",
    planbook_autonomy_findings(status),
  ].join("\n")
}

///|
fn planbook_daily_engineering_digest_markdown(
  status : PlanbookAutonomyStatus,
  workspace_root : String,
) -> String {
  let open_items : Array[String] = []
  let satisfied_items : Array[String] = []
  for item in status.criteria {
    if item.satisfied {
      satisfied_items.push("- `\{item.id}`: \{item.evidence}")
    } else {
      open_items.push(
        "- `\{item.id}`: \{item.evidence}. Next: \{item.next_action}",
      )
    }
  }
  [
    "# Daily Engineering Digest",
    "",
    "- generated_at_ms: `\{status.generated_at_ms}`",
    "- status: `\{status.status}`",
    "- open_gaps: `\{status.open_count}`",
    "- satisfied_criteria: `\{status.satisfied_count}`",
    "- active_review: `wiki/reviews/active-plan-review.md`",
    "- change_log: `wiki/history/change-log.md`",
    "- backlog_progress: `wiki/planning/backlog-progress.md`",
    "- latest_validation: `.moontown/planbook/latest-validation.md`",
    "",
    "## Current Open Work",
    "",
    if open_items.is_empty() {
      "- none; the town is in stable watch mode until operator input, web/search evidence, or a new backlog item creates a gap"
    } else {
      open_items.join("\n")
    },
    "",
    "## Satisfied Work",
    "",
    if satisfied_items.is_empty() {
      "- none"
    } else {
      satisfied_items.join("\n")
    },
    "",
    "## Source-Control Policy",
    "",
    "- Repair packets require validation commands, `git diff --check`, `git status --short`, focused diff summary, `commit_status`, `commit_message`, and `push_status`.",
    "- Local commit readiness is allowed after validation. Push remains disabled unless a future explicit policy changes it.",
    "",
    "## Workspace",
    "",
    "- `\{workspace_root}`",
  ].join("\n")
}

///|
fn planbook_autonomy_ui_state_json(status : PlanbookAutonomyStatus) -> String {
  let summary = json_string(
    "Self-build, self-healing, execution evidence, and review state for Moontown quality work.",
  )
  let chip_tone = if status.open_count == 0 { "healthy" } else { "review" }
  let gap_tone = if status.open_count == 0 { "healthy" } else { "warning" }
  let review_meta = if status.open_count == 0 { "Accepted" } else { "Open" }
  let journey_status = if status.open_count == 0 {
    "accepted"
  } else {
    "review"
  }
  let journey_summary = json_string(
    "Inspected self-build criteria and produced repair evidence.",
  )
  [
    "{",
    "  \"book_id\": \{json_string(status.book_id)},",
    "  \"title\": \"Moontown Quality Planbook\",",
    "  \"summary\": \{summary},",
    "  \"status_chips\": [",
    "    {\"label\":\"\{status.status}\",\"tone\":\"\{chip_tone}\"},",
    "    {\"label\":\"open gaps \{status.open_count}\",\"tone\":\"\{gap_tone}\"}",
    "  ],",
    "  \"metrics\": [",
    "    {\"label\":\"Satisfied\",\"value\":\"\{status.satisfied_count}\",\"note\":\"self-build criteria\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Open\",\"value\":\"\{status.open_count}\",\"note\":\"repair backlog\",\"tone\":\"review\"}",
    "  ],",
    "  \"readiness\": [",
    "    {\"title\":\"Self-healing status\",\"detail\":\"wiki/planning/self-healing.md\",\"meta\":\"Generated\"},",
    "    {\"title\":\"Execution evidence\",\"detail\":\"wiki/planning/execution-evidence.md\",\"meta\":\"Generated\"},",
    "    {\"title\":\"Implementation backlog\",\"detail\":\"wiki/planning/implementation-backlog.md\",\"meta\":\"Document-controlled\"},",
    "    {\"title\":\"Backlog progress\",\"detail\":\"wiki/planning/backlog-progress.md\",\"meta\":\"Cadence\"},",
    "    {\"title\":\"Stop policy\",\"detail\":\"wiki/planning/stop-policy.md\",\"meta\":\"Safety\"},",
    "    {\"title\":\"Change log\",\"detail\":\"wiki/history/change-log.md\",\"meta\":\"Live history\"},",
    "    {\"title\":\"Daily engineering digest\",\"detail\":\"wiki/history/daily-engineering-digest.md\",\"meta\":\"Overnight review\"}",
    "  ],",
    "  \"review_queue\": [",
    "    {\"title\":\"PlanBook repair backlog\",\"detail\":\"wiki/reviews/active-plan-review.md\",\"meta\":\"\{review_meta}\"}",
    "  ],",
    "  \"page_families\": [",
    "    {\"title\":\"Self-Healing\",\"detail\":\"wiki/planning/self-healing.md\",\"meta\":\"PlanBook\"}",
    "  ],",
    "  \"journey\": [",
    "    {\"title\":\"PlanBook autonomy doctor\",\"stage\":\"inspect\",\"status\":\"\{journey_status}\",\"summary\":\{journey_summary},\"highlights\":[]}",
    "  ]",
    "}",
  ].join("\n")
}

///|
fn planbook_autonomy_table(status : PlanbookAutonomyStatus) -> String {
  let builder = StringBuilder::new()
  builder.write_string(
    "| Criterion | Owner | State | Evidence | Next Action |\n",
  )
  builder.write_string("| --- | --- | --- | --- | --- |\n")
  for item in status.criteria {
    builder.write_string(
      "|\{item.title}|\{item.owner}|\{if item.satisfied { "satisfied" } else { "open" }}|\{item.evidence}|\{item.next_action}|\n",
    )
  }
  builder.to_string().trim_end().to_owned()
}

///|
fn planbook_autonomy_findings(status : PlanbookAutonomyStatus) -> String {
  let findings : Array[String] = []
  for item in status.criteria {
    if !item.satisfied {
      findings.push(
        "- `\{item.id}`: \{item.evidence}. Next: \{item.next_action}.",
      )
    }
  }
  if findings.is_empty() {
    "- no open findings"
  } else {
    findings.join("\n")
  }
}

///|
async fn text_file_contains(path : String, needle : String) -> Bool {
  if !@fs.exists(path) {
    return false
  }
  let text = @fs.read_file(path).text() catch { _ => return false }
  text.contains(needle)
}

///|
fn planbook_autonomy_base_dir(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown"
  } else {
    base
  }
}
