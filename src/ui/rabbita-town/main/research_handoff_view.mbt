///|
fn render_research_handoff_status(
  tone : String,
  label : String,
) -> @rabbita.Html {
  span(class="research-handoff-status research-handoff-status-\{tone}", label)
}

///|
fn render_research_handoff_shell(
  tone : String,
  status : String,
  title : String,
  summary : String,
  body : Array[@rabbita.Html],
) -> @rabbita.Html {
  let children : Array[@rabbita.Html] = [
    div(class="research-handoff-heading", [
      div([p(class="eyebrow", "Typed civic handoff"), h2(title)]),
      render_research_handoff_status(tone, status),
    ]),
    p(class="research-handoff-summary", summary),
  ]
  for child in body {
    children.push(child)
  }
  aside(
    class="research-handoff-panel research-handoff-panel-\{tone}",
    attrs=@html.Attrs::build()
      .aria_label("Research handoff")
      .aria_live("polite"),
    children,
  )
}

///|
fn render_research_handoff_loading(
  request : ResearchHandoffRequest,
) -> @rabbita.Html {
  render_research_handoff_shell(
    "loading",
    "VALIDATING",
    "Inspecting research salon",
    "MoonTown is fetching the exact typed artifact and checking it against the URL contract and handoff id. No participant work, synthesis, or execution is claimed while validation is pending.",
    [
      div(class="research-handoff-identity", [
        render_module_detail("Contract", request.handoff_contract),
        render_module_detail("Handoff", request.handoff_id),
      ]),
    ],
  )
}

///|
fn render_research_handoff_blocked(message : String) -> @rabbita.Html {
  render_research_handoff_shell(
    "blocked",
    "BLOCKED",
    "Research handoff blocked",
    "MoonTown did not accept this external handoff. The town remains unchanged and no research-salon execution has started.",
    [
      article(class="research-handoff-boundary research-handoff-error", [
        h3("Why it stopped"),
        p(message),
      ]),
    ],
  )
}

///|
fn render_research_handoff_participant(
  participant : ResearchHandoffParticipant,
) -> @rabbita.Html {
  article(class="research-handoff-participant", [
    div(class="research-handoff-participant-heading", [
      h3(participant.title),
      span(participant.book_id),
    ]),
    p(class="research-handoff-participant-focus", participant.focus_area),
    p(class="research-handoff-question", participant.current_question),
    p(class="research-handoff-contribution", participant.contribution),
  ])
}

///|
fn render_research_handoff_ready(
  dispatch : Dispatch[Msg],
  request : ResearchHandoffRequest,
  handoff : ResearchHandoff,
) -> @rabbita.Html {
  let participants : Array[@rabbita.Html] = []
  for participant in handoff.scenario.participants {
    participants.push(render_research_handoff_participant(participant))
  }
  let quality_rules : Array[@rabbita.Html] = []
  for rule in handoff.scenario.quality_rules {
    quality_rules.push(p(class="research-handoff-rule", rule))
  }
  render_research_handoff_shell(
    "pending",
    "PENDING · NOT EXECUTED",
    handoff.scenario.title,
    "MoonTown validated the exact typed request from \{handoff.producer}. Starting it creates one immutable Flow attempt, delegates synthesis to MoonClaw, and keeps every result pending named-human review.",
    [
      div(class="research-handoff-identity", [
        render_module_detail("Producer run", handoff.producer_run_id),
        render_module_detail("Handoff", request.handoff_id),
        render_module_detail(
          "Participants",
          "\{handoff.scenario.participants.length()} books",
        ),
        render_module_detail("Topic", handoff.scenario.topic),
      ]),
      section(class="research-handoff-section", [
        div(class="research-handoff-section-heading", [
          p(class="eyebrow", "Participant boundary"),
          h3("Books invited to challenge"),
        ]),
        div(class="research-handoff-participants", participants),
      ]),
      div(class="research-handoff-boundary-grid", [
        article(class="research-handoff-boundary", [
          p(class="eyebrow", "Challenge boundary"),
          h3("What MoonTown may examine"),
          p(handoff.scenario.skill_description),
          div(class="research-handoff-compact-meta", [
            render_module_detail(
              "Pattern",
              handoff.scenario.communication_pattern_id.unwrap_or("unknown"),
            ),
            render_module_detail("Reduction", handoff.scenario.reduction_kind),
            render_module_detail("Protocol", handoff.scenario.protocol_channel),
            render_module_detail("Output", handoff.scenario.output_channel),
          ]),
          div(class="research-handoff-rules", quality_rules),
        ]),
        article(class="research-handoff-boundary", [
          p(class="eyebrow", "Review boundary"),
          h3("Nothing is accepted automatically"),
          p(handoff.scenario.review_reason),
          div(class="research-handoff-compact-meta", [
            render_module_detail("Gate", handoff.scenario.review_gate),
            render_module_detail("Owner", handoff.scenario.review_owner),
            render_module_detail(
              "Synthesis book",
              handoff.scenario.building_book_id,
            ),
          ]),
          p(
            class="research-handoff-no-claim",
            "Required next evidence: a separately bound execution receipt and a named-human review decision.",
          ),
        ]),
      ]),
      div(class="research-handoff-actions", [
        button(
          class="research-handoff-action research-handoff-action-primary",
          on_click=dispatch(StartResearchHandoff),
          "Start governed salon",
        ),
        p(
          "The browser cannot supply a different scenario, model, callback, or attempt id. MoonTown re-fetches this exact handoff before execution.",
        ),
      ]),
    ],
  )
}

