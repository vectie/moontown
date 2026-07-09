///|
fn status_chip(text : String, class_name : String) -> @rabbita.Html {
  span(class="chip \{class_name}", text)
}

///|
fn class_suffix_when(enabled : Bool, suffix : String) -> String {
  if enabled {
    suffix
  } else {
    ""
  }
}

///|
fn no_children() -> Array[@rabbita.Html] {
  []
}

///|
fn real_phase_label() -> String {
  let hour = real_local_hour()
  if hour < 6 {
    "Night patrol"
  } else if hour < 11 {
    "Morning onboarding"
  } else if hour < 15 {
    "Midday service"
  } else if hour < 19 {
    "Cafe matching"
  } else {
    "Evening reflection"
  }
}
