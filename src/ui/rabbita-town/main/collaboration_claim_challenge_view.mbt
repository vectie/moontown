///|
fn claim_challenge_field(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
  key : String,
  label : String,
  multiline~ : Bool = false,
) -> @rabbita.Html {
  collaboration_field(
    "collaboration-claim-" + key,
    label,
    state.claim_fields.get("claim_" + key).unwrap_or(""),
    state.busy(),
    value => dispatch(CollaborationEdit("claim_" + key, value)),
    multiline~,
  )
}

///|
fn render_claim_challenge(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
) -> @rabbita.Html {
  if state.claim_fields.get("claim_mode") != Some("compose") {
    return button(
      attrs=@html.Attrs::build().disabled(state.busy()),
      on_click=dispatch(CollaborationEdit("claim_mode", "compose")),
      "继续研究 · 质疑声明",
    )
  }
  let content : Array[@rabbita.Html] = [
    h3("继续研究 · 质疑声明"),
    p(
      "Paste JSON from claim_compare, then explicitly select one group and map each imported label/path to a registered Book and current relative source path. Imported labels are not catalog identities. Different exact values are candidate differences, not semantic contradictions.",
    ),
    claim_challenge_field(
      dispatch,
      state,
      "report",
      "moontown.claim-comparison.v1 report (up to 32 KiB)",
      multiline=true,
    ),
    button(
      attrs=@html.Attrs::build().disabled(state.busy()),
      on_click=dispatch(CollaborationAction("list")),
      "Load registered Books",
    ),
  ]
  match
    @collaboration.decode_claim_comparison(
      state.claim_fields.get("claim_report").unwrap_or(""),
    ) {
    Err(error) => content.push(p(error))
    Ok(report) => {
      content.push(
        p("Reported table digest (unverified table): " + report.table_digest),
      )
      for index, group in report.groups {
        let selected = state.claim_fields.get("claim_group") ==
          Some(index.to_string())
        content.push(
          button(
            attrs=@html.Attrs::build()
              .disabled(state.busy())
              .aria_pressed(if selected { "true" } else { "false" }),
            on_click=dispatch(
              CollaborationEdit("claim_group", index.to_string()),
            ),
            (if selected { "Selected: " } else { "Select: " }) +
            group.topic +
            " · " +
            group.context +
            " · " +
            group.state,
          ),
        )
        if selected {
          for i, claim in group.claims {
            let suffix = i.to_string()
            let source = report.sources.filter(s => s.path == claim.source_path)[0]
            content.push(
              div(class="request-desk-stack", [
                h3("Claim " + claim.claim_id),
                p(
                  "Imported label: " +
                  claim.book_id +
                  " · imported path: " +
                  claim.source_path,
                ),
                p("Exact labelled value: " + claim.value),
                @html.pre(class="collaboration-retained-output", claim.quote),
                p(
                  source.digest +
                  " · " +
                  source.size_bytes.to_string() +
                  " bytes",
                ),
                p("Explicitly choose the registered Book for this claim:"),
                div(
                  state.books.map(book => {
                    button(
                      attrs=@html.Attrs::build()
                        .disabled(state.busy())
                        .aria_pressed(
                          if state.claim_fields.get("claim_book_" + suffix) ==
                            Some(book.book_id) {
                            "true"
                          } else {
                            "false"
                          },
                        ),
                      on_click=dispatch(
                        CollaborationEdit("claim_book_" + suffix, book.book_id),
                      ),
                      book.title + " (" + book.book_id + ")",
                    )
                  }),
                ),
                p(
                  "Mapped Book: " +
                  state.claim_fields
                  .get("claim_book_" + suffix)
                  .unwrap_or("not selected"),
                ),
                claim_challenge_field(
                  dispatch,
                  state,
                  "path_" + suffix,
                  "Current workspace-relative source path",
                ),
                claim_challenge_field(
                  dispatch,
                  state,
                  "challenge_" + suffix,
                  "Independent challenge: what should this Book try to disprove?",
                  multiline=true,
                ),
              ]),
            )
          }
        }
      }
    }
  }
  for
    (key, label) in [
      ("title", "Challenge title"),
      ("question", "Question to investigate"),
      ("falsifier", "Observable result that would disprove the proposed answer"),
      ("reviewer_name", "Human plan reviewer name"),
      ("objection", "Objection to preserve (optional)"),
      ("objection_reviewer_name", "Objection decision owner name"),
    ] {
    content.push(
      claim_challenge_field(
        dispatch,
        state,
        key,
        label,
        multiline=["question", "falsifier", "objection"].contains(key),
      ),
    )
  }
  content.push(
    render_advanced_details(
      "保存标识与审阅人身份",
      needs_attention=["id", "reviewer_id"].any(key => {
        state.claim_fields.get("claim_" + key).unwrap_or("").is_empty()
      }),
      [
        claim_challenge_field(dispatch, state, "id", "新草稿标识"),
        claim_challenge_field(
          dispatch, state, "reviewer_id", "审阅人账户标识",
        ),
        claim_challenge_field(
          dispatch, state, "objection_reviewer_id", "异议审阅人账户标识",
        ),
        p(
          "必须对应真实审阅账户；填写姓名不授予审核权限。",
        ),
      ],
    ),
  )
  let validation = match state.claim_challenge_input() {
    Ok(input) => @collaboration.claim_challenge_draft(input, state.books)
    Err(error) => Err(error)
  }
  if collaboration_has_unsaved_draft(state) {
    content.push(
      p("请先保存当前研究草稿，再保存这份新研究。"),
    )
  }
  content.push(
    p(
      match validation {
        Ok(_) =>
          "可以保存并编辑研究。准备与执行仍需分别确认。"
        Err(error) => error
      },
    ),
  )
  content.push(
    button(
      attrs=@html.Attrs::build().disabled(
        state.busy() ||
        validation is Err(_) ||
        collaboration_has_unsaved_draft(state),
      ),
      on_click=dispatch(CollaborationAction("claim-challenge")),
      "保存并编辑研究",
    ),
  )
  content.push(
    button(
      on_click=dispatch(CollaborationEdit("claim_mode", "off")),
      "取消继续研究",
    ),
  )
  div(class="request-desk-stack", content)
}
