///|
fn work_field(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
  name : String,
  label : String,
  multiline? : Bool = false,
) -> @rabbita.Html {
  collaboration_form_field(
    dispatch,
    state,
    "work_" + name,
    label,
    state.work_fields.get("work_" + name).unwrap_or(""),
    multiline~,
  )
}

///|
fn render_collaboration_work(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
) -> @rabbita.Html {
  let disabled = state.busy() || state.dirty || state.revision.is_empty()
  let work = state.work.unwrap_or(
    @collaboration.empty_work(state.draft.draft_id, state.revision),
  )
  div(class="request-desk-stack", [
    h3("One-off participant work"),
    p(
      "Run the exact saved assignments once using isolated copies of the captured inputs. Saving, preparing and downloading the composer package do not run work. No schedules or participant Book writers are installed by Town. Configured runtime tools retain their existing role, workspace scope and approval policies.",
    ),
    div(class="request-actions", [
      button(
        attrs=@html.Attrs::build().disabled(disabled || state.prepared is None),
        on_click=dispatch(CollaborationAction("oneoff-start")),
        if work.status == "not_started" {
          "Run participants once"
        } else {
          "Resume / reconcile same work"
        },
      ),
      button(
        attrs=@html.Attrs::build().disabled(disabled),
        on_click=dispatch(CollaborationAction("oneoff-read")),
        "Collect / reconcile work status",
      ),
      if state.previous_revision.is_empty() {
        span("")
      } else {
        button(
          attrs=@html.Attrs::build().disabled(disabled),
          on_click=dispatch(
            CollaborationOpen(state.draft.draft_id, state.previous_revision),
          ),
          "Reopen previous source and its decisions",
        )
      },
    ]),
    p("Work status: " + work.status),
    p(work.detail),
    div(
      work.participants.map(participant => {
        div(class="request-desk-stack", [
          h3(participant.book_id + " · " + participant.status),
          p(
            "Private one-off store · Proposal: " +
            participant.proposal_id +
            " · Run: " +
            participant.run_id,
          ),
          p(participant.detail),
          p(participant.output_digest),
          @html.pre(
            class="collaboration-retained-output",
            participant.output_text,
          ),
        ])
      }),
    ),
    if work.result_digest.is_empty() {
      span("")
    } else {
      div(class="request-desk-stack", [
        h3("Review this exact collected result"),
        p(
          work.result_digest +
          " · review " +
          work.review_version.to_string() +
          " · " +
          work.review_status,
        ),
        p(
          "The result preserves each actual contribution, failure and authored objection. It does not invent agreement. Earlier decisions stay retained when a reviewer changes their decision or a new source revision is saved.",
        ),
        if work.operator_id.is_empty() {
          p(
            "Named-human authority is unavailable. Use the existing operator sign-in as the assigned reviewer. A name typed into the draft cannot approve the work.",
          )
        } else {
          p("Current operator account: " + work.operator_id)
        },
        div(
          work.decisions.map(decision => {
            div(class="request-desk-stack", [
              p(
                decision.reviewer_name +
                " (" +
                decision.reviewer_id +
                ") · " +
                decision.prompt,
              ),
              p(
                "Recorded decision: " +
                decision.decision +
                " · " +
                decision.rationale,
              ),
              button(
                attrs=@html.Attrs::build().disabled(
                  disabled || work.operator_id != decision.reviewer_id,
                ),
                on_click=dispatch(
                  CollaborationEdit("work_decision_id", decision.decision_id),
                ),
                "Select " + decision.decision_id,
              ),
            ])
          }),
        ),
        p(
          "Selected decision: " +
          state.work_fields.get("work_decision_id").unwrap_or("none"),
        ),
        div(
          class="request-actions",
          ["approve", "reject", "defer"].map(choice => {
            button(
              attrs=@html.Attrs::build().disabled(
                disabled || work.operator_id.is_empty(),
              ),
              on_click=dispatch(CollaborationEdit("work_decision", choice)),
              choice,
            )
          }),
        ),
        p(
          "Chosen outcome: " +
          state.work_fields.get("work_decision").unwrap_or("none"),
        ),
        work_field(
          dispatch,
          state,
          "rationale",
          "Why approve, reject or defer this exact result?",
          multiline=true,
        ),
        h3("Retained decision history"),
        @html.pre(
          class="collaboration-retained-output",
          work.review_history_text,
        ),
        button(
          attrs=@html.Attrs::build().disabled(
            disabled || work.operator_id.is_empty(),
          ),
          on_click=dispatch(CollaborationAction("oneoff-decide")),
          "Record my named-owner decision",
        ),
      ])
    },
    if !["completed", "partial"].contains(work.status) ||
      work.review_status != "accepted" {
      span("")
    } else {
      div(class="request-desk-stack", [
        h3("Submit this reviewed terminal outcome to Book"),
        p(
          work.participants
          .filter(p => p.status == "completed")
          .length()
          .to_string() +
          " participant(s) succeeded · " +
          work.participants
          .filter(p => p.status == "failed")
          .length()
          .to_string() +
          " failed. Review approves the accurate account, not a claim that all participants succeeded.",
        ),
        p(
          "Choose an existing destination and describe what the work establishes and what remains uncertain. Book independently reviews the deliverable and Three-Gap assessment.",
        ),
        div(
          class="request-actions",
          state.books.map(book => {
            button(
              attrs=@html.Attrs::build().disabled(disabled),
              on_click=dispatch(CollaborationEdit("work_book_id", book.book_id)),
              "Choose " + book.title,
            )
          }),
        ),
        p(
          "Destination: " +
          state.work_fields.get("work_book_id").unwrap_or("none"),
        ),
        work_field(
          dispatch,
          state,
          "outcome_summary",
          "Outcome interpretation and limits",
          multiline=true,
        ),
        div(
          ["information", "recognition", "decisiveness"].map(name => {
            div([
              work_field(
                dispatch,
                state,
                name + "_severity",
                name + " gap severity (0 absent, 1–5 present)",
              ),
              work_field(
                dispatch,
                state,
                name + "_summary",
                name + " gap explanation, including why it is absent if 0",
                multiline=true,
              ),
            ])
          }),
        ),
        p(
          "If any gap is present, name the proposed capability change. This is a proposal only; no activation is granted.",
        ),
        work_field(dispatch, state, "capability_id", "Proposed capability ID"),
        work_field(
          dispatch, state, "capability_version", "Proposed capability version",
        ),
        work_field(
          dispatch,
          state,
          "capability_summary",
          "Proposed capability change",
          multiline=true,
        ),
        button(
          attrs=@html.Attrs::build().disabled(disabled),
          on_click=dispatch(CollaborationAction("oneoff-book")),
          "Send retained outcome to chosen Book",
        ),
      ])
    },
    if work.package_digest.is_empty() {
      span("")
    } else {
      div([
        h3("Book disposition for this exact collaboration"),
        p(work.package_digest),
        p(work.book_status),
        p(
          "Historical local observation. Refresh reads Book's current disposition without accepting, continuing its review gates, activating a capability or rerunning participants.",
        ),
        button(
          attrs=@html.Attrs::build().disabled(disabled),
          on_click=dispatch(CollaborationAction("oneoff-read-book")),
          "Read Book disposition and reopen exact outcome",
        ),
      ])
    },
  ])
}
