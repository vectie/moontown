///|
pub fn wenyu_implementation_backlog_prompt(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  repo_root : String,
) -> String {
  let module_name = wenyu_module_name(entry)
  [
    "Convert the researched Wenyu Valley `\{module_name}` book into a software-development backlog.",
    "",
    "This is a build task, not another research report. Use the existing book evidence first:",
    "- `raw/bootstrap/deep-report.md`",
    "- `raw/bootstrap/evidence-matrix.md`",
    "- `raw/bootstrap/marketing-brief.md`",
    "- `raw/bootstrap/local-sources.md`",
    "- `raw/bootstrap/WENYU_VALLEY_PRD.md`",
    "- `mounted-sources/MANIFEST.md`",
    "",
    "Then inspect the live repository at `\{repo_root}` only where needed.",
    "",
    "Required outputs:",
    "- `build/IMPLEMENTATION_BACKLOG.md`: epics, user stories, implementation files, dependencies, risks, and done criteria.",
    "- `build/ACCEPTANCE_TESTS.md`: observable checks that prove this module works in the Wenyu Valley town UI/runtime.",
    "- `wiki/synthesis/\{entry.id}-build-plan.md`: durable book synthesis linking claims to build decisions.",
    "",
    "Quality bar:",
    "- Every backlog item must cite at least one evidence row, PRD section, or local source path.",
    "- Include concrete code areas, not generic product text.",
    "- Mark work as `codex-ready` only if the file paths, expected behavior, and tests are clear.",
    "",
    "Town objective: \{objective}",
  ].join("\n")
}

///|
pub fn wenyu_code_patch_prompt(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  repo_root : String,
) -> String {
  let module_name = wenyu_module_name(entry)
  [
    "Implement a real code slice for Wenyu Valley `\{module_name}`.",
    "",
    "Use MoonClaw/OpenClaw Codex ACP if available. Do not satisfy this task by writing only markdown. The expected result is a code patch in `\{repo_root}` plus a concise book record.",
    "",
    "Read first:",
    "- `build/IMPLEMENTATION_BACKLOG.md` if present",
    "- `raw/bootstrap/deep-report.md`",
    "- `raw/bootstrap/evidence-matrix.md`",
    "- `raw/bootstrap/WENYU_VALLEY_PRD.md`",
    "- `mounted-sources/moontown/ui-rabbita-town-main.mbt`",
    "- `mounted-sources/moontown/ui-rabbita-town-styles.css`",
    "",
    "Implementation scope:",
    "- Prefer focused, reviewable changes under `ui/rabbita-town`, runtime projection, or Wenyu-specific state models.",
    "- Preserve Moontown/MoonBook/MoonClaw boundaries. Moontown owns orchestration and UI projection; MoonBook owns book memory and generated pages; MoonClaw/OpenClaw owns execution.",
    "- If the task cannot safely patch code, write `build/CODE_BLOCKERS.md` with exact missing input/tooling and create no fake completion.",
    "",
    "Required outputs:",
    "- Real repository changes when feasible.",
    "- `build/CODE_PATCH.md` with changed files, behavior, architecture boundary, and residual risk.",
    "- `build/TEST_RESULTS.md` with commands run and results.",
    "",
    "Validation:",
    "- Run the narrowest relevant build/test command.",
    "- If UI changes are made, build the UI before completion.",
    "",
    "Town objective: \{objective}",
  ].join("\n")
}

///|
pub fn wenyu_asset_pack_prompt(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  repo_root : String,
) -> String {
  let module_name = wenyu_module_name(entry)
  [
    "Create the visual/projection asset pack for Wenyu Valley `\{module_name}`.",
    "",
    "Use image generation through Codex image tools when available, but keep the task useful if image generation is unavailable by writing production-ready prompts and a manifest.",
    "",
    "Read first:",
    "- `raw/bootstrap/deep-report.md`",
    "- `raw/bootstrap/marketing-brief.md`",
    "- `raw/bootstrap/WENYU_VALLEY_PRD.md`",
    "- `mounted-sources/moontown/ui-rabbita-town-styles.css`",
    "- live UI assets under `\{repo_root}/ui/rabbita-town`",
    "",
    "Required outputs:",
    "- `build/ASSET_PROMPTS.md`: exact prompts for module key art, icon, tile, resident/worker sprite, and background vignette.",
    "- `build/ASSET_MANIFEST.md`: intended paths, dimensions, usage locations, accessibility alt text, and generation status.",
    "- Update generated projection notes so the module can appear as a real town district rather than a generic markdown card.",
    "",
    "Quality bar:",
    "- Asset language must match the Wenyu Valley visual world from the PRD and current gamified town UI.",
    "- Do not reuse one generic image description for all modules.",
    "- If images are generated, record absolute file paths and usage instructions.",
    "",
    "Town objective: \{objective}",
  ].join("\n")
}
