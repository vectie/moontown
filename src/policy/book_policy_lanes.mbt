///|
pub(all) enum BookLane {
  Control
  Execute
  Tend
  Unknown(String)
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn lane_text(lane : BookLane) -> String {
  match lane {
    Control => "control"
    Execute => "execute"
    Tend => "tend"
    Unknown(value) => value
  }
}

///|
pub fn lane_from_text(text : String) -> BookLane {
  match text.trim().to_owned().to_lower() {
    "control" => Control
    "execute" => Execute
    "tend" => Tend
    other => Unknown(other)
  }
}

///|
fn execute_lane() -> String {
  lane_text(Execute)
}

///|
fn tend_lane() -> String {
  lane_text(Tend)
}

///|
fn control_lane() -> String {
  lane_text(Control)
}

///|
fn skill_in_lane(skill : SkillSpec, lane : BookLane) -> Bool {
  lane_from_text(skill.lane) == lane
}

///|
pub impl Show for BookLane with fn output(self : BookLane, logger : &Logger) -> Unit {
  logger.write_string(lane_text(self))
}