///|
fn render_research_handoff_executing(
  request : ResearchHandoffRequest,
  handoff : ResearchHandoff,
  action : String,
) -> @rabbita.Html {
  render_research_handoff_shell(
    "loading",
    if action == "reconcile" {
      "RECONCILING"
    } else {
      "RUNNING"
    },
    handoff.scenario.title,
    if action == "reconcile" {
      "MoonTown is reconciling the original immutable Flow attempt and retrying only the correlated result delivery. It is not creating another agent run."
    } else {
      "MoonTown is executing the durable research-salon attempt through its existing civic runtime and MoonClaw reducer. Keep this window open while the local host settles the receipt."
    },
    [
      div(class="research-handoff-identity", [
        render_module_detail("Handoff", request.handoff_id),
        render_module_detail("Action", action),
        render_module_detail("Runtime", "MoonClaw"),
        render_module_detail("Review", "named-human pending"),
      ]),
    ],
  )
}

///|
fn render_research_handoff_settled(
  dispatch : Dispatch[Msg],
  request : ResearchHandoffRequest,
  handoff : ResearchHandoff,
  reply : ResearchHandoffExecutionReply,
) -> @rabbita.Html {
  let delivered = reply.ok &&
    reply.execution_status == "completed" &&
    reply.review_status == "pending" &&
    reply.callback_status == "delivered"
  render_research_handoff_shell(
    if delivered {
      "complete"
    } else {
      "blocked"
    },
    if delivered {
      "RETURNED · REVIEW PENDING"
    } else if reply.callback_status == "pending-reconcile" {
      "RESULT RETAINED"
    } else {
      "BLOCKED"
    },
    handoff.scenario.title,
    if delivered {
      "MoonTown persisted the MoonClaw receipt and reducer output, and MoonFind accepted their exact run identity. This is reviewable evidence—not an accepted synthesis."
    } else if !reply.error.is_blank() {
      reply.error
    } else {
      "MoonTown retained the execution outcome without claiming a successful cross-product return."
    },
    [
      div(class="research-handoff-identity", [
        render_module_detail("Handoff", request.handoff_id),
        render_module_detail("Execution", reply.execution_status),
        render_module_detail("Review", reply.review_status),
        render_module_detail("MoonFind callback", reply.callback_status),
      ]),
      if reply.callback_status == "pending-reconcile" {
        div(class="research-handoff-actions", [
          button(
            class="research-handoff-action research-handoff-action-primary",
            on_click=dispatch(ReconcileResearchHandoff),
            "Reconcile same attempt",
          ),
          p(
            "This reuses the persisted request, idempotency key, receipt, and output. It never launches a replacement attempt.",
          ),
        ])
      } else {
        @html.nothing
      },
    ],
  )
}

///|
fn render_research_handoff_panel(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  match model.research_handoff {
    NoResearchHandoff => @html.nothing
    LoadingResearchHandoff(request) => render_research_handoff_loading(request)
    ReadyResearchHandoff(request, handoff) =>
      render_research_handoff_ready(dispatch, request, handoff)
    ExecutingResearchHandoff(request, handoff, action) =>
      render_research_handoff_executing(request, handoff, action)
    SettledResearchHandoff(request, handoff, reply) =>
      render_research_handoff_settled(dispatch, request, handoff, reply)
    BlockedResearchHandoff(message) => render_research_handoff_blocked(message)
  }
}
