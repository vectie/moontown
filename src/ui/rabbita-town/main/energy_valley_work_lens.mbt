///|
fn energy_valley_runtime_phase_label(
  phase : EnergyValleyRuntimePhase,
) -> String {
  match phase {
    Loading => "Loading"
    Live => "Live"
    Stale => "Stale"
    Unavailable => "Unavailable"
    Error => "Error"
  }
}

///|
fn energy_valley_runtime_phase_detail(
  state : EnergyValleyRuntimeState,
) -> String {
  match state.phase {
    Loading => "Waiting for the first durable runtime projection."
    Live =>
      "Stations and task counts come from the current durable runtime projection."
    Stale =>
      "Showing the last genuine snapshot. It is older than 75 seconds, so no task is claimed active."
    Unavailable =>
      "The runtime reported no durable state. Decorative fixtures do not count as work."
    Error =>
      if state.error.is_empty() {
        "The runtime projection could not be read. No task is claimed active."
      } else {
        "\{state.error} No task is claimed active."
      }
  }
}

///|
fn energy_valley_runtime_civic_key(civic : WenyuTownModule) -> String {
  match civic.id {
    "vitality-dashboard" => "vitality-tower"
    "broadcast-tower" => "story-radar"
    id => id
  }
}

///|
fn energy_valley_runtime_legacy_research_module(
  task : EnergyValleyRuntimeWorkItem,
) -> String {
  let book_id = task.bookId.unwrap_or("").to_lower()
  if book_id.contains("robot") {
    "research-embodied-robotics"
  } else if book_id.contains("opc") {
    "research-opc"
  } else if book_id.contains("hardware") {
    "research-ai-hardware"
  } else if book_id.contains("llm") || book_id.contains("training") {
    "research-llm-training"
  } else {
    "research-ai-agents"
  }
}

///|
fn energy_valley_runtime_task_matches_module(
  task : EnergyValleyRuntimeWorkItem,
  civic : WenyuTownModule,
) -> Bool {
  let civic_key = energy_valley_runtime_civic_key(civic)
  if task.buildingModuleKey == civic_key {
    return true
  }
  if task.buildingModuleKey != "energy-lab" || !civic.id.has_prefix("research-") {
    return false
  }
  if module_book_matches(civic, task.bookId.unwrap_or("")) {
    true
  } else {
    civic.id == energy_valley_runtime_legacy_research_module(task)
  }
}

///|
fn energy_valley_runtime_task_civic_id(
  task : EnergyValleyRuntimeWorkItem,
) -> String {
  match task.buildingModuleKey {
    "vitality-tower" => "vitality-dashboard"
    "story-radar" => "broadcast-tower"
    "energy-lab" =>
      match find_module_for_book(task.bookId.unwrap_or("")) {
        Some(civic) => civic.id
        None => energy_valley_runtime_legacy_research_module(task)
      }
    key => key
  }
}

///|
fn energy_valley_runtime_tasks_for_module(
  state : EnergyValleyRuntimeState,
  civic : WenyuTownModule,
) -> Array[EnergyValleyRuntimeWorkItem] {
  match state.projection {
    Some(projection) =>
      projection.tasks.filter(task => {
        energy_valley_runtime_task_matches_module(task, civic)
      })
    None => []
  }
}

///|
fn energy_valley_runtime_live_tasks_for_module(
  state : EnergyValleyRuntimeState,
  civic : WenyuTownModule,
) -> Array[EnergyValleyRuntimeWorkItem] {
  if energy_valley_runtime_can_claim_active_work(state) {
    energy_valley_runtime_tasks_for_module(state, civic)
  } else {
    []
  }
}

///|
fn energy_valley_runtime_agents_for_task(
  state : EnergyValleyRuntimeState,
  task_id : String,
) -> Array[EnergyValleyRuntimeAgent] {
  match state.projection {
    Some(projection) =>
      projection.agents.filter(agent => {
        agent.workItemId.unwrap_or("") == task_id
      })
    None => []
  }
}

///|
fn energy_valley_runtime_active_agents(
  state : EnergyValleyRuntimeState,
) -> Array[EnergyValleyRuntimeAgent] {
  if !energy_valley_runtime_can_claim_active_work(state) {
    return []
  }
  match state.projection {
    Some(projection) =>
      projection.agents.filter(agent => {
        energy_valley_runtime_active_task_for_agent(state, agent) is Some(_)
      })
    None => []
  }
}

///|
fn energy_valley_runtime_active_agents_for_module(
  state : EnergyValleyRuntimeState,
  civic : WenyuTownModule,
) -> Array[EnergyValleyRuntimeAgent] {
  energy_valley_runtime_active_agents(state).filter(agent => {
    let building_key = agent.buildingModuleKey.unwrap_or("")
    if building_key == energy_valley_runtime_civic_key(civic) {
      true
    } else if building_key == "energy-lab" && civic.id.has_prefix("research-") {
      match agent.workItemId {
        Some(task_id) =>
          energy_valley_runtime_tasks_for_module(state, civic).any(task => {
            task.id == task_id
          })
        None => false
      }
    } else {
      false
    }
  })
}

