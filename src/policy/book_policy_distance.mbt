///|
pub(all) enum InternalDistanceLayer {
  Information
  Recognition
  Decisiveness
  Unknown(String)
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct InternalDistanceStep {
  layer : String
  distance : String
  bridge : String
  subjects : Array[String]
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn internal_distance_layer_text(layer : InternalDistanceLayer) -> String {
  match layer {
    Information => "information"
    Recognition => "recognition"
    Decisiveness => "decisiveness"
    Unknown(value) => value
  }
}

///|
pub fn internal_distance_layer_from_text(
  text : String,
) -> InternalDistanceLayer {
  match text.trim().to_owned().to_lower() {
    "information" => Information
    "recognition" => Recognition
    "decisiveness" => Decisiveness
    other => Unknown(other)
  }
}

///|
fn skill_ids(skills : Array[SkillSpec]) -> Array[String] {
  skills.map(skill => skill.id)
}

///|
fn distance_step(
  layer : InternalDistanceLayer,
  distance : String,
  bridge : String,
  subjects : Array[String],
  summary : String,
) -> InternalDistanceStep {
  {
    layer: internal_distance_layer_text(layer),
    distance,
    bridge,
    subjects,
    summary,
  }
}

///|
pub fn internal_distance_plan(
  policy : BookPolicy,
) -> Array[InternalDistanceStep] {
  [
    distance_step(
      Information,
      "unknown -> known",
      "discovery, sensors, and broadcast",
      skill_ids(execute_skills(policy)),
      "Execute-lane skills gather new observations and turn unknowns into explicit book records.",
    ),
    distance_step(
      Recognition,
      "known -> matters",
      "interpretation, relevance, and connection",
      skill_ids(tend_skills(policy)),
      "Tend-lane skills decide which observations matter, which claims deserve trust, and which connections should reshape the book.",
    ),
    distance_step(
      Decisiveness,
      "matters -> act",
      "confidence, urgency, and safety",
      [output_contract(policy), quality_description(policy)],
      "Quality gates and output contracts decide when the book can act, publish, repair, wait, or escalate.",
    ),
  ]
}

///|
fn internal_distance_row(step : InternalDistanceStep) -> String {
  let subjects = if step.subjects.is_empty() {
    "none"
  } else {
    step.subjects.join(", ")
  }
  "- `\{step.layer}` \{step.distance} via \{step.bridge}: \{step.summary} Subjects: \{subjects}."
}

///|
pub fn internal_distance_markdown(policy : BookPolicy) -> String {
  [
    "Internal distances:",
    "",
    internal_distance_plan(policy).map(internal_distance_row).join("\n"),
  ].join("\n")
}

///|
pub impl Show for InternalDistanceLayer with fn output(
  self : InternalDistanceLayer,
  logger : &Logger,
) -> Unit {
  logger.write_string(internal_distance_layer_text(self))
}
