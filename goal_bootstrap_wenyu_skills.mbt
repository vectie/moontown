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
    @skill_quality.exploration_quality_contract_section(),
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
    @skill_quality.exploration_quality_contract_section(),
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
    @skill_quality.exploration_quality_contract_section(),
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
