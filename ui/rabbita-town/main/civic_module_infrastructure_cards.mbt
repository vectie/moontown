///|
fn render_town_shell_module_card(model : Model) -> @rabbita.Html {
  let tasks = tasks_for_model(model)
  let executions = executions_for_model(model)
  let context = civic_module_priority_runtime_context(model, "wenyu-town-shell")
  let worker = context.worker
  let task = context.task
  let execution = context.execution
  let queue_pressure = town_shell_queue_pressure(model, worker)
  let health = town_shell_health(worker, execution)
  render_civic_module_card_shell(
    civic_module_card_spec(
      "Town-wide / operator shell",
      "Town Shell",
      town_shell_module_copy(model, worker, execution),
      town_shell_worker_label(worker),
      queue_pressure,
      health,
      town_shell_next_action(model, task, execution),
      town_shell_signal_class(model, execution),
      town_shell_signal(model, execution),
      details=[
        render_module_detail(
          "Runtime feed",
          town_shell_runtime_feed_label(model),
        ),
        render_module_detail(
          "Activity",
          town_shell_activity_label(model, tasks, executions),
        ),
        render_module_detail("Stage", town_shell_build_stage(model, execution)),
      ],
    ),
  )
}

///|
fn render_vitality_dashboard_module_card(model : Model) -> @rabbita.Html {
  let context = civic_module_priority_runtime_context(model, "wenyu-town-shell")
  let worker = context.worker
  let task = context.task
  let execution = context.execution
  let queue_pressure = vitality_dashboard_queue_pressure(model, worker)
  let health = vitality_dashboard_health(model, worker, execution)
  render_civic_module_card_shell(
    civic_module_card_spec(
      "Central square / district pulse",
      "Vitality Dashboard",
      vitality_dashboard_module_copy(model, worker, execution),
      vitality_dashboard_worker_label(worker),
      queue_pressure,
      health,
      vitality_dashboard_next_action(model, task, execution),
      vitality_dashboard_signal_class(model, execution),
      vitality_dashboard_signal(model, execution),
      details=[
        render_module_detail(
          "Points",
          vitality_dashboard_points_flow_label(model),
        ),
        render_module_detail(
          "Broadcasts",
          vitality_dashboard_broadcast_label(model),
        ),
        render_module_detail(
          "Response",
          "\{service_response_minutes(model)} min",
        ),
      ],
      card_class=civic_module_card_class(
        extra="civic-module-card-vitality-dashboard",
      ),
    ),
  )
}

///|
fn render_contest_express_module_card(model : Model) -> @rabbita.Html {
  let context = civic_module_priority_runtime_context(
    model, "wenyu-contest-express",
  )
  let worker = context.worker
  let task = context.task
  let execution = context.execution
  let queue_pressure = contest_express_queue_pressure(model, worker)
  let health = contest_express_health(worker, execution)
  render_civic_module_card_shell(
    civic_module_card_spec(
      "Future Harbor / roadshow lane",
      "Contest Express",
      contest_express_module_copy(model, worker, execution),
      contest_express_worker_label(worker),
      queue_pressure,
      health,
      contest_express_next_action(model, task, execution),
      contest_express_signal_class(model, execution),
      contest_express_signal(model, execution),
      details=[
        render_module_detail(
          "Countdown",
          contest_express_countdown_label(model),
        ),
        render_module_detail(
          "Readiness",
          contest_express_readiness_label(model, execution),
        ),
        render_module_detail(
          "Champion wall",
          contest_express_champion_label(model, execution),
        ),
      ],
    ),
  )
}

///|
fn render_physical_bridge_module_card(model : Model) -> @rabbita.Html {
  let context = civic_module_runtime_context(model, "wenyu-physical-bridge")
  let worker = context.worker
  let task = context.task
  let execution = context.execution
  let queue_pressure = physical_bridge_queue_pressure(model, worker)
  let health = physical_bridge_health(model, worker, execution)
  render_civic_module_card_shell(
    civic_module_card_spec(
      "South / virtual-physical connector",
      "Physical Bridge",
      physical_bridge_module_copy(model, worker, execution),
      physical_bridge_worker_label(worker),
      queue_pressure,
      health,
      physical_bridge_next_action(model, task, execution),
      physical_bridge_signal_class(model, execution),
      physical_bridge_signal(model, execution),
      details=[
        render_module_detail("Stage", physical_bridge_stage(model, execution)),
        render_module_detail(
          "Handoff",
          physical_bridge_handoff_label(model, execution),
        ),
        render_module_detail("Coverage", physical_bridge_coverage_label(model)),
      ],
      card_class=civic_module_card_class(
        extra="civic-module-card-physical-bridge",
      ),
    ),
  )
}
