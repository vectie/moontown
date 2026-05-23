///|
fn prioritized_tasks(
  tasks : Array[@moonbook.BookTask],
  goal : String,
) -> Array[@moonbook.BookTask] {
  let ordered = tasks.copy()
  let research_goal = is_research_goal(goal)
  ordered.sort_by(fn(left, right) {
    task_priority_score(right, research_goal).compare(
      task_priority_score(left, research_goal),
    )
  })
  ordered
}

///|
priv struct ResearchBootstrapPlan {
  tasks : Array[@moonbook.BookTask]
  task_limit : Int
  bootstrap_active : Bool
}

///|
async fn preseed_goal_bootstrap_inputs(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
) -> Unit {
  if entry.id.has_prefix("research-") {
    preseed_reference_style_inputs(entry, objective)
  }
  if !entry.id.has_prefix("wenyu-") {
    return
  }
  let root = @moonbook.workspace_root(entry)
  let request_path = "\{root}/raw/bootstrap/RESEARCH_REQUEST.md"
  let hints_path = "\{root}/raw/bootstrap/SOURCE_HINTS.md"
  let prd_copy_path = "\{root}/raw/bootstrap/WENYU_VALLEY_PRD.md"
  let vision_copy_path = "\{root}/raw/bootstrap/WENYU_VISION.md"
  let module_name = wenyu_module_name(entry)
  let repo_root = moontown_repo_root()
  let prd_path = "\{repo_root}/docs/WENYU_VALLEY_PRD.md"
  let vision_path = "\{repo_root}/wenyu.md"
  match read_optional_text(prd_path) {
    Some(text) => write_text_file(prd_copy_path, text)
    None => ()
  }
  match read_optional_text(vision_path) {
    Some(text) => write_text_file(vision_copy_path, text)
    None => ()
  }
  preseed_wenyu_source_bundle(root, repo_root)
  write_wenyu_build_skills(root, entry)
  ensure_wenyu_build_moonclaw_profile(root)
  ensure_wenyu_codex_acp_target(root)
  write_text_file(
    request_path,
    [
      "# Research Request",
      "",
      "## Subject",
      "",
      "Wenyu Valley module: \{module_name}",
      "",
      "## Goal",
      "",
      objective,
      "",
      "## Required Research Behavior",
      "",
      "- Treat this as Wenyu Valley product/build research, not generic MoonBook or MoonClaw research.",
      "- Use the PRD as the primary contract before inspecting generic workspace scaffold files.",
      "- Search the web first for comparable civic AI town, innovation district, student entrepreneurship, digital twin, and community platform patterns that match this module.",
      "- Then inspect local project files for Moontown, MoonBook, MoonClaw, Rabbita UI, and Wenyu Valley docs.",
      "- Produce module-specific implementation tasks, risks, acceptance criteria, and marketing/product language.",
      "- Do not collapse this module into a generic workspace bootstrap report.",
      "",
      "## Required Artifact Quality",
      "",
      "- `research-question.md` must name `\{module_name}` and Wenyu Valley.",
      "- `deep-report.md` title must be `# \{module_name}: Deep Research Analysis` or a clearer Wenyu-specific equivalent.",
      "- `marketing-brief.md` must sell this module as part of Wenyu Valley.",
      "- Evidence rows must include the local PRD copy at `raw/bootstrap/WENYU_VALLEY_PRD.md` and at least one local project or UI source when available.",
      "",
    ].join("\n"),
  )
  write_text_file(
    hints_path,
    [
      "# Source Hints",
      "",
      "## Primary Contract",
      "",
      "- `raw/bootstrap/WENYU_VALLEY_PRD.md`: local immutable copy of the Wenyu Valley PRD. Read this first.",
      "- `raw/bootstrap/WENYU_VISION.md`: local immutable copy of the original Wenyu vision when present.",
      "- `\{prd_path}`: absolute path to product requirements and module contract for Wenyu Valley.",
      "- `\{vision_path}`: absolute path to original user-facing vision/reference file when present.",
      "- `../../../docs/WENYU_VALLEY_PRD.md`: product requirements and module contract for Wenyu Valley.",
      "- `../../../wenyu.md`: original user-facing vision/reference file when present.",
      "",
      "## Local Implementation Sources",
      "",
      "- `mounted-sources/MANIFEST.md`: manifest of Moontown, MoonBook, MoonClaw, and Rabbita files copied into this isolated research workspace.",
      "- `mounted-sources/moontown/ui-rabbita-town-main.mbt`: gamified town UI implementation snapshot.",
      "- `mounted-sources/moontown/ui-rabbita-town-styles.css`: gamified town visual system snapshot.",
      "- `mounted-sources/moontown/roles-mayor.mbt`: mayor decomposition and strategic routing snapshot.",
      "- `mounted-sources/moontown/goal-run.mbt`: town goal launch and book orchestration snapshot.",
      "- `mounted-sources/moontown/goal-bootstrap.mbt`: bootstrap-first routing for research/build lanes snapshot.",
      "- `mounted-sources/moontown/scheduler-daemon.mbt`: daemon scheduling and supervision primitives snapshot.",
      "- `mounted-sources/moontown/moontown.mbt`: town runtime, workers, dispatch, and lifecycle snapshot.",
      "- `mounted-sources/moontown/adapters-moonbook-client.mbt`: MoonBook workspace/task/projection adapter snapshot.",
      "- `mounted-sources/moontown/adapters-moonclaw-client.mbt`: MoonClaw execution adapter snapshot.",
      "- `mounted-sources/moonbook/research-report-skill.md`: MoonBook deep research report skill snapshot.",
      "- `mounted-sources/moonbook/wiki-ingest-skill.md`: MoonBook wiki ingest skill snapshot.",
      "- `mounted-sources/moonbook/wiki-marketing-skill.md`: MoonBook marketing projection skill snapshot.",
      "- `mounted-sources/moonbook/wiki-ui-state-content.mbt`: MoonBook generated-site content/projection snapshot.",
      "- `mounted-sources/moonbook/wiki-extensions-profiles.mbt`: MoonBook extension/profile routing snapshot.",
      "- `mounted-sources/moonclaw/provider-task-execution-skill.md`: MoonClaw provider task execution skill snapshot.",
      "- `mounted-sources/moonclaw/research-report-writer-skill.md`: MoonClaw report-writing skill snapshot.",
      "- `mounted-sources/moonclaw/job-provider-task.mbt`: MoonClaw provider task runtime snapshot.",
      "- `mounted-sources/moonclaw/job-analysis-runner.mbt`: MoonClaw analysis runner snapshot.",
      "- `\{repo_root}/ui/rabbita-town/main/main.mbt`: gamified town UI implementation.",
      "- `\{repo_root}/ui/rabbita-town/styles.css`: gamified town visual system.",
      "- `\{repo_root}/roles/mayor.mbt`: mayor decomposition and strategic routing.",
      "- `\{repo_root}/goal_run.mbt`: town goal launch and book orchestration.",
      "- `\{repo_root}/goal_bootstrap.mbt`: bootstrap-first routing for research/build lanes.",
      "- `\{repo_root}/scheduler/daemon.mbt`: daemon scheduling and supervision primitives.",
      "- `\{repo_root}/adapters/moonbook/client.mbt`: MoonBook workspace/task/projection adapter.",
      "- `\{repo_root}/adapters/moonclaw/client.mbt`: MoonClaw execution adapter.",
      "- `../../../ui/rabbita-town/main/main.mbt`: gamified town UI implementation.",
      "- `../../../ui/rabbita-town/styles.css`: gamified town visual system.",
      "- `../../../roles/mayor.mbt`: mayor decomposition and strategic routing.",
      "- `../../../goal_run.mbt`: town goal launch and book orchestration.",
      "- `../../../goal_bootstrap.mbt`: bootstrap-first routing for research/build lanes.",
      "- `../../../scheduler/daemon.mbt`: daemon scheduling and supervision primitives.",
      "- `../../../adapters/moonbook/client.mbt`: MoonBook workspace/task/projection adapter.",
      "- `../../../adapters/moonclaw/client.mbt`: MoonClaw execution adapter.",
      "",
      "## Adjacent Repositories",
      "",
      "- `../../../../moonbook`: MoonBook workspace, wiki, projection, and skill implementation.",
      "- `../../../../moonclaw`: MoonClaw worker runtime, job profiles, and execution boundary.",
      "- `../../../../sou`: visual reference for town-like UI when available.",
      "- `../../../../gas`: multi-agent reference when available.",
      "- `../../../../ctc`: code-to-course/page skill reference when available.",
      "",
      "## Search Guidance",
      "",
      "- Search web before local file search.",
      "- Prefer sources about civic innovation districts, youth innovation communities, digital-twin campuses, AI agent towns, social simulation dashboards, public-service chatbots, community operation systems, and entrepreneurship/talent matching platforms.",
      "- Reject unrelated name collisions and search-engine landing pages as evidence.",
      "",
    ].join("\n"),
  )
}

