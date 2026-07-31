///|
fn moonflow_product_execution_field(
  reply : MoonFlowReceiverSettlementReply?,
  key : String,
) -> String {
  guard reply is Some(value) &&
    value.product_execution is Some(Object(fields)) &&
    fields.get(key) is Some(String(text)) else {
    return ""
  }
  text
}

///|
fn render_moonflow_receiver_loading(
  request : MoonFlowReceiverRequest,
) -> @rabbita.Html {
  render_research_handoff_shell(
    "loading",
    "VERIFYING FLOW",
    "Inspecting declared MoonFlow work",
    "MoonTown is loading the exact run-bound intake and receiver status from MoonDesk. No workspace mutation or synthesis is claimed yet.",
    [
      div(class="research-handoff-identity", [
        render_module_detail("MoonFlow run", request.run_id),
        render_module_detail(
          "Opaque handoff",
          request.handoff_token[0:12].to_owned() + "…",
        ),
      ]),
    ],
  )
}

///|
fn render_moonflow_receiver_ready(
  dispatch : Dispatch[Msg],
  request : MoonFlowReceiverRequest,
  intake : MoonFlowReceiverIntake,
  status : MoonFlowReceiverStatus,
) -> @rabbita.Html {
  let criteria : Array[@rabbita.Html] = []
  for criterion in intake.payload.review.acceptance_criteria {
    criteria.push(p(class="research-handoff-rule", criterion))
  }
  let inputs : Array[@rabbita.Html] = []
  for reference in intake.payload.inputs.artifacts {
    inputs.push(p(class="research-handoff-rule", reference))
  }
  render_research_handoff_shell(
    "pending",
    "READY · AUTHORITY REQUESTED",
    "MoonFlow civic synthesis",
    "This is the declared MoonTown step in the selected MoonFlow run. Starting it verifies the exact input digest, uses MoonClaw through MoonTown’s existing civic adapter, returns the product result to MoonFind, then settles this Work item with a generic MoonFlow receipt.",
    [
      div(class="research-handoff-identity", [
        render_module_detail("Run", request.run_id),
        render_module_detail("Work item", intake.payload.run.work_item_id),
        render_module_detail("Operation", intake.payload.run.operation),
        render_module_detail("Flow status", status.work_item_status),
        render_module_detail(
          "Input digest",
          intake.payload.inputs.digest[0:19].to_owned() + "…",
        ),
        render_module_detail(
          "Authority",
          intake.payload.authority.requested_authority,
        ),
      ]),
      div(class="research-handoff-boundary-grid", [
        article(class="research-handoff-boundary", [
          p(class="eyebrow", "Bound evidence"),
          h3("Workspace inputs"),
          div(class="research-handoff-rules", inputs),
        ]),
        article(class="research-handoff-boundary", [
          p(class="eyebrow", "Acceptance boundary"),
          h3("Operational completion only"),
          div(class="research-handoff-rules", criteria),
          p(
            class="research-handoff-no-claim",
            "The receiver may verify that a pending-review synthesis exists. It cannot accept that synthesis as knowledge.",
          ),
        ]),
      ]),
      div(class="research-handoff-actions", [
        button(
          class="research-handoff-action research-handoff-action-primary",
          on_click=dispatch(StartMoonFlowReceiver),
          "Grant scope & run declared step",
        ),
        p(
          "The browser sends the exact inspected intake. MoonTown revalidates the token, payload digest, contracts, input files, and evidence before any work.",
        ),
      ]),
    ],
  )
}

///|
fn render_moonflow_receiver_executing(
  request : MoonFlowReceiverRequest,
  intake : MoonFlowReceiverIntake,
  action : String,
) -> @rabbita.Html {
  render_research_handoff_shell(
    "loading",
    if action == "reconcile" {
      "RECONCILING"
    } else {
      "RUNNING"
    },
    "MoonFlow civic synthesis",
    if action == "reconcile" {
      "MoonTown is reopening only the persisted result/callback/receipt path for this exact token. It is not creating another agent runtime or replacement attempt."
    } else {
      "MoonTown is running the declared civic synthesis through its existing MoonClaw-backed adapter, persisting reviewable outputs, and returning them through the two correlated transports."
    },
    [
      div(class="research-handoff-identity", [
        render_module_detail("Run", request.run_id),
        render_module_detail("Work item", intake.payload.run.work_item_id),
        render_module_detail("Runtime", "MoonClaw"),
        render_module_detail("Action", action),
      ]),
    ],
  )
}

///|
fn render_moonflow_receiver_settled(
  dispatch : Dispatch[Msg],
  request : MoonFlowReceiverRequest,
  intake : MoonFlowReceiverIntake,
  status : MoonFlowReceiverStatus,
  settlement : MoonFlowReceiverSettlementReply?,
) -> @rabbita.Html {
  let accepted = status.status == "accepted" && status.stage == "applied"
  let callback = moonflow_product_execution_field(settlement, "callback_status")
  let error = settlement.map(value => value.error).unwrap_or("")
  render_research_handoff_shell(
    if accepted {
      "complete"
    } else {
      "blocked"
    },
    if accepted {
      "FLOW ACCEPTED · REVIEW PENDING"
    } else {
      "RESULT RETAINED"
    },
    "MoonFlow civic synthesis",
    if accepted {
      "MoonFind received the correlated product result and MoonFlow applied the exact receiver receipt. The next dependency may now become ready; the synthesis itself remains pending named-human MoonBook review."
    } else if !error.is_empty() {
      error
    } else {
      "MoonTown retained the product outcome, but MoonFlow has not accepted the receiver receipt."
    },
    [
      div(class="research-handoff-identity", [
        render_module_detail("Run", request.run_id),
        render_module_detail("Work item", intake.payload.run.work_item_id),
        render_module_detail("MoonFind callback", callback),
        render_module_detail("MoonFlow receipt", status.status),
        render_module_detail("Work status", status.work_item_status),
        render_module_detail("Run outcome", status.run_outcome),
      ]),
      if accepted {
        div(class="research-handoff-actions", [
          a(
            class="research-handoff-action research-handoff-action-primary",
            href=status.return_path,
            "Return to MoonFlow",
          ),
          p(
            "MoonFlow owns dependency release and replay. MoonTown does not schedule the next product.",
          ),
        ])
      } else {
        div(class="research-handoff-actions", [
          button(
            class="research-handoff-action research-handoff-action-primary",
            on_click=dispatch(ReconcileMoonFlowReceiver),
            "Reconcile persisted result",
          ),
          p(
            "This reuses the same handoff token, MoonTown attempt, MoonFind callback package, and immutable receiver receipt.",
          ),
        ])
      },
    ],
  )
}

///|
fn render_moonflow_receiver_panel(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  match model.moonflow_receiver {
    NoMoonFlowReceiver => @html.nothing
    LoadingMoonFlowReceiver(request) =>
      render_moonflow_receiver_loading(request)
    ReadyMoonFlowReceiver(request, intake, status) =>
      render_moonflow_receiver_ready(dispatch, request, intake, status)
    ExecutingMoonFlowReceiver(request, intake, _, action) =>
      render_moonflow_receiver_executing(request, intake, action)
    SettledMoonFlowReceiver(request, intake, status, settlement) =>
      render_moonflow_receiver_settled(
        dispatch, request, intake, status, settlement,
      )
    BlockedMoonFlowReceiver(message) => render_research_handoff_blocked(message)
  }
}
