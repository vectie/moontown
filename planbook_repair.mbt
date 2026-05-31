///|
pub struct PlanbookRepairTask {
  id : String
  criterion_id : String
  title : String
  status : String
  owner : String
  workspace_root : String
  packet_path : String
  proposal_id : String?
  run_id : String?
  summary : String
  validation_command : String
  generated_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn default_planbook_repair_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/planbook/repair-task.json"
}

///|
pub fn default_planbook_repair_markdown_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/planbook/repair-task.md"
}

///|
pub async fn write_moontown_planbook_repair_task(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  dispatch? : Bool = false,
) -> String {
  let status = inspect_moontown_planbook_autonomy(
    snapshot_path~,
    workspace_root~,
    book_catalog_path~,
  )
  match first_planbook_open_criterion(status) {
    Some(criterion) => {
      let task = match
        existing_planbook_repair_handoff(
          criterion, snapshot_path, workspace_root,
        ) {
        Some(task) => task
        None =>
          match existing_planbook_repair_in_flight(criterion, snapshot_path) {
            Some(task) => task
            None =>
              materialize_planbook_repair_task(
                criterion, snapshot_path, workspace_root, book_catalog_path, dispatch,
              )
          }
      }
      write_planbook_repair_status(task, workspace_root, snapshot_path)
      "PlanBook repair task `\{task.id}` is \{task.status}: \{task.summary}"
    }
    None => {
      let task = planbook_noop_repair_task(snapshot_path, workspace_root)
      write_planbook_repair_status(task, workspace_root, snapshot_path)
      "PlanBook has no open repair task."
    }
  }
}

///|
async fn existing_planbook_repair_in_flight(
  criterion : PlanbookCriterionStatus,
  snapshot_path : String,
) -> PlanbookRepairTask? {
  let path = default_planbook_repair_path(snapshot_path~)
  if !@fs.exists(path) {
    return None
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ => return None
  }
  let task : PlanbookRepairTask = @json.from_json(parsed) catch {
    _ => return None
  }
  if task.criterion_id != criterion.id {
    return None
  }
  if planbook_repair_task_in_flight(task) {
    Some(task)
  } else {
    None
  }
}

///|
pub async fn render_moontown_planbook_repair_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  let path = default_planbook_repair_path(snapshot_path~)
  if !@fs.exists(path) {
    return "No PlanBook repair task exists at \{path}. Run `moon run cmd/main -- planbook repair`."
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ =>
      return "PlanBook repair task exists at \{path}, but it is not valid JSON."
  }
  let task : PlanbookRepairTask = @json.from_json(parsed) catch {
    _ =>
      return "PlanBook repair task exists at \{path}, but it does not match the contract."
  }
  if task.criterion_id == "none" {
    let status = inspect_moontown_planbook_autonomy(snapshot_path~)
    match first_planbook_open_criterion(status) {
      Some(criterion) =>
        return "PlanBook repair task at \{path} is stale: autonomy now has open gap `\{criterion.id}`. Run `moon run cmd/main -- planbook repair --dispatch` to refresh and dispatch the bounded repair."
      None => ()
    }
  }
  let result_text = reconcile_planbook_repair_result(task)
  render_planbook_repair_markdown(task, result_text~)
}