///|
async fn preseed_reference_style_inputs(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
) -> Unit {
  let report_path = optional_env_text("MOONTOWN_REFERENCE_REPORT_PATH")
  let visual_path = optional_env_text("MOONTOWN_REFERENCE_IMAGE_PATH")
  let source_hints_path = optional_env_text(
    "MOONTOWN_REFERENCE_SOURCE_HINTS_PATH",
  )
  if report_path is None && visual_path is None && source_hints_path is None {
    return
  }
  let root = @moonbook.workspace_root(entry)
  let bootstrap_root = "\{root}/raw/bootstrap"
  let mut copied_report = false
  let mut copied_report_lines = 0
  let mut copied_source_hints = false
  let mut copied_source_hint_lines = 0
  match report_path {
    Some(path) =>
      match read_optional_text(path) {
        Some(text) => {
          write_text_file("\{bootstrap_root}/REFERENCE_OUTPUT.md", text)
          copied_report = true
          copied_report_lines = count_reference_lines(text)
        }
        None => ()
      }
    None => ()
  }
  match visual_path {
    Some(path) =>
      write_text_file("\{bootstrap_root}/REFERENCE_VISUAL_PATH.txt", path)
    None => ()
  }
  match source_hints_path {
    Some(path) =>
      match read_optional_text(path) {
        Some(text) => {
          write_text_file("\{bootstrap_root}/REFERENCE_SOURCE_HINTS.md", text)
          copied_source_hints = true
          copied_source_hint_lines = count_reference_lines(text)
        }
        None => ()
      }
    None => ()
  }
  write_text_file(
    "\{bootstrap_root}/REFERENCE_STYLE.md",
    reference_style_seed_text(
      entry, objective, report_path, visual_path, source_hints_path, copied_report,
      copied_report_lines, copied_source_hints, copied_source_hint_lines,
    ),
  )
}

