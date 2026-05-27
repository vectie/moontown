///|
fn is_wenyu_book(entry : @moonbook.BookCatalogEntry) -> Bool {
  entry.id.has_prefix("wenyu-")
}

///|
async fn wenyu_book_ready_for_build(entry : @moonbook.BookCatalogEntry) -> Bool {
  if !is_wenyu_book(entry) {
    return false
  }
  let root = @moonbook.workspace_root(entry)
  let required = [
    "raw/bootstrap/deep-report.md", "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/marketing-brief.md",
    "raw/bootstrap/local-sources.md", "mounted-sources/MANIFEST.md",
  ]
  for path in required {
    if !@fs.exists("\{root}/\{path}") {
      return false
    }
  }
  true
}

///|
fn wenyu_build_task_limit(task_limit : Int) -> Int {
  if task_limit < 4 {
    4
  } else {
    task_limit
  }
}

///|
fn wenyu_build_plan(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  task_limit : Int,
) -> ResearchBootstrapPlan {
  {
    tasks: wenyu_build_tasks(entry, objective),
    task_limit: wenyu_build_task_limit(task_limit),
    bootstrap_active: false,
  }
}

///|
fn wenyu_build_tasks(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
) -> Array[@moonbook.BookTask] {
  let module_name = wenyu_module_name(entry)
  let repo_root = moontown_repo_root()
  let build_tasks = [
    @moonbook.BookTask::new(
      id="goal-\{entry.id}-implementation-backlog",
      goal=Some(objective),
      title="Compile implementation backlog for \{module_name}",
      kind="implementation-backlog",
      prompt=wenyu_implementation_backlog_prompt(entry, objective, repo_root),
      priority=120,
      requires_review=true,
      target_pages=[
        "build/IMPLEMENTATION_BACKLOG.md",
        "build/ACCEPTANCE_TESTS.md",
        "wiki/synthesis/\{entry.id}-build-plan.md",
      ],
      required_role=Some(@core.WorkerRole::Planner),
    ),
    @moonbook.BookTask::new(
      id="goal-\{entry.id}-code-patch",
      goal=Some(objective),
      title="Implement code slice for \{module_name}",
      kind="code-patch",
      prompt=wenyu_code_patch_prompt(entry, objective, repo_root),
      priority=115,
      requires_review=true,
      target_pages=[
        "build/CODE_PATCH.md", "build/TEST_RESULTS.md", "repo:/Users/kq/Workspace/moontown",
      ],
      required_role=Some(@core.WorkerRole::Harness),
    ),
    @moonbook.BookTask::new(
      id="goal-\{entry.id}-asset-pack",
      goal=Some(objective),
      title="Generate asset and projection pack for \{module_name}",
      kind="image-asset",
      prompt=wenyu_asset_pack_prompt(entry, objective, repo_root),
      priority=110,
      requires_review=true,
      target_pages=[
        "build/ASSET_PROMPTS.md", "build/ASSET_MANIFEST.md", "book/site/generated/index.html",
      ],
      required_role=Some(@core.WorkerRole::Specialist),
    ),
  ]
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) =>
      [@civic.wenyu_civic_service_task(service, objective), ..build_tasks]
    None => build_tasks
  }
}

///|
fn wenyu_civic_service_plan(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  tasks : Array[@moonbook.BookTask],
  task_limit : Int,
) -> ResearchBootstrapPlan {
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) => {
      let service_task = @civic.wenyu_civic_service_task(service, objective)
      let ordered = prioritized_tasks(tasks, objective)
      let merged = [service_task]
      for task in ordered {
        if task.id != service_task.id &&
          task.kind != "research-bootstrap-ingest" {
          merged.push(task)
        }
      }
      {
        tasks: merged,
        task_limit: if task_limit < 1 {
          1
        } else {
          task_limit
        },
        bootstrap_active: false,
      }
    }
    None =>
      {
        tasks: prioritized_tasks(tasks, objective),
        task_limit: if task_limit < 1 {
          1
        } else {
          task_limit
        },
        bootstrap_active: false,
      }
  }
}

