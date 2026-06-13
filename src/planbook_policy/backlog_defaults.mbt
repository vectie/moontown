///|
pub fn default_backlog_items(
  created_at_ms : UInt64,
) -> Array[PlanbookImplementationBacklogItem] {
  [
    {
      id: "live-change-log-projection",
      title: "Project live change history into PlanBook and operator UI state",
      owner: "moontown+planbook",
      priority: 10,
      status: "open",
      source_plan: "docs/PLANBOOK.md",
      rationale: "The town must explain what changed over time, not only what is true now.",
      target_files: [
        "src/planbook_runtime/planbook_autonomy.mbt", "src/planbook_runtime/planbook.mbt",
        "src/live_autonomy_runtime/live_autonomy.mbt", "src/ui/rabbita-town/main/main.mbt",
        "docs/PLANBOOK.md",
      ],
      acceptance: [
        "PlanBook workspace has a durable change log", "Generated MoonBook UI state links to recent change history",
        "Operator can inspect what changed without reading raw daemon logs",
      ],
      validation: [
        "moon check --no-render", "moon test planbook_autonomy_wbtest.mbt live_autonomy_wbtest.mbt --no-render",
        "git diff --check",
      ],
      created_at_ms,
    },
    {
      id: "validated-auto-commit-policy",
      title: "Promote validated self-repairs into local commits with auditable policy",
      owner: "moontown+planbook+moonclaw",
      priority: 20,
      status: "open",
      source_plan: "docs/PLANBOOK.md",
      rationale: "A live software town needs source-control discipline, not only file patches.",
      target_files: [
        "src/planbook_runtime/planbook_repair.mbt", "src/planbook_runtime/planbook_autonomy.mbt",
        "docs/PLANBOOK.md",
      ],
      acceptance: [
        "Repair packets carry explicit commit and push policy", "Accepted repair result records commit status and message",
        "Push remains disabled unless policy is changed in JSON or docs",
      ],
      validation: [
        "moon check --no-render", "moon test planbook_autonomy_wbtest.mbt --no-render",
        "git diff --check",
      ],
      created_at_ms,
    },
    {
      id: "daily-engineering-digest",
      title: "Generate a daily engineering digest from PlanBook repair and daemon history",
      owner: "moontown+planbook",
      priority: 30,
      status: "open",
      source_plan: "docs/USAGE.md",
      rationale: "The operator should see overnight progress, blockers, and commits without tailing logs.",
      target_files: [
        "src/planbook_runtime/planbook_autonomy.mbt", "src/runtime_status/runtime_status_snapshot.mbt",
        "docs/USAGE.md",
      ],
      acceptance: [
        "Daily digest summarizes attempts, accepted repairs, blockers, validations, and commits",
        "Digest is written to the PlanBook workspace", "Live status points to the latest digest",
      ],
      validation: [
        "moon check --no-render", "moon test planbook_autonomy_wbtest.mbt live_autonomy_wbtest.mbt --no-render",
        "git diff --check",
      ],
      created_at_ms,
    },
  ]
}