///|
fn optional_env_text(key : String) -> String? {
  match @sys.get_env_var(key) {
    Some(value) => {
      let trimmed = value.trim().to_string()
      if trimmed.is_empty() {
        None
      } else {
        Some(trimmed)
      }
    }
    None => None
  }
}

///|
fn reference_style_seed_text(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  report_path : String?,
  visual_path : String?,
  source_hints_path : String?,
  copied_report : Bool,
  copied_report_lines : Int,
  copied_source_hints : Bool,
  copied_source_hint_lines : Int,
) -> String {
  let report_line = match report_path {
    Some(path) =>
      if copied_report {
        "- Reference report copied from `\{path}` to `raw/bootstrap/REFERENCE_OUTPUT.md` (\{copied_report_lines} lines)."
      } else {
        "- Reference report requested at `\{path}`, but the file could not be read."
      }
    None => "- No reference report path was supplied."
  }
  let visual_line = match visual_path {
    Some(path) => "- Reference visual path supplied: `\{path}`."
    None => "- No reference visual path was supplied."
  }
  let source_hint_line = match source_hints_path {
    Some(path) =>
      if copied_source_hints {
        "- Reference source hints copied from `\{path}` to `raw/bootstrap/REFERENCE_SOURCE_HINTS.md` (\{copied_source_hint_lines} lines)."
      } else {
        "- Reference source hints requested at `\{path}`, but the file could not be read."
      }
    None => "- No reference source hints path was supplied."
  }
  let target_line = if copied_report && copied_report_lines >= 200 {
    let target = (copied_report_lines * 60 + 99) / 100
    "- Reference-matched minimum: when enough screened sources exist, `raw/bootstrap/deep-report.md` should reach at least \{target} lines (60% of the reference report), and repair passes should target at least 30 lines above that minimum to avoid brittle near-misses."
  } else {
    "- No numeric reference-length minimum applies."
  }
  [
    "# Reference Style Seed",
    "",
    "This file is a style and quality seed for `\{entry.id}`. It is not domain evidence.",
    "",
    "## Objective",
    "",
    objective,
    "",
    "## Supplied References",
    "",
    report_line,
    target_line,
    visual_line,
    source_hint_line,
    "",
    "## Usage Rules",
    "",
    "- Use `raw/bootstrap/REFERENCE_OUTPUT.md` only to infer depth, organization, evidence density, visual/table expectations, and reader-facing quality.",
    "- Do not copy the reference report's factual claims into the new topic unless independent screened evidence supports them.",
    "- Use the reference report's route names, comparison axes, diagrams, and section taxonomy as hypotheses or search leads when they are relevant to the user's objective. Verify every adopted route independently before using it as evidence.",
    "- Use `raw/bootstrap/REFERENCE_SOURCE_HINTS.md`, when present, only as a lead sheet. Fetch, screen, include, reject, or mark each lead blocked before it can influence synthesis.",
    "- Match the reference's ambition and approximate length class: long-form thesis-first analysis, numbered sections, source-backed claims, comparison tables, roadmap or maturity logic, and a final evidence/limits section.",
    "- If the reference is in Chinese, keep Chinese as the default report language unless the user goal clearly asks for another language.",
    "- If a reference visual is supplied, use it as a cue for the kind of analytical visualization to create, such as a comparison matrix or radar-style score table. Do not treat the image as source evidence unless its underlying data is independently verified.",
  ].join("\n")
}

///|
fn count_reference_lines(text : String) -> Int {
  if text.is_empty() {
    return 0
  }
  let mut count = 0
  for _ in text.split("\n") {
    count += 1
  }
  count
}

///|
async fn ensure_wenyu_build_moonclaw_profile(root : String) -> Unit {
  let path = "\{root}/moonclaw.jobs.json"
  let profile = wenyu_build_moonclaw_profile_json()
  let profile_json = @json.parse(profile) catch { _ => Json::object({}) }
  if !@fs.exists(path) {
    write_text_file(
      path,
      [
        "{",
        "  \"jobs\": {",
        "    \"profiles\": {",
        "      \"wenyu_build_controller\": \{profile}",
        "    }",
        "  }",
        "}",
      ].join("\n"),
    )
    return
  }
  let text = read_text_or_empty(path)
  let parsed = @json.parse(text) catch {
    _ => {
      insert_wenyu_build_profile_text(path, text, profile)
      return
    }
  }
  write_text_file(
    path,
    upsert_wenyu_build_profile_json(parsed, profile_json).stringify(indent=2),
  )
}

///|
async fn ensure_wenyu_codex_acp_target(root : String) -> Unit {
  write_wenyu_codex_acp_target_config("\{root}/moonclaw.json", root)
  write_wenyu_codex_acp_target_config("\{root}/.moonclaw/moonclaw.json", root)
}

///|
async fn write_wenyu_codex_acp_target_config(
  path : String,
  root : String,
) -> Unit {
  let base = if @fs.exists(path) {
    let text = read_text_or_empty(path)
    @json.parse(text) catch {
      _ => Json::object({})
    }
  } else {
    Json::object({})
  }
  write_text_file(
    path,
    upsert_codex_moontown_target_json(base, root).stringify(indent=2),
  )
}

///|
fn json_object_copy(value : Json?) -> Map[String, Json] {
  let copied : Map[String, Json] = {}
  match value {
    Some(Object(obj)) =>
      for key, entry in obj {
        copied[key] = entry
      }
    _ => ()
  }
  copied
}

