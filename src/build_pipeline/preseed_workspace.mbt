///|
pub async fn preseed_wenyu_goal_inputs(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  repo_root : String,
) -> Unit {
  let root = @moonbook.workspace_root(entry)
  let prd_path = "\{repo_root}/docs/WENYU_VALLEY_PRD.md"
  let vision_path = "\{repo_root}/docs/project/wenyu.md"
  copy_optional_bootstrap_text(
    source=prd_path,
    dest="\{root}/raw/bootstrap/WENYU_VALLEY_PRD.md",
  )
  copy_optional_bootstrap_text(
    source=vision_path,
    dest="\{root}/raw/bootstrap/WENYU_VISION.md",
  )
  preseed_wenyu_source_bundle(root, repo_root)
  @book_templates.write_wenyu_build_skills(root, entry)
  @civic_runtime.write_wenyu_civic_workspace_seed(entry, objective)
  ensure_wenyu_build_moonclaw_profile(root)
  ensure_wenyu_codex_acp_target(root)
  write_wenyu_research_request(root, entry, objective)
  write_wenyu_source_hints(root, prd_path, vision_path, repo_root)
}

///|
async fn copy_optional_bootstrap_text(source~ : String, dest~ : String) -> Unit {
  match @support.read_optional_text(source) {
    Some(text) => @support.write_text_file(dest, text)
    None => ()
  }
}

///|
async fn write_wenyu_research_request(
  root : String,
  entry : @moonbook.BookCatalogEntry,
  objective : String,
) -> Unit {
  let module_name = wenyu_module_name(entry)
  @support.write_text_file(
    "\{root}/raw/bootstrap/RESEARCH_REQUEST.md",
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
}

///|
async fn write_wenyu_source_hints(
  root : String,
  prd_path : String,
  vision_path : String,
  repo_root : String,
) -> Unit {
  @support.write_text_file(
    "\{root}/raw/bootstrap/SOURCE_HINTS.md",
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
      "- `../../../docs/project/wenyu.md`: original user-facing vision/reference file when present.",
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
      "- `mounted-sources/moontown/adapters-moonclaw-import.mbt`: MoonClaw execution adapter snapshot.",
      "- `mounted-sources/moonbook/research-report-skill.md`: MoonBook deep research report skill snapshot.",
      "- `mounted-sources/moonbook/wiki-ingest-skill.md`: MoonBook wiki ingest skill snapshot.",
      "- `mounted-sources/moonbook/wiki-marketing-skill.md`: MoonBook marketing projection skill snapshot.",
      "- `mounted-sources/moonbook/wiki-ui-state-content.mbt`: MoonBook generated-site content/projection snapshot.",
      "- `mounted-sources/moonbook/wiki-extensions-profiles.mbt`: MoonBook extension/profile routing snapshot.",
      "- `mounted-sources/moonclaw/provider-task-execution-skill.md`: MoonClaw provider task execution skill snapshot.",
      "- `mounted-sources/moonclaw/research-report-writer-skill.md`: MoonClaw report-writing skill snapshot.",
      "- `mounted-sources/moonclaw/job-provider-task.mbt`: MoonClaw provider task runtime snapshot.",
      "- `mounted-sources/moonclaw/job-analysis-runner.mbt`: MoonClaw analysis runner snapshot.",
      "- `\{repo_root}/src/ui/rabbita-town/main/main.mbt`: gamified town UI implementation.",
      "- `\{repo_root}/src/ui/rabbita-town/styles.css`: gamified town visual system.",
      "- `\{repo_root}/src/roles/mayor.mbt`: mayor decomposition and strategic routing.",
      "- `\{repo_root}/src/town_runtime/goal_run.mbt`: town goal launch and book orchestration.",
      "- `\{repo_root}/src/town_runtime/goal_bootstrap.mbt`: bootstrap-first routing for research/build lanes.",
      "- `\{repo_root}/src/scheduler/daemon.mbt`: daemon scheduling and supervision primitives.",
      "- `\{repo_root}/src/adapters/moonbook/client.mbt`: MoonBook workspace/task/projection adapter.",
      "- `\{repo_root}/src/adapters/moonclaw/import.mbt`: MoonClaw execution adapter.",
      "- `../../../src/ui/rabbita-town/main/main.mbt`: gamified town UI implementation.",
      "- `../../../src/ui/rabbita-town/styles.css`: gamified town visual system.",
      "- `../../../src/roles/mayor.mbt`: mayor decomposition and strategic routing.",
      "- `../../../src/town_runtime/goal_run.mbt`: town goal launch and book orchestration.",
      "- `../../../src/town_runtime/goal_bootstrap.mbt`: bootstrap-first routing for research/build lanes.",
      "- `../../../src/scheduler/daemon.mbt`: daemon scheduling and supervision primitives.",
      "- `../../../src/adapters/moonbook/client.mbt`: MoonBook workspace/task/projection adapter.",
      "- `../../../src/adapters/moonclaw/import.mbt`: MoonClaw execution adapter.",
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
