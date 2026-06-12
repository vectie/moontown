///|
pub struct BookLoopStep {
  order : Int
  phase : String
  lane : String
  subject : String
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookLoopPlan {
  steps : Array[BookLoopStep]
  execute_step_count : Int
  tend_step_count : Int
  required_record_contract : String
  health_gate : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn loop_step(
  order : Int,
  phase : String,
  lane : String,
  subject : String,
  summary : String,
) -> BookLoopStep {
  { order, phase, lane, subject, summary }
}

///|
fn append_skill_steps(
  steps : Array[BookLoopStep],
  order : Int,
  phase : String,
  skills : Array[SkillSpec],
) -> Int {
  let mut next_order = order
  for item in skills {
    steps.push(loop_step(next_order, phase, item.lane, item.id, item.purpose))
    next_order += 1
  }
  next_order
}

///|
pub fn loop_plan(policy : BookPolicy) -> BookLoopPlan {
  let steps : Array[BookLoopStep] = []
  let mut order = 1
  steps.push(
    loop_step(
      order, "read-policy", "control", "book-policy", "Load the composed book policy as the source of truth for skills, required files, quality gates, and output surface.",
    ),
  )
  order += 1
  order = append_skill_steps(
    steps,
    order,
    "execute-skill",
    execute_skills(policy),
  )
  steps.push(
    loop_step(
      order,
      "record-results",
      execute_lane(),
      output_contract(policy),
      "Persist skill outputs, decisions, evidence, and projection artifacts using the policy output contract.",
    ),
  )
  order += 1
  order = append_skill_steps(steps, order, "tend-skill", tend_skills(policy))
  steps.push(
    loop_step(
      order,
      "evaluate-health",
      tend_lane(),
      output_contract(policy),
      "Compare required files, structural score, semantic score, and review state against the policy quality criteria.",
    ),
  )
  {
    steps,
    execute_step_count: execute_skills(policy).length() + 1,
    tend_step_count: tend_skills(policy).length() + 1,
    required_record_contract: output_contract(policy),
    health_gate: quality_description(policy),
  }
}

///|
fn loop_step_row(step : BookLoopStep) -> String {
  "\{step.order}. `\{step.phase}` lane=`\{step.lane}` subject=`\{step.subject}`: \{step.summary}"
}

///|
pub fn loop_markdown(policy : BookPolicy) -> String {
  let plan = loop_plan(policy)
  [
    "Book loop:",
    "",
    plan.steps.map(loop_step_row).join("\n"),
    "",
    "Loop gates:",
    "- execute steps: `\{plan.execute_step_count}`",
    "- tend steps: `\{plan.tend_step_count}`",
    "- result contract: `\{plan.required_record_contract}`",
    "- health gate: \{plan.health_gate}",
  ].join("\n")
}