///|
fn codex_moontown_target_json() -> Json {
  {
    "backend": "codex",
    "label": "Codex Moontown Builder",
    "cwd": "/Users/kq/Workspace/moontown",
    "workspace": "/Users/kq/Workspace/moontown",
    "command": "/Users/kq/.nvm/versions/node/v22.22.1/bin/codex",
    "args": [
      "exec", "--model", "gpt-5.4", "--sandbox", "workspace-write", "--cd", "/Users/kq/Workspace/moontown",
      "--add-dir", "/Users/kq/Workspace/moonbook", "--add-dir", "/Users/kq/Workspace/moonclaw",
    ],
    "model": "gpt-5.4",
  }
}

///|
fn upsert_codex_moontown_target_json(config : Json, book_root : String) -> Json {
  let root = json_object_copy(Some(config))
  let agents = json_object_copy(root.get("agents"))
  let defaults = json_object_copy(agents.get("defaults"))
  defaults["workspace"] = book_root.to_json()
  agents["defaults"] = Json::object(defaults)
  root["agents"] = Json::object(agents)
  let acp = json_object_copy(root.get("acp"))
  let targets = json_object_copy(acp.get("targets"))
  targets["wenyu-codex-moontown"] = codex_moontown_target_json()
  acp["targets"] = Json::object(targets)
  root["acp"] = Json::object(acp)
  Json::object(root)
}

///|
fn upsert_wenyu_build_profile_json(config : Json, profile : Json) -> Json {
  let root = json_object_copy(Some(config))
  let jobs = json_object_copy(root.get("jobs"))
  let profiles = json_object_copy(jobs.get("profiles"))
  profiles["wenyu_build_controller"] = profile
  jobs["profiles"] = Json::object(profiles)
  root["jobs"] = Json::object(jobs)
  Json::object(root)
}

///|
async fn insert_wenyu_build_profile_text(
  path : String,
  text : String,
  profile : String,
) -> Unit {
  if text.contains("\"wenyu_build_controller\"") {
    return
  }
  let marker = "\"profiles\": {"
  let replacement = "\"profiles\": {\n      \"wenyu_build_controller\": \{profile},"
  if text.contains(marker) {
    write_text_file(path, text.replace(old=marker, new=replacement))
  }
}

///|
fn wenyu_build_moonclaw_profile_json() -> String {
  [
    "{", "        \"family\": \"wenyu_build_controller\",", "        \"role\": \"controller\",",
    "        \"priority\": 150,", "        \"tags\": [\"wenyu\", \"build\", \"code\", \"asset\", \"implementation\"],",
    "        \"match\": {", "          \"all\": [\"wenyu\"],", "          \"any\": [\"build\", \"implementation\", \"code\", \"asset\", \"projection\"]",
    "        },", "        \"steps\": [", "          {", "            \"id\": \"execute_wenyu_build\",",
    "            \"title\": \"Execute Wenyu build packet\",", "            \"kind\": \"job.analysis\",",
    "            \"execution_mode\": \"acp\",", "            \"execution_target\": \"wenyu-codex-moontown\",",
    "            \"prompt_template\": \"Execute the imported Wenyu Valley build packet for ${proposal.title}. This is not a wiki query. Read the packet request, context_pages, skill_paths, and external_packet metadata. If the task asks for a code patch, inspect and edit the named repository paths when safe, then run the narrowest validation command. If the task asks for an asset pack, generate or write production-ready asset prompts and a manifest. If the task asks for a backlog, write implementation-grade backlog and acceptance tests. Always write the requested build/* artifacts in the book workspace. Return changed files, artifacts, blockers, and validation results. Do not claim success without either real file changes or an explicit blocker.\",",
    "            \"metadata\": {", "              \"preferred_skills\": [\"wenyu-build\", \"wenyu-code-patch\", \"wenyu-asset-pack\"],",
    "              \"model\": \"gpt-5.4\",", "              \"enable_tools\": true,",
    "              \"web_search\": false,", "              \"board_lane\": \"Build\",",
    "              \"board_order\": 0,", "              \"disable_waiting_for_input\": true,",
    "              \"best_effort_on_missing_input\": true,", "              \"timeout_ms\": 600000",
    "            }", "          },", "          {", "            \"id\": \"review_wenyu_build\",",
    "            \"title\": \"Review Wenyu build output\",", "            \"kind\": \"job.analysis\",",
    "            \"execution_mode\": \"acp\",", "            \"execution_target\": \"wenyu-codex-moontown\",",
    "            \"prompt_template\": \"Review the build output for ${proposal.title}. First read `.moonclaw/run.json` if present and use its `source_workspace` as the book workspace; do not assume the isolated run workspace is the source book. Verify artifacts in that source book workspace and verify repository paths under `/Users/kq/Workspace/moontown`. Code tasks must either show real repository changes plus `build/CODE_PATCH.md` and `build/TEST_RESULTS.md`, or write/identify `build/CODE_BLOCKERS.md`. Asset tasks must produce module-specific prompts/manifests. Classify the outcome as implemented, prompt-ready, or blocked with exact reasons. Do not report missing artifacts until you checked the source book workspace and repository absolute paths.\",",
    "            \"metadata\": {", "              \"preferred_skills\": [\"wenyu-build\"],",
    "              \"model\": \"gpt-5.4\",", "              \"enable_tools\": true,",
    "              \"web_search\": false,", "              \"board_lane\": \"Review\",",
    "              \"board_order\": 1,", "              \"disable_waiting_for_input\": true,",
    "              \"best_effort_on_missing_input\": true,", "              \"timeout_ms\": 600000",
    "            }", "          }", "        ],", "        \"metadata\": {", "          \"profile_metadata\": {",
    "            \"disable_waiting_for_input\": true,", "            \"best_effort_on_missing_input\": true",
    "          },", "          \"role_runtime\": {", "            \"planning_layer\": \"domain\",",
    "            \"runtime_mode\": \"builder\",", "            \"tool_access\": \"workspace\",",
    "            \"memory_scope\": \"domain\",", "            \"allow_delegate\": false,",
    "            \"allow_workspace_write\": true,", "            \"allow_execution_tools\": true,",
    "            \"output_contract\": \"wenyu.build.packet.v1\"", "          }",
    "        }", "      }",
  ].join("\n")
}

