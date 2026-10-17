///|
fn render_collective_experiment(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
  work : @collaboration.OneoffWork,
) -> @rabbita.Html {
  let disabled = state.busy() || state.dirty || state.revision.is_empty()
  if !@collaboration.salon_ready(work) {
    return p(
      "Cross-Book experiments need two completed contributions and a settled result.",
    )
  }
  if state.work_fields.get("work_collective_mode") != Some("compose") {
    return button(
      attrs=@html.Attrs::build().disabled(disabled),
      on_click=dispatch(CollaborationEdit("work_collective_mode", "compose")),
      "Combine contributions into a new experiment",
    )
  }
  let saved : @collaboration.SavedDraft = {
    contract_version: "moontown.collaboration-draft.v1",
    draft: state.draft,
    revision: state.revision,
    previous_revision: state.previous_revision,
    recorded_at: "",
    sources: state.sources,
  }
  let validation = @collaboration.collective_followup(
    saved,
    work,
    collaboration_work_payload(state),
  )
  div(class="request-desk-stack", [
    h3("Compose a cross-Book experiment"),
    p(
      "Connect evidence from every completed Book into one testable hypothesis, then ask those Books to challenge it independently. These are operator-authored proposals; participation does not mean agreement or verified emergence.",
    ),
    work_field(
      dispatch, state, "collective_new_id", "New peer-challenge draft ID",
    ),
    work_field(
      dispatch, state, "collective_title", "Experiment title (up to 200 characters)",
    ),
    work_field(
      dispatch,
      state,
      "collective_hypothesis",
      "Combined hypothesis: what becomes possible by connecting these contributions?",
      multiline=true,
    ),
    div(
      @collaboration.salon_candidates(work).map(candidate => {
        div(class="request-desk-stack", [
          h3("Connect " + candidate.book_id),
          p(
            "Retained run " +
            candidate.run_id +
            " · " +
            candidate.output_digest,
          ),
          @html.pre(
            class="collaboration-retained-output",
            candidate.output_text,
          ),
          work_field(
            dispatch,
            state,
            "collective_quote_" + candidate.book_id,
            "Exact supporting passage (up to 1000 characters)",
            multiline=true,
          ),
          work_field(
            dispatch,
            state,
            "collective_connection_" + candidate.book_id,
            "How does this evidence change the combined hypothesis?",
            multiline=true,
          ),
          work_field(
            dispatch,
            state,
            "collective_challenge_" + candidate.book_id,
            "What should this Book challenge or try to disprove?",
            multiline=true,
          ),
        ])
      }),
    ),
    work_field(
      dispatch,
      state,
      "collective_experiment",
      "Smallest experiment: method, observation and constraints",
      multiline=true,
    ),
    work_field(
      dispatch,
      state,
      "collective_falsifier",
      "What observable result would disprove the hypothesis?",
      multiline=true,
    ),
    p("Original independently owned objection: " + state.draft.objection),
    work_field(
      dispatch,
      state,
      "collective_dissent",
      "Contradictions and dissent the next round must preserve",
      multiline=true,
    ),
    work_field(
      dispatch,
      state,
      "collective_assumptions",
      "Unresolved assumptions and missing evidence",
      multiline=true,
    ),
    p(
      "Failed Books remain attributed in the proposal and are not assigned successful evidence. The new round keeps exact prior excerpts and captures current files from the original selected paths. It gets fresh work and review state; no approval is inherited. Saving does not run agents or execute the experiment.",
    ),
    p(
      match validation {
        Ok(_) =>
          "Ready to save a new peer-challenge round. Prepare and run remain separate explicit actions."
        Err(error) => error
      },
    ),
    button(
      attrs=@html.Attrs::build().disabled(disabled || validation is Err(_)),
      on_click=dispatch(CollaborationAction("oneoff-followup")),
      "Save experiment as a new peer-challenge round",
    ),
    button(
      attrs=@html.Attrs::build().disabled(disabled),
      on_click=dispatch(CollaborationEdit("work_collective_mode", "off")),
      "Discard experiment notes",
    ),
  ])
}
