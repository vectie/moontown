///|
priv struct TickMetricState {
  budget : Int32
  energy : Int32
  pressure : Int32
  stability : Int32
}

///|
fn operating_budget_delta() -> Int32 {
  -2
}

///|
fn operating_energy_delta() -> Int32 {
  -1
}

///|
fn operating_pressure_delta() -> Int32 {
  1
}

///|
fn operating_stability_delta() -> Int32 {
  0
}

///|
fn periodic_bonus(tick : Int32, period : Int32, amount : Int32) -> Int32 {
  if tick % period == 0 {
    amount
  } else {
    0
  }
}

///|
fn recovery_boost(active : Bool, amount : Int32) -> Int32 {
  if active {
    amount
  } else {
    0
  }
}

///|
fn tick_metric_state(model : Model) -> TickMetricState {
  if model.state_source == StateSourceKind::SnapshotFile {
    return {
      budget: model.budget,
      energy: model.energy,
      pressure: model.pressure,
      stability: model.stability,
    }
  }
  let recovery_active = mayor_recovery_active(model)
  let overload_penalty = if model.pressure > 70 { 4 } else { 0 }
  let brittle_penalty = if model.stability < 35 { 3 } else { 0 }
  let budget_penalty = if model.budget < 24 { 2 } else { 0 }
  let energy_penalty = if model.energy < 28 { 3 } else { 0 }
  let budget = clamp_metric(
    model.budget +
    operating_budget_delta() +
    periodic_bonus(model.tick, 6, 2) +
    recovery_boost(recovery_active, 8),
  )
  let energy = clamp_metric(
    model.energy +
    operating_energy_delta() -
    overload_penalty +
    periodic_bonus(model.tick, 5, 1) +
    recovery_boost(recovery_active, 10),
  )
  let pressure = clamp_metric(
    model.pressure +
    operating_pressure_delta() +
    brittle_penalty +
    energy_penalty -
    periodic_bonus(model.tick, 4, 1) -
    recovery_boost(recovery_active, 14),
  )
  let stability = clamp_metric(
    model.stability +
    operating_stability_delta() -
    overload_penalty -
    budget_penalty +
    periodic_bonus(model.tick, 5, 1) +
    recovery_boost(recovery_active, 12),
  )
  { budget, energy, pressure, stability, }
}