///|
async fn write_wenyu_build_skills(
  root : String,
  entry : @moonbook.BookCatalogEntry,
) -> Unit {
  write_text_file(
    "\{root}/skills/wenyu-build/SKILL.md",
    wenyu_build_skill_text(entry),
  )
  write_text_file(
    "\{root}/skills/wenyu-code-patch/SKILL.md",
    wenyu_code_patch_skill_text(entry),
  )
  write_text_file(
    "\{root}/skills/wenyu-asset-pack/SKILL.md",
    wenyu_asset_pack_skill_text(entry),
  )
}

///|
fn wenyu_build_skill_text(entry : @moonbook.BookCatalogEntry) -> String {
  let module_name = wenyu_module_name(entry)
  [
    "---",
    "name: wenyu-build",
    "description: Turn a Wenyu Valley research book into implementation-grade software backlog, acceptance tests, and build decisions.",
    "---",
    "",
    "# Wenyu Build Skill: \{module_name}",
    "",
    "You are converting research into buildable software work. Do not produce another generic report.",
    "",
    "## Required Inputs",
    "",
    "- `raw/bootstrap/WENYU_VALLEY_PRD.md`",
    "- `raw/bootstrap/deep-report.md`",
    "- `raw/bootstrap/evidence-matrix.md`",
    "- `raw/bootstrap/marketing-brief.md`",
    "- `mounted-sources/MANIFEST.md`",
    "",
    "## Output Rules",
    "",
    "- Write `build/IMPLEMENTATION_BACKLOG.md` with epics, stories, concrete files, dependencies, and done criteria.",
    "- Write `build/ACCEPTANCE_TESTS.md` with testable UI/runtime behaviors.",
    "- Write `wiki/synthesis/\{entry.id}-build-plan.md` with durable rationale and evidence links.",
    "- Every build item must cite a PRD section, evidence row, or local source path.",
    "- Mark `codex-ready: yes` only when path, behavior, and validation command are all clear.",
    "",
    "## Concrete Example",
    "",
    "```md",
    "## Story: Show \{module_name} as a live district",
    "",
    "- Evidence: `raw/bootstrap/evidence-matrix.md#C3`, `mounted-sources/moontown/ui-rabbita-town-main.mbt`",
    "- Files: `/Users/kq/Workspace/moontown/ui/rabbita-town/main/main.mbt`, `/Users/kq/Workspace/moontown/ui/rabbita-town/styles.css`",
    "- Behavior: district tile displays current agent activity, health, and next action",
    "- Acceptance: UI build passes and the tile is visible in the town dashboard",
    "- codex-ready: yes",
    "```",
  ].join("\n")
}

///|
fn wenyu_code_patch_skill_text(entry : @moonbook.BookCatalogEntry) -> String {
  let module_name = wenyu_module_name(entry)
  [
    "---",
    "name: wenyu-code-patch",
    "description: Execute focused code changes for one Wenyu Valley module through Codex/OpenClaw while preserving Moontown/MoonBook/MoonClaw boundaries.",
    "---",
    "",
    "# Wenyu Code Patch Skill: \{module_name}",
    "",
    "This skill is for implementation. A successful result normally changes code.",
    "",
    "## Execution Rules",
    "",
    "- Prefer a small, reviewable code slice over a broad rewrite.",
    "- Use the backlog and evidence files before editing.",
    "- Keep responsibilities clean: Moontown orchestrates and projects; MoonBook stores durable book memory; MoonClaw/OpenClaw executes tasks.",
    "- If Codex ACP or write access is unavailable, write `build/CODE_BLOCKERS.md` with exact blocker details instead of pretending success.",
    "- If UI code changes, run the UI build.",
    "",
    "## Required Result Record",
    "",
    "Write `build/CODE_PATCH.md` containing:",
    "",
    "- changed files",
    "- user-facing behavior",
    "- boundary rationale",
    "- tests/build commands",
    "- residual risks",
    "",
    "## Concrete Example",
    "",
    "```md",
    "# Code Patch",
    "",
    "- Changed: `/Users/kq/Workspace/moontown/ui/rabbita-town/main/main.mbt`",
    "- Behavior: \{module_name} district now renders a live queue and health meter",
    "- Boundary: Moontown UI reads projected state; MoonBook remains source of book memory",
    "- Validation: `npm run build` in `ui/rabbita-town` passed",
    "- Risk: generated image assets are still prompt-only",
    "```",
  ].join("\n")
}

