///|
pub fn wenyu_build_skill_text(entry : @moonbook.BookCatalogEntry) -> String {
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
    "- Files: `/Users/kq/Workspace/moontown/src/ui/rabbita-town/main/main.mbt`, `/Users/kq/Workspace/moontown/src/ui/rabbita-town/styles.css`",
    "- Behavior: district tile displays current agent activity, health, and next action",
    "- Acceptance: UI build passes and the tile is visible in the town dashboard",
    "- codex-ready: yes",
    "```",
  ].join("\n")
}

///|
pub fn wenyu_code_patch_skill_text(
  entry : @moonbook.BookCatalogEntry,
) -> String {
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
    "- Read `build/IMPLEMENTATION_BACKLOG.md` and choose one small codex-ready slice.",
    "- Patch the relevant repository files directly when the task grants workspace write access.",
    "- Keep Moontown as control plane, MoonBook as workspace/memory, MoonClaw as worker runtime.",
    "- Do not move single-agent editing into Moontown; leave complex personal workspace editing to Moondesk.",
    "- Run the narrowest validation command that proves the slice works.",
    "- If code cannot be changed, write `build/BLOCKED_CODE_PATCH.md` with exact missing permission or missing file.",
    "",
    @skill_quality.exploration_quality_contract_section(),
    "",
    "## Required Output Contract",
    "",
    "Return a JSON object with:",
    "",
    "```json",
    "{\"changed_files\":[\"path\"],\"validation\":[\"command\"],\"summary\":\"what changed\",\"blocked\":false}",
    "```",
    "",
    "## Concrete Example",
    "",
    "```json",
    "{\"changed_files\":[\"src/ui/rabbita-town/main/main.mbt\"],\"validation\":[\"moon check --no-render\"],\"summary\":\"Added \{module_name} district projection to the viewport model.\",\"blocked\":false}",
    "```",
  ].join("\n")
}

///|
pub fn wenyu_asset_pack_skill_text(
  entry : @moonbook.BookCatalogEntry,
) -> String {
  let module_name = wenyu_module_name(entry)
  [
    "---",
    "name: wenyu-asset-pack",
    "description: Produce reusable visual prompts and projection-ready asset manifests for one Wenyu Valley module.",
    "---",
    "",
    "# Wenyu Asset Pack Skill: \{module_name}",
    "",
    "You are preparing visual assets and UI projection instructions, not merely describing an idea.",
    "",
    "## Asset Rules",
    "",
    "- Use a coherent Wenyu Valley visual language: clean civic-tech, spring valley, river, modular buildings, readable map symbols.",
    "- Produce prompts that can generate transparent or isolated assets suitable for tile-map composition.",
    "- Specify scale, tile footprint, anchor point, orientation, day/night variants, and hover/click states.",
    "- Connect every asset to its civic function and the MoonBook/MoonClaw workflow it represents.",
    "- Write `build/ASSET_PROMPTS.md` and `build/ASSET_MANIFEST.md`.",
    "",
    @skill_quality.exploration_quality_contract_section(),
    "",
    "## Concrete Example",
    "",
    "```md",
    "### Asset: \{module_name} pavilion",
    "",
    "- Prompt: white tech pavilion, isometric 2.5D, glass roof, civic AI town, transparent background, spring valley palette",
    "- Footprint: 4x3 tiles",
    "- Anchor: south-center entrance tile",
    "- States: idle, active salon, blocked review, completed output",
    "- Runtime meaning: agents enter when the \{module_name} book has an active service task",
    "```",
  ].join("\n")
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
