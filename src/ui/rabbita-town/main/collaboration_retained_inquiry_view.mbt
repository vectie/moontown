///|
fn retained_inquiry_field(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
  key : String,
  label : String,
  multiline? : Bool = false,
) -> @rabbita.Html {
  collaboration_field(
    "collaboration-inquiry-" + key,
    label,
    state.inquiry_fields.get("inquiry_" + key).unwrap_or(""),
    state.busy(),
    value => dispatch(CollaborationEdit("inquiry_" + key, value)),
    multiline~,
  )
}

///|
fn render_retained_inquiry(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
  outcome : @collaboration.RetainedOutcome,
) -> @rabbita.Html {
  if state.inquiry_fields.get("inquiry_mode") != Some("compose") {
    return button(
      attrs=@html.Attrs::build().disabled(
        state.busy() || !@collaboration.salon_ready(outcome.work),
      ),
      on_click=dispatch(CollaborationEdit("inquiry_mode", "compose")),
      "Use retained contributions in a new research-salon inquiry",
    )
  }
  let content : Array[@rabbita.Html] = [
    h3("New inquiry from this historical dossier"),
    p(
      "Select at least two successful Books and copy exact passages from their retained outputs above. Write a new question and independent challenges. Failed Books remain named gaps. Historical decisions do not approve this inquiry.",
    ),
    p(
      "Pinned origin: " +
      outcome.key.draft_id +
      " / " +
      outcome.key.revision +
      " / review " +
      outcome.key.review_version.to_string() +
      " / " +
      outcome.key.review_digest,
    ),
    p(
      "Saving captures current files at the original selected Book paths and opens the new saved draft in the ordinary composer. Save any existing composer edits first. You can then edit assignments and source paths before Prepare; no work runs here.",
    ),
  ]
  for p in @collaboration.salon_candidates(outcome.work) {
    let selected = state.inquiry_fields.get("inquiry_include_" + p.book_id) ==
      Some("yes")
    content.push(
      button(
        attrs=@html.Attrs::build()
          .disabled(state.busy())
          .aria_pressed(if selected { "true" } else { "false" }),
        on_click=dispatch(
          CollaborationEdit(
            "inquiry_include_" + p.book_id,
            if selected {
              "no"
            } else {
              "yes"
            },
          ),
        ),
        (if selected { "Selected: " } else { "Select: " }) + p.book_id,
      ),
    )
    if selected {
      content.push(
        retained_inquiry_field(
          dispatch,
          state,
          "quote_" + p.book_id,
          "Exact retained excerpt from " +
          p.book_id +
          " (up to 1000 characters)",
          multiline=true,
        ),
      )
      content.push(
        retained_inquiry_field(
          dispatch,
          state,
          "challenge_" + p.book_id,
          "Independent challenge for " + p.book_id,
          multiline=true,
        ),
      )
    }
  }
  for
    (key, label) in [
      ("id", "New inquiry draft ID"),
      ("title", "New inquiry title"),
      ("question", "New scoped research question"),
      ("falsifier", "Observable result that would disprove the proposed answer"),
      ("dissent", "Dissent to preserve"),
      ("assumptions", "Unresolved assumptions"),
      ("reviewer_id", "New inquiry human reviewer ID"),
      ("reviewer_name", "New inquiry human reviewer name"),
      ("objection_reviewer_id", "Objection decision owner ID"),
      ("objection_reviewer_name", "Objection decision owner name"),
    ] {
    content.push(
      retained_inquiry_field(
        dispatch,
        state,
        key,
        label,
        multiline=["question", "falsifier", "dissent", "assumptions"].contains(
          key,
        ),
      ),
    )
  }
  let validation = state.retained_inquiry_preview()
  content.push(
    p(
      match validation {
        Ok(_) =>
          "Ready to verify retained evidence and save a new editable inquiry. Current Book sources must still exist."
        Err(error) => error
      },
    ),
  )
  content.push(
    button(
      attrs=@html.Attrs::build().disabled(state.busy() || validation is Err(_)),
      on_click=dispatch(CollaborationAction("retained-inquiry")),
      "Save new inquiry and open in composer",
    ),
  )
  content.push(
    button(
      on_click=dispatch(CollaborationEdit("inquiry_mode", "off")),
      "Cancel new inquiry",
    ),
  )
  div(class="request-desk-stack", content)
}