///|
fn wenyu_asset_pack_skill_text(entry : @moonbook.BookCatalogEntry) -> String {
  let module_name = wenyu_module_name(entry)
  [
    "---",
    "name: wenyu-asset-pack",
    "description: Produce module-specific image prompts, generated asset manifests, and projection notes for Wenyu Valley town districts.",
    "---",
    "",
    "# Wenyu Asset Pack Skill: \{module_name}",
    "",
    "Make this module visually distinct inside the town. Do not reuse generic cyber-city wording across modules.",
    "",
    "## Required Outputs",
    "",
    "- `build/ASSET_PROMPTS.md`: key art, icon, tile, resident/worker sprite, and background vignette prompts.",
    "- `build/ASSET_MANIFEST.md`: paths, dimensions, usage location, alt text, status, and generation notes.",
    "- Projection notes for how the module should appear in `ui/rabbita-town`.",
    "",
    "## Concrete Example",
    "",
    "```md",
    "## District Tile Prompt",
    "",
    "A warm civic AI innovation district for \{module_name}, clay-and-glass architectural model, visible tiny agent workers, public-service dashboard lights, Wenyu Valley signage, no generic neon cyberpunk, 16:9.",
    "",
    "## Manifest Row",
    "",
    "| Asset | Path | Size | Usage | Alt text | Status |",
    "| --- | --- | --- | --- | --- | --- |",
    "| District tile | `ui/rabbita-town/assets/wenyu-\{entry.id}-tile.png` | 1536x864 | map card | \{module_name} district with active AI workers | prompt-ready |",
    "```",
  ].join("\n")
}

///|
async fn preseed_wenyu_source_bundle(root : String, repo_root : String) -> Unit {
  let bundle_root = "\{root}/mounted-sources"
  write_text_file(
    "\{bundle_root}/MANIFEST.md",
    [
      "# Mounted Source Manifest", "", "This bundle is generated by Moontown when bootstrapping a Wenyu Valley lane.",
      "It gives isolated MoonBook/MoonClaw workers local, readable evidence without granting town-global filesystem authority.",
      "", "## Moontown", "", "- `moontown/ui-rabbita-town-main.mbt` from `ui/rabbita-town/main/main.mbt`",
      "- `moontown/ui-rabbita-town-styles.css` from `ui/rabbita-town/styles.css`",
      "- `moontown/roles-mayor.mbt` from `roles/mayor.mbt`", "- `moontown/goal-run.mbt` from `goal_run.mbt`",
      "- `moontown/goal-bootstrap.mbt` from `goal_bootstrap.mbt`", "- `moontown/scheduler-daemon.mbt` from `scheduler/daemon.mbt`",
      "- `moontown/moontown.mbt` from `moontown.mbt`", "- `moontown/adapters-moonbook-client.mbt` from `adapters/moonbook/client.mbt`",
      "- `moontown/adapters-moonclaw-client.mbt` from `adapters/moonclaw/client.mbt`",
      "", "## MoonBook", "", "- `moonbook/research-report-skill.md` from `../moonbook/seed/wiki/skills/research-report/SKILL.md`",
      "- `moonbook/wiki-ingest-skill.md` from `../moonbook/seed/wiki/skills/wiki-ingest/SKILL.md`",
      "- `moonbook/wiki-marketing-skill.md` from `../moonbook/seed/wiki/skills/wiki-marketing/SKILL.md`",
      "- `moonbook/wiki-ui-state-content.mbt` from `../moonbook/wiki/ui_state_content.mbt`",
      "- `moonbook/wiki-extensions-profiles.mbt` from `../moonbook/wiki/extensions_profiles.mbt`",
      "", "## MoonClaw", "", "- `moonclaw/provider-task-execution-skill.md` from `../moonclaw/skills/provider-task-execution/SKILL.md`",
      "- `moonclaw/research-report-writer-skill.md` from `../moonclaw/skills/research-report-writer/SKILL.md`",
      "- `moonclaw/job-provider-task.mbt` from `../moonclaw/job/provider_task.mbt`",
      "- `moonclaw/job-analysis-runner.mbt` from `../moonclaw/job/analysis_runner.mbt`",
      "", "## Research Rule", "", "Use these snapshots after web discovery to verify implementation readiness, ownership boundaries, and projection/runtime gaps.",
      "",
    ].join("\n"),
  )
  copy_source_snapshot(
    source="\{repo_root}/ui/rabbita-town/main/main.mbt",
    dest="\{bundle_root}/moontown/ui-rabbita-town-main.mbt",
  )
  copy_source_snapshot(
    source="\{repo_root}/ui/rabbita-town/styles.css",
    dest="\{bundle_root}/moontown/ui-rabbita-town-styles.css",
  )
  copy_source_snapshot(
    source="\{repo_root}/roles/mayor.mbt",
    dest="\{bundle_root}/moontown/roles-mayor.mbt",
  )
  copy_source_snapshot(
    source="\{repo_root}/goal_run.mbt",
    dest="\{bundle_root}/moontown/goal-run.mbt",
  )
  copy_source_snapshot(
    source="\{repo_root}/goal_bootstrap.mbt",
    dest="\{bundle_root}/moontown/goal-bootstrap.mbt",
  )
  copy_source_snapshot(
    source="\{repo_root}/scheduler/daemon.mbt",
    dest="\{bundle_root}/moontown/scheduler-daemon.mbt",
  )
  copy_source_snapshot(
    source="\{repo_root}/moontown.mbt",
    dest="\{bundle_root}/moontown/moontown.mbt",
  )
  copy_source_snapshot(
    source="\{repo_root}/adapters/moonbook/client.mbt",
    dest="\{bundle_root}/moontown/adapters-moonbook-client.mbt",
  )
  copy_source_snapshot(
    source="\{repo_root}/adapters/moonclaw/client.mbt",
    dest="\{bundle_root}/moontown/adapters-moonclaw-client.mbt",
  )
  copy_source_snapshot(
    source="\{repo_root}/../moonbook/seed/wiki/skills/research-report/SKILL.md",
    dest="\{bundle_root}/moonbook/research-report-skill.md",
  )
  copy_source_snapshot(
    source="\{repo_root}/../moonbook/seed/wiki/skills/wiki-ingest/SKILL.md",
    dest="\{bundle_root}/moonbook/wiki-ingest-skill.md",
  )
  copy_source_snapshot(
    source="\{repo_root}/../moonbook/seed/wiki/skills/wiki-marketing/SKILL.md",
    dest="\{bundle_root}/moonbook/wiki-marketing-skill.md",
  )
  copy_source_snapshot(
    source="\{repo_root}/../moonbook/wiki/ui_state_content.mbt",
    dest="\{bundle_root}/moonbook/wiki-ui-state-content.mbt",
  )
  copy_source_snapshot(
    source="\{repo_root}/../moonbook/wiki/extensions_profiles.mbt",
    dest="\{bundle_root}/moonbook/wiki-extensions-profiles.mbt",
  )
  copy_source_snapshot(
    source="\{repo_root}/../moonclaw/skills/provider-task-execution/SKILL.md",
    dest="\{bundle_root}/moonclaw/provider-task-execution-skill.md",
  )
  copy_source_snapshot(
    source="\{repo_root}/../moonclaw/skills/research-report-writer/SKILL.md",
    dest="\{bundle_root}/moonclaw/research-report-writer-skill.md",
  )
  copy_source_snapshot(
    source="\{repo_root}/../moonclaw/job/provider_task.mbt",
    dest="\{bundle_root}/moonclaw/job-provider-task.mbt",
  )
  copy_source_snapshot(
    source="\{repo_root}/../moonclaw/job/analysis_runner.mbt",
    dest="\{bundle_root}/moonclaw/job-analysis-runner.mbt",
  )
}