///|
async fn complete_wenyu_build_artifacts_if_needed(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  execution : @core.TaskExecutionRecord,
) -> @core.TaskExecutionRecord {
  if !is_wenyu_book(entry) {
    return execution
  }
  match task.kind {
    "implementation-backlog" => {
      write_wenyu_implementation_backlog(entry, task)
      copy_execution_with(
        execution,
        status=@core.TaskExecutionStatus::Completed,
        summary="Moontown materialized implementation backlog and acceptance tests for \{entry.id} after the Wenyu build controller returned no writable artifacts.",
      )
    }
    "code-patch" => {
      if execution.status is @core.TaskExecutionStatus::Completed {
        return execution
      }
      write_wenyu_code_patch_record(entry, task, execution)
      copy_execution_with(
        execution,
        status=@core.TaskExecutionStatus::ReviewQueued,
        summary="Moontown materialized a code-patch handoff and blocker record for \{entry.id}; Codex/OpenClaw execution did not produce a repository patch in this run.",
      )
    }
    "image-asset" => {
      write_wenyu_asset_pack_record(entry, task)
      copy_execution_with(
        execution,
        status=@core.TaskExecutionStatus::Completed,
        summary="Moontown materialized module-specific asset prompts and an asset manifest for \{entry.id} after the Wenyu build controller returned no writable artifacts.",
      )
    }
    _ => execution
  }
}

///|
async fn write_wenyu_implementation_backlog(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
) -> Unit {
  let root = @moonbook.workspace_root(entry)
  let module_name = wenyu_module_name(entry)
  write_text_file(
    "\{root}/build/IMPLEMENTATION_BACKLOG.md",
    [
      "# \{module_name} Implementation Backlog",
      "",
      "- Book: `\{entry.id}`",
      "- Task: `\{task.id}`",
      "- Status: codex-ready backlog generated by Moontown build fallback",
      "",
      "## Evidence Inputs",
      "",
      "- `raw/bootstrap/WENYU_VALLEY_PRD.md`",
      "- `raw/bootstrap/deep-report.md`",
      "- `raw/bootstrap/evidence-matrix.md`",
      "- `raw/bootstrap/marketing-brief.md`",
      "- `mounted-sources/MANIFEST.md`",
      "",
      "## Epic 1: Live District Projection",
      "",
      "- Story: render this module as a distinct live Wenyu Valley district in the town UI.",
      "- Files: `/Users/kq/Workspace/moontown/ui/rabbita-town/main/main.mbt`, `/Users/kq/Workspace/moontown/ui/rabbita-town/styles.css`.",
      "- Done: district card shows module name, worker state, queue pressure, health, and next action.",
      "- Evidence: PRD copy, deep report, mounted UI sources.",
      "- codex-ready: yes.",
      "",
      "## Epic 2: Book-to-UI Projection",
      "",
      "- Story: project this book's build/readiness state into a UI-readable town state object.",
      "- Files: `/Users/kq/Workspace/moontown/town_synthesis.mbt`, `/Users/kq/Workspace/moontown/moontown.mbt`.",
      "- Done: generated dashboard can distinguish research, build, blocked, and implemented states.",
      "- Evidence: `mounted-sources/moontown/town-synthesis.mbt` when present, current town synthesis output.",
      "- codex-ready: yes.",
      "",
      "## Epic 3: Review And Recovery Loop",
      "",
      "- Story: failed code or asset execution must become visible as a recoverable town action, not silent markdown.",
      "- Files: `/Users/kq/Workspace/moontown/goal_supervision.mbt`, `/Users/kq/Workspace/moontown/health`.",
      "- Done: missing code patch, read-only ACP, or missing image generation produces a clear review/backlog event.",
      "- Evidence: MoonClaw run events and `build/CODE_BLOCKERS.md`.",
      "- codex-ready: yes.",
    ].join("\n"),
  )
  write_text_file(
    "\{root}/build/ACCEPTANCE_TESTS.md",
    [
      "# \{module_name} Acceptance Tests",
      "",
      "1. Run the Wenyu goal and confirm this book receives `implementation-backlog`, `code-patch`, and `image-asset` tasks.",
      "2. Confirm `moonclaw.jobs.json` contains `wenyu_build_controller`.",
      "3. Confirm the town dashboard shows the module as a build-stage district, not only a bootstrap research card.",
      "4. If UI files change, run the Rabbita town UI build.",
      "5. Confirm `build/CODE_PATCH.md` or `build/CODE_BLOCKERS.md` exists after the code task.",
      "6. Confirm `build/ASSET_PROMPTS.md` and `build/ASSET_MANIFEST.md` exist after the asset task.",
    ].join("\n"),
  )
  write_text_file(
    "\{root}/wiki/synthesis/\{entry.id}-build-plan.md",
    [
      "# \{module_name} Build Plan",
      "",
      "This page links Wenyu Valley research output to implementation-ready work.",
      "",
      "## Current Build Decision",
      "",
      "Moontown may dispatch this module to MoonClaw/OpenClaw for implementation, but if the runtime lacks writable execution it must still materialize a reviewable backlog and blockers.",
      "",
      "## Primary Artifacts",
      "",
      "- `build/IMPLEMENTATION_BACKLOG.md`",
      "- `build/ACCEPTANCE_TESTS.md`",
      "- `build/CODE_PATCH.md` or `build/CODE_BLOCKERS.md`",
      "- `build/ASSET_PROMPTS.md`",
      "- `build/ASSET_MANIFEST.md`",
    ].join("\n"),
  )
}

