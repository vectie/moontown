///|
fn render_wenyu_next_build_plan(plan : @roles.MayorGoalPlan) -> String {
  let builder = StringBuilder::new()
  let steps = wenyu_next_build_steps()
  let mut index = 1
  for step in steps {
    builder.write_string("\{index}. \{step}\n")
    index += 1
  }
  builder.write_string("\n")
  builder.write_string(
    "Lane count for next planning pass: \{plan.lanes.length()}.",
  )
  builder.to_string()
}

///|
fn wenyu_next_build_steps() -> Array[String] {
  [
    "Promote each lane's bootstrap findings into module-specific MoonBook pages instead of generic MoonTown/MoonBook/MoonClaw pages.",
    "Define a shared `TownRuntimeProjection` contract that exposes only safe, UI-ready fragments from each module book.",
    "Switch Rabbita Town from demo simulation state to projection-loaded Wenyu state while keeping simulation fallback for demos.",
    "Add module-by-module build tasks from the lane reports, starting with Town Shell and Resident Twins because other modules depend on live place and resident primitives.",
    "Keep the mayor loop responsible for supervision, recovery, and cross-lane synthesis; do not move global scheduling authority into MoonBook or MoonClaw.",
  ]
}