///|
async fn copy_source_snapshot(source~ : String, dest~ : String) -> Unit {
  match read_optional_text(source) {
    Some(text) =>
      write_text_file(
        dest,
        ["---", "source: \{source}", "generated_by: moontown", "---", "", text].join(
          "\n",
        ),
      )
    None => ()
  }
}

///|
fn moontown_repo_root() -> String {
  match @env.current_dir() {
    Some(dir) => dir
    None => "."
  }
}

///|
fn wenyu_module_name(entry : @moonbook.BookCatalogEntry) -> String {
  let prefix = "Wenyu Valley / "
  if entry.name.has_prefix(prefix) {
    entry.name.replace(old=prefix, new="")
  } else {
    entry.name
  }
}

///|
async fn research_bootstrap_plan(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
  summary : @moonbook.BookStateSummary,
  tasks : Array[@moonbook.BookTask],
  task_limit : Int,
) -> ResearchBootstrapPlan {
  let ordered = prioritized_tasks(tasks, goal)
  let quality_gaps = research_quality_gaps(entry)
  let bootstrap_active = research_goal_needs_bootstrap(
    entry,
    goal,
    summary,
    quality_gaps~,
  )
  if !bootstrap_active {
    return { tasks: ordered, task_limit, bootstrap_active: false }
  }
  if !quality_gaps.is_empty() {
    archive_research_bootstrap_for_repair(entry, quality_gaps)
  }
  let bootstrap_task = bootstrap_ingest_task(entry, goal)
  let planned = [
    bootstrap_task,
    ..ordered.filter(fn(task) { task.id != bootstrap_task.id }),
  ]
  let effective_limit = research_bootstrap_task_limit()
  { tasks: planned, task_limit: effective_limit, bootstrap_active: true }
}

///|
fn research_bootstrap_task_limit() -> Int {
  1
}

///|
async fn research_goal_needs_bootstrap(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
  summary : @moonbook.BookStateSummary,
  quality_gaps? : Array[String] = [],
) -> Bool {
  if !is_research_goal(goal) {
    return false
  }
  let no_substantive_tree = !has_substantive_research_tree(entry)
  let missing_domain_coverage = summary.entity_count == 0 &&
    summary.concept_count == 0
  let no_durable_sources = summary.verified_source_count == 0
  let no_durable_evidence = summary.evidence_count == 0
  let quality_repair_needed = !quality_gaps.is_empty()
  no_substantive_tree ||
  missing_domain_coverage ||
  no_durable_sources ||
  no_durable_evidence ||
  quality_repair_needed
}