///|
async fn write_wenyu_code_patch_record(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  let root = @moonbook.workspace_root(entry)
  let module_name = wenyu_module_name(entry)
  write_text_file(
    "\{root}/build/CODE_PATCH.md",
    [
      "# \{module_name} Code Patch Handoff",
      "",
      "- Task: `\{task.id}`",
      "- Target repository: `/Users/kq/Workspace/moontown`",
      "- Status: blocked before repository patch",
      "",
      "## Intended Patch",
      "",
      "- Add or update Wenyu district projection in `ui/rabbita-town`.",
      "- Surface this module's build/readiness state in the live town dashboard.",
      "- Preserve Moontown as orchestration/UI, MoonBook as memory/wiki, and MoonClaw/OpenClaw as executor.",
      "",
      "## Validation To Run After Patch",
      "",
      "- `/Users/kq/.moon/bin/moon test`",
      "- `/Users/kq/.moon/bin/moon check`",
      "- UI build command for `ui/rabbita-town` if UI files change.",
    ].join("\n"),
  )
  write_text_file(
    "\{root}/build/CODE_BLOCKERS.md",
    [
      "# \{module_name} Code Execution Blockers",
      "",
      "The Wenyu build controller did not produce a repository patch in this run.",
      "",
      "## Runtime Summary",
      "",
      execution.summary,
      "",
      "## Required Fix",
      "",
      "- Configure the MoonClaw/OpenClaw Codex ACP target with write access to `/Users/kq/Workspace/moontown`.",
      "- Dispatch code-patch tasks to that ACP target instead of a read-only or book-only analysis runner.",
      "- Rerun this task after the target can edit files and run validation.",
    ].join("\n"),
  )
  write_text_file(
    "\{root}/build/TEST_RESULTS.md",
    [
      "# \{module_name} Test Results",
      "",
      "- Code patch status: blocked before repository edit.",
      "- Tests run by this fallback: none.",
      "- Required next validation: run MoonBit tests/checks and UI build after Codex ACP applies the patch.",
    ].join("\n"),
  )
}

///|
async fn write_wenyu_asset_pack_record(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
) -> Unit {
  let root = @moonbook.workspace_root(entry)
  let module_name = wenyu_module_name(entry)
  write_text_file(
    "\{root}/build/ASSET_PROMPTS.md",
    [
      "# \{module_name} Asset Prompts",
      "",
      "- Task: `\{task.id}`",
      "",
      "## District Tile",
      "",
      "A warm civic AI innovation district for \{module_name}, Wenyu Valley town map style, clay-and-glass miniature architecture, visible tiny AI workers, public-service dashboard lights, approachable student innovation atmosphere, no generic neon cyberpunk, 16:9.",
      "",
      "## Icon",
      "",
      "Simple readable icon for \{module_name}, civic innovation town visual language, rounded geometry, warm daylight palette, transparent background.",
      "",
      "## Resident Or Worker Sprite",
      "",
      "Small friendly AI worker sprite for \{module_name}, isometric town dashboard style, clear silhouette, visible task tool, transparent background.",
      "",
      "## Background Vignette",
      "",
      "Soft Wenyu Valley background vignette for \{module_name}, town district atmosphere, layered paper-map depth, gentle motion-ready shapes.",
    ].join("\n"),
  )
  write_text_file(
    "\{root}/build/ASSET_MANIFEST.md",
    [
      "# \{module_name} Asset Manifest",
      "",
      "| Asset | Intended Path | Size | Usage | Alt Text | Status |",
      "| --- | --- | --- | --- | --- | --- |",
      "| District tile | `ui/rabbita-town/assets/\{entry.id}-tile.png` | 1536x864 | town district card | \{module_name} district with visible AI workers | prompt-ready |",
      "| Icon | `ui/rabbita-town/assets/\{entry.id}-icon.png` | 512x512 | map marker and panel heading | \{module_name} icon | prompt-ready |",
      "| Worker sprite | `ui/rabbita-town/assets/\{entry.id}-worker.png` | 768x768 | live worker layer | AI worker for \{module_name} | prompt-ready |",
      "| Background vignette | `ui/rabbita-town/assets/\{entry.id}-vignette.png` | 1536x864 | district background | Wenyu Valley \{module_name} background | prompt-ready |",
    ].join("\n"),
  )
}

///|
fn wenyu_implementation_backlog_prompt(
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
fn wenyu_code_patch_prompt(
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
fn wenyu_asset_pack_prompt(
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
