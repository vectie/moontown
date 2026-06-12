///|
priv struct TickMetricState {
  budget : Int
  energy : Int
  pressure : Int
  stability : Int
}

///|
fn strategy_budget_delta(strategy : Strategy) -> Int {
  match strategy {
    Balanced => -2
    Throughput => -4
    Recovery => -1
  }
}

///|
fn strategy_energy_delta(strategy : Strategy) -> Int {
  match strategy {
    Balanced => -1
    Throughput => -4
    Recovery => 2
  }
}

///|
fn strategy_pressure_delta(strategy : Strategy) -> Int {
  match strategy {
    Balanced => 1
    Throughput => 5
    Recovery => -3
  }
}

///|
fn strategy_stability_delta(strategy : Strategy) -> Int {
  match strategy {
    Balanced => 0
    Throughput => -3
    Recovery => 3
  }
}

///|
fn periodic_bonus(tick : Int, period : Int, amount : Int) -> Int {
  if tick % period == 0 {
    amount
  } else {
    0
  }
}

///|
fn recovery_boost(active : Bool, amount : Int) -> Int {
  if active {
    amount
  } else {
    0
  }
}

///|
fn tick_metric_state(model : Model) -> TickMetricState {
  let recovery_active = mayor_recovery_active(model)
  let overload_penalty = if model.pressure > 70 { 4 } else { 0 }
  let brittle_penalty = if model.stability < 35 { 3 } else { 0 }
  let budget_penalty = if model.budget < 24 { 2 } else { 0 }
  let energy_penalty = if model.energy < 28 { 3 } else { 0 }
  let budget = clamp_metric(
    model.budget +
    strategy_budget_delta(model.strategy) +
    periodic_bonus(model.tick, 6, 2) +
    recovery_boost(recovery_active, 8),
  )
  let energy = clamp_metric(
    model.energy +
    strategy_energy_delta(model.strategy) -
    overload_penalty +
    periodic_bonus(model.tick, 5, 1) +
    recovery_boost(recovery_active, 10),
  )
  let pressure = clamp_metric(
    model.pressure +
    strategy_pressure_delta(model.strategy) +
    brittle_penalty +
    energy_penalty -
    periodic_bonus(model.tick, 4, 1) -
    recovery_boost(recovery_active, 14),
  )
  let stability = clamp_metric(
    model.stability +
    strategy_stability_delta(model.strategy) -
    overload_penalty -
    budget_penalty +
    periodic_bonus(model.tick, 5, 1) +
    recovery_boost(recovery_active, 12),
  )
  { budget, energy, pressure, stability }
}
