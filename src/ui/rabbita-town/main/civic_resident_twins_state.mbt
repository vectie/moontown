///|
fn resident_twins_active_twin(model : Model) -> ResidentSim? {
  let residents = resident_sims(model)
  if residents.is_empty() {
    None
  } else {
    residents.get(model.tick % residents.length())
  }
}

///|
fn resident_twins_active_twin_label(model : Model) -> String {
  match resident_twins_active_twin(model) {
    Some(resident) => "\{resident.name} / \{resident.zone}"
    None => "Await first resident projection"
  }
}

///|
fn resident_twins_privacy_label(model : Model) -> String {
  let residents = resident_sims(model)
  let private_count = resident_private_scope_count(model)
  let visible_count = residents.length() - private_count
  if residents.is_empty() {
    "Projection pending"
  } else {
    "\{private_count} private / \{visible_count} shared"
  }
}