///|
fn energy_valley_runtime_known_agents_for_module(
  state : EnergyValleyRuntimeState,
  civic : WenyuTownModule,
) -> Array[EnergyValleyRuntimeAgent] {
  match state.projection {
    None => []
    Some(projection) =>
      projection.agents.filter(agent => {
        let building_key = agent.buildingModuleKey.unwrap_or("")
        if building_key == energy_valley_runtime_civic_key(civic) {
          true
        } else if building_key == "energy-lab" &&
          civic.id.has_prefix("research-") {
          match agent.workItemId {
            Some(task_id) =>
              energy_valley_runtime_tasks_for_module(state, civic).any(task => {
                task.id == task_id
              })
            None => false
          }
        } else {
          false
        }
      })
  }
}

///|
fn energy_valley_runtime_exchange_title(
  state : EnergyValleyRuntimeState,
  exchange_party_count : Int,
) -> String {
  if exchange_party_count >= 2 {
    if state.phase is Live {
      "Exchange active"
    } else {
      "Last recorded exchange team"
    }
  } else if exchange_party_count == 1 {
    "Solo station"
  } else {
    "No runtime agents assigned"
  }
}

///|
fn render_energy_valley_module_agent_exchange(
  state : EnergyValleyRuntimeState,
  civic : WenyuTownModule,
) -> @rabbita.Html {
  let agents = energy_valley_runtime_known_agents_for_module(state, civic)
  let tasks = energy_valley_runtime_tasks_for_module(state, civic)
  let mut participant_count = 0
  let participant_families : Array[String] = []
  for task in tasks {
    match task.collaboration {
      Some(collaboration) =>
        for participant in collaboration.participants {
          participant_count += 1
          if !participant_families.contains(participant.family) {
            participant_families.push(participant.family)
          }
        }
      None => ()
    }
  }
  section(class="module-agent-exchange", [
    header(class="module-work-floor-header module-agent-exchange-head", [
      div([
        p(class="eyebrow", "Agent exchange"),
        h2(
          energy_valley_runtime_exchange_title(
            state,
            agents.length() + participant_count,
          ),
        ),
      ]),
      span(
        class="module-work-floor-seed",
        "\{agents.length()} runtime · \{participant_count} collaborators",
      ),
    ]),
    p(
      class="module-work-floor-intro",
      if state.phase is Live {
        "Runtime agents enter through the shared road, work at assigned stations, and exchange recorded collaboration runs here."
      } else {
        "The roster below comes from the last genuine runtime snapshot; it remains inspectable but is not presented as live activity."
      },
    ),
    if agents.is_empty() {
      p(
        class="interior-empty",
        "No durable runtime agent currently resolves to this building.",
      )
    } else {
      div(
        class="module-runtime-agent-grid",
        agents.map(agent => {
          article(class="module-runtime-agent-card", [
            div(class="module-runtime-agent-head", [
              span(class="module-runtime-agent-name", agent.name),
              span(agent.status),
            ]),
            p("\{agent.role} · \{agent.runId.unwrap_or("no run")}"),
            p(
              class="module-runtime-agent-work",
              match agent.workItemId {
                Some(work_item_id) => "Work item \{work_item_id}"
                None => "No work item attached"
              },
            ),
          ])
        }),
      )
    },
    if participant_families.is_empty() {
      p(
        class="module-agent-exchange-foot",
        "No collaboration participants are recorded for this building snapshot.",
      )
    } else {
      p(
        class="module-agent-exchange-foot",
        "Recorded collaboration families: \{participant_families.join(", ")}.",
      )
    },
  ])
}

///|
fn energy_valley_runtime_task_count(
  state : EnergyValleyRuntimeState,
  status : String,
) -> Int {
  let mut count = 0
  match state.projection {
    Some(projection) =>
      for task in projection.tasks {
        if task.status == status {
          count += 1
        }
      }
    None => ()
  }
  count
}

///|
fn energy_valley_runtime_open_task_count(
  state : EnergyValleyRuntimeState,
) -> Int {
  let mut count = 0
  match state.projection {
    Some(projection) =>
      for task in projection.tasks {
        if task.status != "completed" {
          count += 1
        }
      }
    None => ()
  }
  count
}

///|
fn energy_valley_runtime_optional_label(value : String?) -> String {
  value.unwrap_or("Not assigned")
}

///|
fn render_energy_valley_runtime_identity_row(
  label : String,
  value : String,
) -> @rabbita.Html {
  div(class="module-runtime-counter", [
    span(class="module-runtime-counter-label", label),
    span(class="module-runtime-counter-value", value),
  ])
}

