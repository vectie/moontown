///|
fn render_collaboration_outcomes(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
) -> @rabbita.Html {
  div(class="request-desk-stack", [
    h3("Retained outcome library"),
    p(
      "Browse every retained source revision and inspect its actual contributions and attributed failures. Library reads never collect, run, schedule, or submit work. Prepared questions without a terminal dossier are marked not_retained; unavailable marks missing or corrupt evidence.",
    ),
    div(class="request-actions", [
      button(
        attrs=@html.Attrs::build().disabled(state.busy()),
        on_click=dispatch(CollaborationAction("outcome-list")),
        "Load / reload retained outcomes",
      ),
      button(
        on_click=dispatch(CollaborationCancel),
        "Cancel pending inspection or download",
      ),
    ]),
    p("Filter outcome"),
    div(
      class="request-actions",
      ["", "completed", "partial", "not_retained", "unavailable"].map(value => {
        button(
          attrs=@html.Attrs::build().aria_pressed(
            if state.outcome_filter == value {
              "true"
            } else {
              "false"
            },
          ),
          on_click=dispatch(CollaborationEdit("outcome_filter", value)),
          if value.is_empty() {
            "All outcomes"
          } else {
            value
          },
        )
      }),
    ),
    p("Filter review"),
    div(
      class="request-actions",
      [
        "", "pending_review", "rejected", "deferred", "accepted", "not_ready", "unavailable",
      ].map(value => {
        button(
          attrs=@html.Attrs::build().aria_pressed(
            if state.review_filter == value {
              "true"
            } else {
              "false"
            },
          ),
          on_click=dispatch(CollaborationEdit("review_filter", value)),
          if value.is_empty() {
            "All review states"
          } else {
            value
          },
        )
      }),
    ),
    p(state.visible_outcomes().length().to_string() + " matching revisions"),
    div(
      class="request-desk-stack",
      state
      .visible_outcomes()
      .map(entry => {
        div([
          p(entry.title + " · " + entry.draft_id + " · " + entry.recorded_at),
          p(entry.revision),
          p(
            entry.outcome_status +
            " · " +
            entry.review_status +
            " · review " +
            entry.review_version.to_string(),
          ),
          p(entry.error),
          button(
            attrs=@html.Attrs::build().disabled(
              state.busy() ||
              !["completed", "partial"].contains(entry.outcome_status),
            ),
            on_click=dispatch(CollaborationOutcomeOpen(entry.key())),
            "Inspect retained result and review " +
            entry.review_version.to_string(),
          ),
        ])
      }),
    ),
    match state.outcome {
      None => span("")
      Some(outcome) => {
        let work = outcome.work
        div(class="request-desk-stack", [
          h3("Selected retained dossier: " + outcome.saved.draft.title),
          p(outcome.key.draft_id + " · " + outcome.key.revision),
          p(
            "Outcome: " +
            work.status +
            " · selected review: " +
            outcome.key.review_version.to_string() +
            " · " +
            outcome.review_status,
          ),
          p(outcome.key.result_digest),
          p("Pinned review bytes: " + outcome.key.review_digest),
          p(
            "Pending, rejected and deferred dossiers remain downloadable. Review acceptance concerns this account; download never submits to Book or establishes Book acceptance.",
          ),
          p(
            "Choose an earlier retained review version; reload the library to discover later decisions",
          ),
          div(
            class="request-actions",
            outcome.reviews.map(review => {
              button(
                attrs=@html.Attrs::build().disabled(state.busy()),
                on_click=dispatch(
                  CollaborationOutcomeOpen({
                    ..outcome.key,
                    review_version: review.version,
                    review_digest: review.digest,
                  }),
                ),
                "Inspect review " + review.version.to_string(),
              )
            }),
          ),
          p("Question: " + outcome.saved.draft.question),
          p("Retained objection: " + outcome.saved.draft.objection),
          div(
            work.participants.map(participant => {
              div(class="request-desk-stack", [
                h3(participant.book_id + " · " + participant.status),
                p("Run: " + participant.run_id),
                p(participant.detail),
                p(participant.output_digest),
                @html.pre(
                  class="collaboration-retained-output",
                  participant.output_text,
                ),
              ])
            }),
          ),
          h3("Exact collected result"),
          @html.pre(class="collaboration-retained-output", work.result_text),
          h3("Selected review history"),
          @html.pre(
            class="collaboration-retained-output",
            work.review_history_text,
          ),
          div(
            work.decisions.map(decision => {
              p(
                decision.reviewer_name +
                " (" +
                decision.reviewer_id +
                ") · " +
                decision.decision_id +
                ": " +
                decision.decision +
                " · " +
                decision.rationale,
              )
            }),
          ),
          h3("Captured source bytes"),
          div(
            outcome.saved.sources.map(source => {
              p(
                source.book_id +
                "/" +
                source.source_path +
                " · " +
                source.size_bytes.to_string() +
                " bytes · " +
                source.digest,
              )
            }),
          ),
          button(
            class="request-submit",
            attrs=@html.Attrs::build().disabled(state.busy()),
            on_click=dispatch(CollaborationOutcomeDownload),
            "Download exact retained dossier (.tar)",
          ),
          p(
            "Archive: " +
            outcome.archive_digest +
            " · " +
            outcome.archive_size_bytes.to_string() +
            " bytes",
          ),
          p(
            "Includes a readable summary, exact collected result, attributed contributions and failures, binary-safe captured sources, selected review history and a byte-checked manifest",
          ),
        ])
      }
    },
  ])
}