///|
async fn archive_research_bootstrap_for_repair(
  entry : @moonbook.BookCatalogEntry,
  quality_gaps : Array[String],
) -> Unit {
  guard entry.id.has_prefix("research-") else { return }
  let root = @moonbook.workspace_root(entry)
  let raw_root = "\{root}/raw/bootstrap"
  let archive_id = quality_gaps
    .join("|")
    .hash()
    .to_string()
    .trim(chars="-")
    .to_string()
  let archive_dir = "\{raw_root}/archive/quality-repair-\{archive_id}"
  ignore_checked_command("mkdir", ["-p", archive_dir])
  for relative in research_bootstrap_repair_artifacts() {
    let path = "\{root}/\{relative}"
    if !@fs.exists(path) {
      continue
    }
    let archived = "\{archive_dir}/\{path_basename(relative)}"
    ignore_checked_command("cp", [path, archived])
    ignore_checked_command("rm", ["-f", path])
  }
  write_text_file(
    "\{raw_root}/QUALITY_REPAIR.md",
    [
      "# Quality Repair Trigger",
      "",
      "Moontown archived stale generated bootstrap artifacts before relaunching research because the quality gate found these gaps:",
      "",
      ..quality_gaps.map(fn(gap) { "- \{gap}" }),
      "",
      "The next bootstrap run must regenerate the raw research envelope from the current `RESEARCH_REQUEST.md`, `SOURCE_HINTS.md`, and loaded skills instead of completing from stale artifacts.",
    ].join("\n"),
  )
}

///|
async fn ignore_checked_command(command : String, args : Array[String]) -> Unit {
  let completed = @integration.run_checked(command, args) catch { _ => return }
  ignore(completed)
}

///|
fn research_bootstrap_repair_artifacts() -> Array[String] {
  [
    "raw/bootstrap/research-question.md", "raw/bootstrap/search-log.md", "raw/bootstrap/source-screen.md",
    "raw/bootstrap/local-sources.md", "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/synthesis-brief.md",
    "raw/bootstrap/deep-report.md", "raw/bootstrap/marketing-brief.md",
  ]
}

///|
fn path_basename(path : String) -> String {
  let parts = path.split("/").to_array()
  match parts.get(parts.length() - 1) {
    Some(part) => part.to_string()
    None => path
  }
}

///|
fn bootstrap_ingest_task(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
) -> @moonbook.BookTask {
  let normalized_goal = goal.trim().to_string()
  let prompt = if is_wenyu_valley_goal(normalized_goal) {
    "Bootstrap this Wenyu Valley module before implementation. Use `../../../docs/WENYU_VALLEY_PRD.md` as the primary contract from this book workspace, run web search before local file search for comparable civic/AI innovation town patterns, then inspect local project files. Produce lane-specific raw bootstrap artifacts, a claim-level evidence matrix, module entities/concepts, implementation tasks, acceptance criteria, risk list, and a marketing/product brief. The result must be specific to this Wenyu module and must not collapse all Wenyu modules into one generic page."
  } else {
    "Bootstrap this book before answering the research question. Work as a researcher: formulate the lane-specific question, run web search before local file search, fetch and screen authoritative sources, extract a claim-level evidence matrix, inspect local files only after web discovery, write a skill-authored marketing brief, then materialize verified source, entity, concept, and synthesis pages. The result must be specific to this book lane, not generic MoonBook copy, and every major claim must cite a source ID or local path."
  }
  @moonbook.BookTask::new(
    id="goal-\{entry.id}-research-bootstrap-ingest",
    goal=Some(normalized_goal),
    title=if is_wenyu_valley_goal(normalized_goal) {
      "Bootstrap Wenyu Valley module coverage"
    } else {
      "Bootstrap verified research coverage"
    },
    kind="ingest",
    prompt~,
    priority=100,
    requires_review=true,
    target_pages=[
      "raw/bootstrap/research-question.md", "raw/bootstrap/search-log.md", "raw/bootstrap/source-screen.md",
      "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/local-sources.md", "raw/bootstrap/synthesis-brief.md",
      "raw/bootstrap/marketing-brief.md", "wiki/sources", "wiki/entities", "wiki/concepts",
      "wiki/synthesis", "wiki/index.md", "wiki/log.md",
    ],
    required_role=Some(@core.WorkerRole::Harness),
  )
}

///|
fn is_research_goal(goal : String) -> Bool {
  let notes = goal.to_lower()
  notes.contains("research") ||
  notes.contains("moontown") ||
  notes.contains("moonbook") ||
  notes.contains("moonclaw") ||
  is_wenyu_valley_goal(goal)
}

///|
fn is_wenyu_valley_goal(goal : String) -> Bool {
  let notes = goal.to_lower()
  notes.contains("wenyu") ||
  notes.contains("wenyu valley") ||
  (notes.contains("innovation town") && notes.contains("prd"))
}

///|
async fn has_substantive_research_tree(
  entry : @moonbook.BookCatalogEntry,
) -> Bool {
  let root = @moonbook.workspace_root(entry)
  let paths = [
    "\{root}/wiki/entities",
    "\{root}/wiki/concepts",
    "\{root}/wiki/sources",
    "\{root}/wiki/queries",
  ]
  for path in paths {
    let listed = @integration.run_checked("find", [path, "-type", "f"]) catch {
      _ => continue
    }
    if !listed.stdout.trim().is_blank() {
      return true
    }
  }
  false
}

///|
fn task_priority_score(task : @moonbook.BookTask, research_goal : Bool) -> Int {
  let kind_score = match task.kind {
    "analysis" => 60
    "synthesis" => 50
    "planning" => if research_goal { 15 } else { 40 }
    "review" => if research_goal { 10 } else { 45 }
    "ingest" | "ingest-followup" => if research_goal { 35 } else { 25 }
    _ => 20
  }
  kind_score + task.priority
}
