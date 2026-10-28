///|
fn retained_inquiry_field(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
  key : String,
  label : String,
  multiline~ : Bool = false,
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
      "继续研究",
    )
  }
  let content : Array[@rabbita.Html] = [
    h3("继续研究"),
    p("至少选择两份贡献。"),
    render_advanced_details("所选成果的来源版本", [
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
    ]),
  ]
  for p in @collaboration.salon_candidates(outcome.work) {
    let selected = state.inquiry_fields.get("inquiry_include_" + p.book_id) ==
      Some("yes")
    content.push(
      button(
        attrs=@html.Attrs::build()
          .disabled(state.busy())
          .aria_label(
            (if selected { "Selected: " } else { "Select: " }) + p.book_id,
          )
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
        town_ui_label(if selected { "check" } else { "plus" }, p.book_id),
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
      ("title", "研究标题"),
      ("question", "要研究的新问题"),
      ("falsifier", "什么观察结果会推翻假设？"),
      ("dissent", "需要保留的异议"),
      ("assumptions", "尚未验证的假设"),
      ("reviewer_name", "审阅人姓名"),
      ("objection_reviewer_name", "异议审阅人姓名"),
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
  content.push(
    render_advanced_details(
      "保存标识与审阅人身份",
      needs_attention=["id", "reviewer_id", "objection_reviewer_id"].any(key => {
        state.inquiry_fields.get("inquiry_" + key).unwrap_or("").is_empty()
      }),
      [
        retained_inquiry_field(dispatch, state, "id", "新草稿标识"),
        retained_inquiry_field(
          dispatch, state, "reviewer_id", "审阅人账户标识",
        ),
        retained_inquiry_field(
          dispatch, state, "objection_reviewer_id", "异议审阅人账户标识",
        ),
        p(
          "必须对应真实审阅账户；填写姓名不授予审核权限。",
        ),
      ],
    ),
  )
  if collaboration_has_unsaved_draft(state) {
    content.push(
      p("请先保存当前研究草稿，再保存这份新研究。"),
    )
  }
  let validation = state.retained_inquiry_preview()
  content.push(
    match validation {
      Ok(_) => @html.nothing
      Err(error) => p(attrs=@html.Attrs::build().role("status"), error)
    },
  )
  content.push(
    button(
      attrs=@html.Attrs::build().disabled(
        state.busy() ||
        validation is Err(_) ||
        collaboration_has_unsaved_draft(state),
      ),
      on_click=dispatch(CollaborationAction("retained-inquiry")),
      "保存并编辑研究",
    ),
  )
  content.push(
    button(
      on_click=dispatch(CollaborationEdit("inquiry_mode", "off")),
      "取消继续研究",
    ),
  )
  div(class="request-desk-stack", content)
}