///|
pub async fn planbook_repair_active_count(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> Int {
  let path = default_planbook_repair_path(snapshot_path~)
  if !@fs.exists(path) {
    return 0
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch { _ => return 0 }
  let task : PlanbookRepairTask = @json.from_json(parsed) catch {
    _ => return 0
  }
  if planbook_repair_criterion_now_satisfied(task) {
    return 0
  }
  if reconcile_planbook_repair_result(task) != "" {
    return 0
  }
  if planbook_repair_task_in_flight(task) {
    1
  } else {
    0
  }
}

///|
async fn planbook_repair_task_in_flight(task : PlanbookRepairTask) -> Bool {
  if task.status != "dispatched" && task.status != "running" {
    return false
  }
  let run_id = match task.run_id {
    Some(run_id) => run_id
    None => return false
  }
  match planbook_repair_run_status(task, run_id) {
    Some("Pending") => @moonclaw.run_process_alive(run_id)
    Some("WaitingForInput") => @moonclaw.run_process_alive(run_id)
    Some("Running") => @moonclaw.run_process_alive(run_id)
    Some(_) => false
    None => @moonclaw.run_process_alive(run_id)
  }
}

///|
async fn planbook_repair_run_status(
  task : PlanbookRepairTask,
  run_id : String,
) -> String? {
  let path = "\{task.workspace_root}/.moonclaw/jobs/index/runs.json"
  if !@fs.exists(path) {
    return None
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ => return None
  }
  match parsed {
    Object(root) =>
      match root.get("runs") {
        Some(Array(runs)) => {
          for item in runs {
            match item {
              Object(run) =>
                if json_object_string(run, "id") == Some(run_id) {
                  return json_object_string(run, "status")
                }
              _ => ()
            }
          }
          None
        }
        _ => None
      }
    _ => None
  }
}

///|
fn json_object_string(object : Map[String, Json], key : String) -> String? {
  match object.get(key) {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
async fn existing_planbook_repair_handoff(
  criterion : PlanbookCriterionStatus,
  snapshot_path : String,
  workspace_root : String,
) -> PlanbookRepairTask? {
  ignore(snapshot_path)
  let result_path = "\{workspace_root}/raw/repair/repair-result.md"
  let result_text = read_text_or_empty(result_path)
  if !result_text.contains("criterion_id: \{criterion.id}") {
    return None
  }
  if !result_text.contains("repair_decision: needs_external_owner") &&
    !result_text.contains("repair_decision: blocked") {
    return None
  }
  if planbook_repair_handoff_is_stale(criterion, result_text) {
    return None
  }
  Some({
    id: "planbook-repair-\{criterion.id}",
    criterion_id: criterion.id,
    title: criterion.title,
    status: "blocked",
    owner: criterion.owner,
    workspace_root,
    packet_path: "\{workspace_root}/raw/repair/planbook-repair-\{criterion.id}.packet.json",
    proposal_id: None,
    run_id: None,
    summary: "Existing repair result classifies this gap as an ownership handoff. Moontown will not dispatch duplicate repair packets until the owner boundary changes or the result is cleared.",
    validation_command: planbook_repair_validation_command(),
    generated_at_ms: @env.now(),
  })
}

///|
fn planbook_repair_handoff_is_stale(
  criterion : PlanbookCriterionStatus,
  result_text : String,
) -> Bool {
  match criterion.id {
    "live-runtime-recovery" => !result_text.contains(criterion.evidence)
    _ => false
  }
}

///|
async fn planbook_repair_criterion_now_satisfied(
  task : PlanbookRepairTask,
) -> Bool {
  match task.criterion_id {
    "moonbook-native-planbook-provider" =>
      @fs.exists("../moonbook/seed/wiki/skills/code-plan/SKILL.md") ||
      @fs.exists("../moonbook/seed/wiki/skills/planbook/SKILL.md")
    "live-runtime-recovery" => {
      let status = inspect_moontown_planbook_autonomy()
      for item in status.criteria {
        if item.id == "live-runtime-recovery" {
          return item.satisfied
        }
      }
      false
    }
    _ => false
  }
}

///|
async fn materialize_planbook_repair_task(
  criterion : PlanbookCriterionStatus,
  snapshot_path : String,
  workspace_root : String,
  book_catalog_path : String,
  dispatch : Bool,
) -> PlanbookRepairTask {
  ignore(snapshot_path)
  ignore(book_catalog_path)
  let task_id = "planbook-repair-\{criterion.id}"
  let packet_path = "\{workspace_root}/raw/repair/\{task_id}.packet.json"
  write_planbook_repair_workspace(criterion, workspace_root)
  clear_stale_planbook_repair_result(workspace_root, criterion)
  let packet = planbook_repair_packet(criterion, task_id)
  let mut proposal_id : String? = None
  let mut run_id : String? = None
  let mut task_status = "queued"
  let mut summary = "Queued bounded repair packet for `\{criterion.id}`. Dispatch with `moon run cmd/main -- planbook repair --dispatch` when MoonClaw/Codex execution is available."
  if dispatch {
    let imported = @moonclaw.import_packet(
      packet,
      packet_path,
      cwd=workspace_root,
      confirm=true,
      run_inline=moontown_moonclaw_inline_enabled(),
    ) catch {
      error =>
        return {
          id: task_id,
          criterion_id: criterion.id,
          title: criterion.title,
          status: "blocked",
          owner: criterion.owner,
          workspace_root,
          packet_path,
          proposal_id: None,
          run_id: None,
          summary: "MoonClaw repair dispatch failed: \{error}",
          validation_command: planbook_repair_validation_command(),
          generated_at_ms: @env.now(),
        }
    }
    proposal_id = Some(imported.proposal_id)
    run_id = imported.run_id
    let launch_command = match imported.run_id {
      Some(run_id) if !moontown_moonclaw_inline_enabled() =>
        Some(@moonclaw.run_confirmed_run(run_id, cwd=workspace_root))
      _ => None
    }
    task_status = if imported.run_id is Some(_) {
      "dispatched"
    } else {
      "queued"
    }
    summary = match launch_command {
      Some(command) => "\{imported.summary} Detached runner: \{command}"
      None => imported.summary
    }
  } else {
    @moonclaw.save_packet_file(packet_path, packet)
  }
  {
    id: task_id,
    criterion_id: criterion.id,
    title: criterion.title,
    status: task_status,
    owner: criterion.owner,
    workspace_root,
    packet_path,
    proposal_id,
    run_id,
    summary,
    validation_command: planbook_repair_validation_command(),
    generated_at_ms: @env.now(),
  }
}

///|
async fn clear_stale_planbook_repair_result(
  workspace_root : String,
  criterion : PlanbookCriterionStatus,
) -> Unit {
  let result_path = "\{workspace_root}/raw/repair/repair-result.md"
  let result_text = read_text_or_empty(result_path)
  if result_text != "" &&
    planbook_repair_handoff_is_stale(criterion, result_text) {
    write_text_file(
      "\{workspace_root}/raw/repair/repair-result.superseded.md",
      result_text,
    )
    @fs.remove(result_path) catch {
      _ => write_text_file(result_path, "")
    }
  }
}

///|
async fn write_planbook_repair_workspace(
  criterion : PlanbookCriterionStatus,
  workspace_root : String,
) -> Unit {
  write_text_file(
    "\{workspace_root}/raw/repair/PLANBOOK_REPAIR_CONTEXT.md",
    planbook_repair_context_markdown(criterion),
  )
  write_text_file(
    "\{workspace_root}/skills/planbook-repair/SKILL.md",
    planbook_repair_skill_markdown(),
  )
  write_text_file(
    "\{workspace_root}/plans/self-healing-repair/plan.md",
    planbook_repair_plan_markdown(criterion),
  )
  write_planbook_repair_moonclaw_profile(workspace_root)
  write_planbook_repair_acp_target(workspace_root)
}

///|
async fn write_planbook_repair_moonclaw_profile(
  workspace_root : String,
) -> Unit {
  let path = "\{workspace_root}/moonclaw.jobs.json"
  let base = if @fs.exists(path) {
    @json.parse(@fs.read_file(path).text()) catch {
      _ => Json::object({})
    }
  } else {
    Json::object({})
  }
  write_text_file(
    path,
    upsert_planbook_repair_profile_json(base).stringify(indent=2),
  )
}

///|
async fn write_planbook_repair_acp_target(workspace_root : String) -> Unit {
  let home = "\{workspace_root}/.moonclaw"
  let path = "\{home}/moonclaw.json"
  let base = if @fs.exists(path) {
    @json.parse(@fs.read_file(path).text()) catch {
      _ => Json::object({})
    }
  } else {
    Json::object({})
  }
  let root = json_object_copy(Some(base))
  let acp = json_object_copy(root.get("acp"))
  let targets = json_object_copy(acp.get("targets"))
  let codex_command = resolved_codex_command()
  targets["codex-main"] = {
    "backend": "codex",
    "label": "Codex PlanBook Repair",
    "cwd": workspace_root,
    "workspace": workspace_root,
    "command": codex_command,
    "args": resolved_codex_args(),
    "model": "gpt-5",
  }
  acp["targets"] = Json::object(targets)
  root["acp"] = Json::object(acp)
  write_text_file(path, Json::object(root).stringify(indent=2))
}

///|
fn resolved_codex_command() -> String {
  match optional_env_text("CODEX_BIN") {
    Some(command) => command
    None => "/Users/kq/.nvm/versions/node/v22.22.1/bin/node"
  }
}

///|
fn resolved_codex_args() -> Array[String] {
  match optional_env_text("CODEX_BIN") {
    Some(_) => ["exec"]
    None =>
      [
        "/Users/kq/.nvm/versions/node/v22.22.1/lib/node_modules/@openai/codex/bin/codex.js",
        "exec",
      ]
  }
}

///|
fn planbook_repair_timeout_ms_json() -> Json {
  let value = 600000
  value.to_json()
}

///|
fn upsert_planbook_repair_profile_json(base : Json) -> Json {
  let root = json_object_copy(Some(base))
  let jobs = json_object_copy(root.get("jobs"))
  let profiles = json_object_copy(jobs.get("profiles"))
  profiles["planbook_repair_worker"] = planbook_repair_worker_profile_json()
  jobs["profiles"] = Json::object(profiles)
  root["jobs"] = Json::object(jobs)
  Json::object(root)
}

///|
fn planbook_repair_worker_profile_json() -> Json {
  {
    "family": "planbook_repair_worker",
    "role": "worker",
    "priority": 180,
    "tags": ["planbook", "self-healing", "repair"],
    "match": {
      "all": ["planbook", "repair"],
      "any": ["self-healing", "gap", "criterion"],
    },
    "steps": [
      {
        "id": "repair_planbook_gap",
        "title": "Repair one bounded PlanBook self-build gap",
        "kind": "job.analysis",
        "prompt_template": "Read ${proposal.request_text}. Then read context_pages and skill_paths. Make the smallest safe repair or return a precise ownership blocker. Write raw/repair/repair-result.md with the planbook.repair.result.v1 contract.",
        "metadata": {
          "preferred_skills": ["planbook-repair", "code-plan", "code-review"],
          "enable_tools": true,
          "execution_mode": "acp",
          "execution_target": "codex-main",
          "output_contract": "planbook.repair.result.v1",
          "target_pages": [
            "raw/repair/repair-result.md", "wiki/reviews/active-plan-review.md",
            "wiki/planning/execution-evidence.md",
          ],
          "disable_waiting_for_input": true,
          "best_effort_on_missing_input": true,
          "best_effort_on_timeout": true,
          "timeout_ms": 600000,
          "role_runtime": {
            "planning_layer": "town-self-healing",
            "runtime_mode": "bounded-repair",
            "tool_access": "workspace-and-repo",
            "memory_scope": "planbook",
            "allow_delegate": false,
            "allow_workspace_write": true,
            "allow_execution_tools": true,
            "output_contract": "planbook.repair.result.v1",
          },
        },
      },
    ],
    "metadata": {
      "owner": "moontown-planbook",
      "purpose": "Repair one PlanBook self-build criterion without leaking MoonBook or MoonClaw ownership into Moontown.",
    },
  }
}

///|
fn planbook_repair_packet(
  criterion : PlanbookCriterionStatus,
  task_id : String,
) -> @moonclaw.ExternalProposalPacket {
  @moonclaw.ExternalProposalPacket::new(
    packet_id=task_id,
    title="Repair PlanBook gap: \{criterion.title}",
    summary="Bounded self-repair task for PlanBook criterion `\{criterion.id}`.",
    request_text=planbook_repair_request_text(criterion),
    profile="planbook_repair_worker",
    output_contract="planbook.repair.result.v1",
    context_pages=[
      "raw/repair/PLANBOOK_REPAIR_CONTEXT.md", "plans/self-healing-repair/plan.md",
      "wiki/planning/self-healing.md", "wiki/reviews/active-plan-review.md",
    ],
    skill_paths=["skills/planbook-repair/SKILL.md"],
    notes=[
      "Make the smallest safe repair that satisfies the criterion.", "Do not modify unrelated book/domain content.",
      "If the repair belongs in MoonBook or MoonClaw, produce a precise patch plan and blocker instead of leaking ownership into Moontown.",
    ],
    tags=["planbook", "self-healing", "repair", criterion.id],
    metadata={
      "producer": "moontown".to_json(),
      "book_id": default_planbook_book_id().to_json(),
      "criterion_id": criterion.id.to_json(),
      "plan_id": criterion.plan_id.to_json(),
      "owner": criterion.owner.to_json(),
      "disable_waiting_for_input": true.to_json(),
      "best_effort_on_missing_input": true.to_json(),
      "best_effort_on_timeout": true.to_json(),
      "timeout_ms": planbook_repair_timeout_ms_json(),
      "profile_metadata": {
        "disable_waiting_for_input": true.to_json(),
        "best_effort_on_missing_input": true.to_json(),
        "best_effort_on_timeout": true.to_json(),
        "timeout_ms": planbook_repair_timeout_ms_json(),
      },
      "step_metadata": {
        "kind": "planbook_repair".to_json(),
        "execution_mode": "acp".to_json(),
        "execution_target": "codex-main".to_json(),
        "output_contract": "planbook.repair.result.v1".to_json(),
        "preferred_skills": ["planbook-repair", "code-plan", "code-review"].to_json(),
        "target_pages": [
          "raw/repair/repair-result.md", "wiki/reviews/active-plan-review.md", "wiki/planning/execution-evidence.md",
        ].to_json(),
        "disable_waiting_for_input": true.to_json(),
        "best_effort_on_missing_input": true.to_json(),
        "best_effort_on_timeout": true.to_json(),
        "timeout_ms": planbook_repair_timeout_ms_json(),
      },
    },
  )
}

///|
fn planbook_repair_request_text(criterion : PlanbookCriterionStatus) -> String {
  [
    "You are the PlanBook repair worker for Moontown.",
    "Open criterion: `\{criterion.id}`.",
    "Title: \{criterion.title}",
    "Owner boundary: \{criterion.owner}.",
    "Evidence: \{criterion.evidence}",
    "Required next action: \{criterion.next_action}",
    "",
    "Task:",
    "1. Read `skills/planbook-repair/SKILL.md` and the repair context.",
    "2. Decide whether this can be fixed inside Moontown or must be handed to MoonBook/MoonClaw.",
    "3. If it can be fixed safely, apply the smallest code/docs change.",
    "4. Run or name validation commands.",
    "5. Write `raw/repair/repair-result.md` with decision, files changed, validation, remaining blockers, and cookbook impact.",
    "6. Do not mark the criterion satisfied unless evidence exists after validation.",
  ].join("\n")
}

///|
fn planbook_repair_context_markdown(
  criterion : PlanbookCriterionStatus,
) -> String {
  [
    "# PlanBook Repair Context",
    "",
    "- Criterion: `\{criterion.id}`",
    "- Plan: `\{criterion.plan_id}`",
    "- Title: \{criterion.title}",
    "- Owner: \{criterion.owner}",
    "- Satisfied: `\{criterion.satisfied}`",
    "- Evidence: \{criterion.evidence}",
    "- Next action: \{criterion.next_action}",
    "",
    "## Boundary Rule",
    "",
    "Moontown may repair routing, daemon, live-spine, UI projection, and PlanBook evidence plumbing. MoonBook owns native book profiles/templates/projections. MoonClaw owns execution runtime behavior and provider retry stability. Do not copy another project into Moontown to fake ownership.",
  ].join("\n")
}

///|
fn planbook_repair_plan_markdown(criterion : PlanbookCriterionStatus) -> String {
  [
    "# Plan: Self-Heal `\{criterion.id}`",
    "",
    "## Problem",
    "",
    criterion.evidence,
    "",
    "## Goal",
    "",
    criterion.next_action,
    "",
    "## Acceptance Criteria",
    "",
    "- [ ] Repair worker writes `raw/repair/repair-result.md`.",
    "- [ ] Validation command is recorded.",
    "- [ ] PlanBook autonomy doctor reruns and updates `.moontown/planbook/autonomy.json`.",
    "- [ ] If ownership is outside Moontown, the result names the correct repository and does not fake completion.",
  ].join("\n")
}

///|
fn planbook_repair_skill_markdown() -> String {
  [
    "---", "name: planbook-repair", "description: Repair one bounded PlanBook self-build gap while preserving Moontown/MoonBook/MoonClaw ownership boundaries.",
    "---", "", "# PlanBook Repair Skill", "", "You repair exactly one self-build criterion. Prefer small patches, direct validation, and explicit blockers over broad rewrites.",
    "", "## Required Decision", "", "- `repair_decision`: accepted | needs_external_owner | blocked | no_change",
    "- `criterion_id`: the criterion being repaired", "- `files_changed`: exact files changed, or `none`",
    "- `validation`: commands run and results", "- `remaining_blockers`: unresolved gaps",
    "- `cookbook_impact`: none | update_needed | updated", "", "## Rules", "", "- Fix Moontown-owned routing/live-spine/UI/docs issues inside Moontown.",
    "- For MoonBook-native provider/profile work, produce a MoonBook patch plan or patch only when executing inside MoonBook.",
    "- For MoonClaw runtime/provider work, produce a MoonClaw patch plan or patch only when executing inside MoonClaw.",
    "- Never claim success because a markdown plan exists.", "- Rerun the PlanBook doctor after a local repair.",
    "", "## Concrete Example", "", "```md", "repair_decision: accepted", "criterion_id: planbook-live-spine",
    "files_changed: live_autonomy.mbt, planbook_autonomy.mbt", "validation: moon check --no-render passed; moon test planbook_autonomy_wbtest.mbt passed",
    "remaining_blockers: none for this criterion", "cookbook_impact: update_needed",
    "```",
  ].join("\n")
}

///|
async fn write_planbook_repair_status(
  task : PlanbookRepairTask,
  workspace_root : String,
  snapshot_path : String,
) -> Unit {
  write_text_file(
    default_planbook_repair_path(snapshot_path~),
    task.to_json().stringify(indent=2),
  )
  write_text_file(
    default_planbook_repair_markdown_path(snapshot_path~),
    render_planbook_repair_markdown(task),
  )
  write_text_file(
    "\{workspace_root}/wiki/planning/self-healing-repair.md",
    render_planbook_repair_markdown(task),
  )
}

///|
async fn reconcile_planbook_repair_result(task : PlanbookRepairTask) -> String {
  let existing = planbook_repair_result_text_for_task(task)
  if existing != "" {
    return existing
  }
  let run_result = planbook_repair_result_text_from_run(task)
  if run_result != "" {
    write_text_file(planbook_repair_result_path(task), run_result)
  }
  run_result
}

///|
fn render_planbook_repair_markdown(
  task : PlanbookRepairTask,
  result_text? : String = "",
) -> String {
  let proposal = task.proposal_id.unwrap_or("none")
  let run = task.run_id.unwrap_or("none")
  let lines = [
    "# PlanBook Repair Task",
    "",
    "- id: `\{task.id}`",
    "- criterion: `\{task.criterion_id}`",
    "- title: \{task.title}",
    "- status: `\{task.status}`",
    "- owner: `\{task.owner}`",
    "- workspace: `\{task.workspace_root}`",
    "- packet: `\{task.packet_path}`",
    "- proposal: `\{proposal}`",
    "- run: `\{run}`",
    "- validation: `\{task.validation_command}`",
    "",
    "## Summary",
    "",
    task.summary,
  ]
  if result_text != "" {
    lines.push("")
    lines.push("## Repair Result")
    lines.push("")
    lines.push("```text")
    lines.push(result_text)
    lines.push("```")
  }
  lines.join("\n")
}

///|
fn planbook_repair_result_path(task : PlanbookRepairTask) -> String {
  "\{task.workspace_root}/raw/repair/repair-result.md"
}

///|
async fn planbook_repair_result_text_for_task(
  task : PlanbookRepairTask,
) -> String {
  let text = read_text_or_empty(planbook_repair_result_path(task))
  if text.contains("criterion_id: \{task.criterion_id}") ||
    text.contains("\"criterion_id\":\"\{task.criterion_id}\"") ||
    text.contains("\"criterion_id\": \"\{task.criterion_id}\"") {
    text
  } else {
    ""
  }
}

///|
async fn planbook_repair_result_text_from_run(
  task : PlanbookRepairTask,
) -> String {
  let run_id = match task.run_id {
    Some(run_id) => run_id
    None => return ""
  }
  let workspace_dir = match
    @moonclaw.run_workspace_dir(run_id, cwd=task.workspace_root) {
    Some(workspace_dir) => workspace_dir
    None => return ""
  }
  let result_path = "\{workspace_dir}/result.json"
  if !@fs.exists(result_path) {
    return ""
  }
  let parsed = @json.parse(@fs.read_file(result_path).text()) catch {
    _ => return ""
  }
  let content = json_string_field(parsed, "content").unwrap_or("")
  if content.contains("criterion_id: \{task.criterion_id}") ||
    content.contains("\"criterion_id\":\"\{task.criterion_id}\"") ||
    content.contains("\"criterion_id\": \"\{task.criterion_id}\"") {
    content
  } else {
    ""
  }
}

///|
fn json_string_field(value : Json, key : String) -> String? {
  match value {
    Object(object) =>
      match object.get(key) {
        Some(String(text)) => Some(text)
        _ => None
      }
    _ => None
  }
}

///|
fn first_planbook_open_criterion(
  status : PlanbookAutonomyStatus,
) -> PlanbookCriterionStatus? {
  for item in status.criteria {
    if !item.satisfied {
      return Some(item)
    }
  }
  None
}

///|
fn planbook_noop_repair_task(
  snapshot_path : String,
  workspace_root : String,
) -> PlanbookRepairTask {
  ignore(snapshot_path)
  {
    id: "planbook-repair-none",
    criterion_id: "none",
    title: "No open PlanBook gap",
    status: "idle",
    owner: "moontown",
    workspace_root,
    packet_path: "",
    proposal_id: None,
    run_id: None,
    summary: "No open PlanBook gap was found.",
    validation_command: planbook_repair_validation_command(),
    generated_at_ms: @env.now(),
  }
}

///|
fn planbook_repair_validation_command() -> String {
  "moon check --no-render && moon test planbook_autonomy_wbtest.mbt live_autonomy_wbtest.mbt && moon test"
}
