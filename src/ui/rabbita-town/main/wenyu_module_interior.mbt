///|
fn module_workers(
  civic : WenyuTownModule,
  workers : Array[WorkerSim],
) -> Array[WorkerSim] {
  workers.filter(worker => module_book_matches(civic, worker.book_id))
}

///|
fn render_module_visual_agent(
  dispatch : Dispatch[Msg],
  agent : VisualAgentSnapshot,
) -> @rabbita.Html {
  button(
    class="interior-agent visual-interior-agent \{visual_agent_status_class(agent)}",
    title=agent.message,
    on_click=dispatch(SelectWorker(agent.worker_id)),
    [
      span(class="interior-agent-name", agent.worker_name),
      span(class="interior-agent-role", "\{agent.role} / \{agent.phase}"),
      span(class="interior-agent-summary", agent.message),
    ],
  )
}

///|
fn render_module_issue_list(civic : WenyuTownModule) -> @rabbita.Html {
  let issues = module_validation_issues(civic)
  if issues.is_empty() {
    div(class="module-issue-list module-issue-list-clean", [
      span("Config validated for current viewport placement."),
    ])
  } else {
    div(
      class="module-issue-list",
      issues.map(issue => span(class="module-issue-chip", issue)),
    )
  }
}

///|
fn render_module_runtime_counters(
  runtime : WenyuModuleRuntimeState,
) -> @rabbita.Html {
  div(class="module-runtime-counters", [
    span("Run \{runtime.running_count}"),
    span("Wait \{runtime.waiting_count}"),
    span("Review \{runtime.review_count}"),
    span("Blocked \{runtime.blocked_count}"),
    span("Done \{runtime.completed_count}"),
  ])
}

///|
fn render_module_protocol_card(civic : WenyuTownModule) -> @rabbita.Html {
  article(class="module-protocol-card", [
    div(class="module-civic-health-head", [
      span(class="module-book-chip projection-tone-info", "Building Protocol"),
      span(class="module-civic-status", civic.protocol_pattern),
    ]),
    p(class="module-book-summary", civic.use_case),
    div(class="module-book-metric-grid", [
      render_projection_metric({
        label: "Footprint",
        value: "\{civic.footprint_w}x\{civic.footprint_h}",
        note: "tile occupancy",
        tone: "info",
      }),
      render_projection_metric({
        label: "Entrance",
        value: "\{civic.entrance_x},\{civic.entrance_y}",
        note: "road-facing tile",
        tone: "info",
      }),
      render_projection_metric({
        label: "Style",
        value: civic.style_family,
        note: civic.asset_base,
        tone: "info",
      }),
    ]),
    div(class="module-agent-flow", [
      span(class="module-detail-label", "Agent Flow"),
      p(civic.agent_flow),
    ]),
  ])
}

///|
fn render_module_interior_diagnostics(
  model : Model,
  civic : WenyuTownModule,
  runtime : WenyuModuleRuntimeState,
) -> @rabbita.Html {
  @html.details(class="module-interior-diagnostics", [
    @html.summary(class="module-interior-diagnostics-summary", [
      span("Diagnostics"),
      span("Runtime, configuration, protocol, and book output"),
    ]),
    div(class="module-interior-diagnostics-body", [
      p(class="module-runtime-detail", runtime.detail),
      render_module_runtime_counters(runtime),
      render_module_issue_list(civic),
      render_module_protocol_card(civic),
      render_module_book_projection(model, civic),
    ]),
  ])
}

///|
fn render_wenyu_module_interior(
  dispatch : Dispatch[Msg],
  model : Model,
  civic : WenyuTownModule,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let residents = module_workers(civic, workers)
  let visual_agents = module_active_visual_agents(model, civic)
  let runtime = wenyu_module_runtime_state(model, civic, executions)
  let projection = find_module_book_projection(model, civic)
  section(class="interior-shell module-interior-shell", [
    header(class="interior-header", [
      div([
        p(class="eyebrow", "Module Interior"),
        h2(civic.title),
        p(
          class="module-interior-district",
          module_interior_district_label(civic.district),
        ),
      ]),
      a(
        href="./viewport.html?assets=generated&mode=view&v=wenyu-modules",
        class="control-button viewport-back-town",
        "Back To Town",
      ),
    ]),
    div(class="interior-room module-interior-room", [
      render_module_interior_overview(civic, runtime, projection),
      div(class="interior-floor", module_interior_furniture(civic)),
      div(
        class="interior-agent-grid module-interior-agent-grid",
        if !visual_agents.is_empty() {
          visual_agents.map(agent => render_module_visual_agent(dispatch, agent))
        } else if residents.is_empty() {
          [
            p(
              class="interior-empty",
              "No active workers are inside this module. Idle residents stay hidden until the module is opened by runtime projection.",
            ),
          ]
        } else {
          residents.map(worker => render_interior_agent(dispatch, worker))
        },
      ),
      render_module_interior_diagnostics(model, civic, runtime),
    ]),
  ])
}
