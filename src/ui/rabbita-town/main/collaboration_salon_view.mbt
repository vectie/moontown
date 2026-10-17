///|
fn render_idea_salon(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
  work : @collaboration.OneoffWork,
) -> @rabbita.Html {
  let disabled = state.busy() || state.dirty || state.revision.is_empty()
  if !@collaboration.salon_ready(work) {
    return p(
      "Idea salon: collect at least two completed contributions to compare. Missing or failed Books remain visible above; they never count as consensus.",
    )
  }
  if state.work_fields.get("work_salon_mode") != Some("compare") {
    return button(
      attrs=@html.Attrs::build().disabled(disabled),
      on_click=dispatch(CollaborationEdit("work_salon_mode", "compare")),
      "Compare ideas from these Books",
    )
  }
  div(class="request-desk-stack", [
    h3("Run an idea salon: compare and choose"),
    p("Question: " + state.draft.question),
    p(
      "Compare the returned outputs against the same criterion, then choose one proposal for Book review. These are your assessments, not generated agent votes. Fixture outputs remain fixture rehearsals; this worksheet does not establish genuine autonomous emergence.",
    ),
    work_field(
      dispatch,
      state,
      "salon_basis",
      "Comparison criterion: what makes an idea worth pursuing?",
      multiline=true,
    ),
    div(
      @collaboration.salon_candidates(work).map(candidate => {
        div(class="request-desk-stack", [
          h3(candidate.book_id),
          p("Run " + candidate.run_id + " · " + candidate.output_digest),
          @html.pre(
            class="collaboration-retained-output",
            candidate.output_text,
          ),
          work_field(
            dispatch,
            state,
            "salon_assessment_" + candidate.book_id,
            "Assess " +
            candidate.book_id +
            " against your criterion, citing its evidence and limits",
            multiline=true,
          ),
          button(
            attrs=@html.Attrs::build().disabled(disabled),
            on_click=dispatch(
              CollaborationEdit("work_salon_selected_book", candidate.book_id),
            ),
            if state.work_fields.get("work_salon_selected_book") ==
              Some(candidate.book_id) {
              "Selected: " + candidate.book_id
            } else {
              "Choose " + candidate.book_id + " for Book review"
            },
          ),
        ])
      }),
    ),
    work_field(
      dispatch,
      state,
      "salon_rationale",
      "Why this selected idea?",
      multiline=true,
    ),
    work_field(
      dispatch,
      state,
      "salon_alternatives",
      "Alternatives kept and why they were not selected",
      multiline=true,
    ),
    p("Original independently owned objection: " + state.draft.objection),
    work_field(
      dispatch,
      state,
      "salon_dissent",
      "Dissent preserved, including the objection above; explain if none was returned",
      multiline=true,
    ),
    work_field(
      dispatch,
      state,
      "salon_assumptions",
      "Unresolved assumptions and the next evidence needed",
      multiline=true,
    ),
    p(
      "Complete the named-owner result review below, choose a destination Book, and use Send selected salon outcome to chosen Book. Your comparison and selection travel with the exact source/output dossier for Book's independent review. Notes are kept in this open form until submitted; changing the question or source clears them.",
    ),
    button(
      attrs=@html.Attrs::build().disabled(disabled),
      on_click=dispatch(CollaborationEdit("work_salon_mode", "off")),
      "Discard comparison notes",
    ),
  ])
}
