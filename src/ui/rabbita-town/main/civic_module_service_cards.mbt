///|
fn render_policy_hall_module_card(model : Model) -> @rabbita.Html {
  let context = policy_hall_runtime_context(model)
  let worker = context.worker
  let task = context.task
  let execution = context.execution
  let queue_pressure = policy_hall_queue_pressure(model, worker)
  let health = policy_hall_health(worker, execution)
  let confidence = policy_hall_confidence(model, execution)
  render_civic_module_card_shell(
    civic_module_card_spec(
      "South / services",
      "Policy Hall",
      policy_hall_module_copy(model, worker, execution),
      policy_hall_worker_label(worker),
      queue_pressure,
      health,
      policy_hall_next_action(model, task, execution),
      policy_hall_signal_class(model, execution),
      policy_hall_signal(model, execution),
      details=[
        render_module_detail("Confidence", "\{confidence}%"),
        render_module_detail(
          "Checklist",
          policy_hall_checklist_label(model, execution),
        ),
        render_module_detail(
          "Evidence",
          policy_hall_evidence_label(model, execution),
        ),
      ],
    ),
  )
}

///|
fn render_resident_twins_module_card(model : Model) -> @rabbita.Html {
  let context = civic_module_runtime_context(model, "wenyu-resident-twins")
  let worker = context.worker
  let task = context.task
  let execution = context.execution
  let queue_pressure = resident_twins_queue_pressure(model, worker)
  let health = resident_twins_health(worker, execution)
  render_civic_module_card_shell(
    civic_module_card_spec(
      "Central / lived layer",
      "Resident Twins",
      resident_twins_module_copy(model, worker, execution),
      resident_twins_worker_label(worker),
      queue_pressure,
      health,
      resident_twins_next_action(model, task, execution),
      resident_twins_signal_class(model, execution),
      resident_twins_signal(model, execution),
      details=[
        render_module_detail(
          "Stage",
          resident_twins_build_stage(model, execution),
        ),
        render_module_detail(
          "Active twin",
          resident_twins_active_twin_label(model),
        ),
        render_module_detail("Privacy", resident_twins_privacy_label(model)),
      ],
    ),
  )
}

///|
fn render_social_square_module_card(model : Model) -> @rabbita.Html {
  let context = social_square_runtime_context(model)
  let worker = context.worker
  let task = context.task
  let execution = context.execution
  let lead_match = social_square_lead_match(model)
  let queue_pressure = social_square_queue_pressure(model, worker)
  let health = social_square_health(worker, execution)
  render_civic_module_card_shell(
    civic_module_card_spec(
      "Central / cafe",
      "Social Square",
      social_square_module_copy(model, worker, execution),
      social_square_worker_label(worker),
      queue_pressure,
      health,
      social_square_next_action(model, task, execution),
      social_square_signal_class(model, execution),
      social_square_signal(model, execution),
      details=[
        render_module_detail("Stage", social_square_stage(model, execution)),
        render_module_detail("Lead pair", social_square_pair_label(lead_match)),
        render_module_detail(
          "Strongest match",
          "\{lead_match.confidence}% confidence",
        ),
      ],
      card_class=civic_module_card_class(
        extra="civic-module-card-social-square",
      ),
    ),
  )
}

///|
fn render_talent_avenue_module_card(model : Model) -> @rabbita.Html {
  let context = civic_module_runtime_context(model, "talent-avenue")
  let worker = context.worker
  let task = context.task
  let execution = context.execution
  let queue_pressure = talent_avenue_queue_pressure(model, worker)
  let health = talent_avenue_health(model, worker, execution)
  render_civic_module_card_shell(
    civic_module_card_spec(
      "Central / showcase",
      "Talent Avenue",
      talent_avenue_module_copy(model, worker, execution),
      talent_avenue_worker_label(worker),
      queue_pressure,
      health,
      talent_avenue_next_action(model, task, execution),
      talent_avenue_signal_class(model, execution),
      talent_avenue_signal(model, execution),
    ),
  )
}

///|
fn render_ai_garden_module_card(model : Model) -> @rabbita.Html {
  let context = ai_garden_runtime_context(model)
  let worker = context.worker
  let task = context.task
  let execution = context.execution
  let queue_pressure = ai_garden_queue_pressure(model, worker)
  let health = ai_garden_health(model, worker, execution)
  render_civic_module_card_shell(
    civic_module_card_spec(
      "North / eco",
      "AI Garden",
      ai_garden_module_copy(model, worker, execution),
      ai_garden_worker_label(worker),
      queue_pressure,
      health,
      ai_garden_next_action(model, task, execution),
      ai_garden_signal_class(model, execution),
      ai_garden_signal(model, execution),
      details=[
        render_module_detail("Stage", ai_garden_stage(model, execution)),
        render_module_detail(
          "Tool trial",
          ai_garden_tool_trial_label(model, execution),
        ),
        render_module_detail("Workshop", ai_garden_workshop_label(model)),
      ],
    ),
  )
}
