///|
fn render_wenyu_product_architecture(plan : @roles.MayorGoalPlan) -> String {
  let builder = StringBuilder::new()
  builder.write_string(wenyu_product_architecture_intro())
  builder.write_string("\n\n")
  builder.write_string(render_wenyu_architecture_graph(plan))
  builder.write_string("\n")
  builder.write_string(wenyu_product_architecture_boundary())
  builder.to_string()
}

///|
fn wenyu_product_architecture_intro() -> String {
  [
    "Wenyu Valley should be built as a projection-driven civic simulation, not as a static website.",
    "Moontown stays awake as the mayor/control plane.", "MoonBook owns durable module knowledge and generated projections.",
    "MoonClaw executes bounded research/build tasks inside each module book.",
  ].join(" ")
}

///|
fn render_wenyu_architecture_graph(plan : @roles.MayorGoalPlan) -> String {
  let builder = StringBuilder::new()
  builder.write_string("```mermaid\n")
  builder.write_string("flowchart TB\n")
  builder.write_string(wenyu_architecture_goal_edge())
  let mut index = 1
  for lane in plan.lanes {
    builder.write_string(wenyu_architecture_lane_edge(index, lane))
    index += 1
  }
  builder.write_string(wenyu_architecture_synthesis_edge())
  builder.write_string(wenyu_architecture_operator_edge())
  builder.write_string("```\n")
  builder.to_string()
}

///|
fn wenyu_architecture_goal_edge() -> String {
  "  Goal[\"Wenyu Valley PRD goal\"] --> Mayor[\"Mayor claw in Moontown\"]\n"
}

///|
fn wenyu_architecture_lane_edge(
  index : Int,
  lane : @roles.MayorGoalLane,
) -> String {
  "  Mayor --> Lane\{index}[\"\{lane.entry.name}\"]\n"
}

///|
fn wenyu_architecture_synthesis_edge() -> String {
  "  Mayor --> Synthesis[\"Town-level build synthesis\"]\n"
}

///|
fn wenyu_architecture_operator_edge() -> String {
  "  Synthesis --> Operator[\"Operator-visible Wenyu roadmap\"]\n"
}

///|
fn wenyu_product_architecture_boundary() -> String {
  [
    "The important boundary is responsibility:", "Moontown decomposes, supervises, and visualizes.",
    "MoonBook turns each lane into durable wiki/projection state.", "MoonClaw performs the worker execution and emits artifacts back to the book.",
  ].join(" ")
}