///|
fn render_energy_valley_runtime_agents(
  state : EnergyValleyRuntimeState,
  task : EnergyValleyRuntimeWorkItem,
) -> @rabbita.Html {
  let agents = energy_valley_runtime_agents_for_task(state, task.id)
  if agents.is_empty() {
    p(
      class="module-runtime-detail",
      "No runtime agent is currently attached to this work item.",
    )
  } else {
    div(
      class="module-runtime-counters",
      agents.map(agent => {
        let run_id = agent.runId.unwrap_or("no run")
        render_energy_valley_runtime_identity_row(
          agent.name,
          "\{agent.role} · \{agent.status} · \{run_id}",
        )
      }),
    )
  }
}

///|
fn render_energy_valley_runtime_participants(
  task : EnergyValleyRuntimeWorkItem,
) -> @rabbita.Html {
  match task.collaboration {
    Some(collaboration) =>
      if collaboration.participants.is_empty() {
        p(
          class="module-runtime-detail",
          "No collaboration run participants are recorded.",
        )
      } else {
        div(
          class="module-runtime-counters",
          [
            render_energy_valley_runtime_identity_row(
              "Mode",
              collaboration.mode,
            ),
          ] +
          collaboration.participants.map(participant => {
            render_energy_valley_runtime_identity_row(
              participant.family,
              "\{participant.status} · \{participant.runId}",
            )
          }),
        )
      }
    None =>
      p(
        class="module-runtime-detail",
        "No collaboration run participants are recorded.",
      )
  }
}

///|
fn render_energy_valley_runtime_result_links(
  task : EnergyValleyRuntimeWorkItem,
) -> @rabbita.Html {
  let links = task.resultLinks.unwrap_or([])
  if links.is_empty() {
    p(
      class="module-runtime-detail",
      "No allowlisted result page is recorded yet.",
    )
  } else {
    div(
      class="module-runtime-counters",
      links
      .filter(energy_valley_runtime_result_link_is_valid)
      .map(link => {
        a(
          href=link.url,
          class="module-runtime-counter module-runtime-result-link",
          [
            span(class="module-runtime-counter-label", link.kind),
            span(class="module-runtime-counter-value", link.label),
          ],
        )
      }),
    )
  }
}

///|
fn render_energy_valley_runtime_task(
  state : EnergyValleyRuntimeState,
  civic : WenyuTownModule,
  task : EnergyValleyRuntimeWorkItem,
) -> @rabbita.Html {
  @html.details(class="module-interior-diagnostics runtime-work-item", [
    @html.summary(class="module-interior-diagnostics-summary", [
      span(task.title),
      span("\{task.status} · \{task.id}"),
    ]),
    div(class="module-interior-diagnostics-body", [
      div(class="module-runtime-counters", [
        render_energy_valley_runtime_identity_row("Task ID", task.id),
        render_energy_valley_runtime_identity_row("Status", task.status),
        render_energy_valley_runtime_identity_row("Source", task.source),
        render_energy_valley_runtime_identity_row(
          "Run",
          energy_valley_runtime_optional_label(task.runId),
        ),
        render_energy_valley_runtime_identity_row(
          "Correlation",
          energy_valley_runtime_optional_label(task.correlationId),
        ),
        render_energy_valley_runtime_identity_row(
          "Building",
          task.buildingModuleKey,
        ),
        render_energy_valley_runtime_identity_row(
          "Module",
          "\{civic.title} · \{civic.id}",
        ),
      ]),
      h3("Assigned runtime agents"),
      render_energy_valley_runtime_agents(state, task),
      h3("Collaboration participants"),
      render_energy_valley_runtime_participants(task),
      h3("Recorded results"),
      render_energy_valley_runtime_result_links(task),
    ]),
  ])
}

///|
fn render_energy_valley_module_work_lens(
  state : EnergyValleyRuntimeState,
  civic : WenyuTownModule,
) -> @rabbita.Html {
  let tasks = energy_valley_runtime_tasks_for_module(state, civic)
  section(class="module-runtime-work-lens", [
    header(class="module-work-floor-header", [
      div([
        p(class="eyebrow", "Runtime work lens"),
        h2("Recorded building work"),
      ]),
      span(
        class="module-work-floor-seed",
        energy_valley_runtime_phase_label(state.phase),
      ),
    ]),
    p(
      class="module-work-floor-intro",
      energy_valley_runtime_phase_detail(state),
    ),
    if tasks.is_empty() {
      p(
        class="interior-empty",
        "No durable task currently resolves to this building.",
      )
    } else {
      div(
        class="module-runtime-work-items",
        tasks.map(task => render_energy_valley_runtime_task(state, civic, task)),
      )
    },
  ])
}
