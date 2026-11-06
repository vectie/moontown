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
    p(
      "选择成功成果中的原文片段，并填写独立质疑。可从多份历史记录中添加贡献，合计至少来自两本 Book。",
    ),
    render_advanced_details("所选成果的来源版本", [
      p(
        "来源：" +
        outcome.key.draft_id +
        " / " +
        outcome.key.revision +
        " / 审核 " +
        outcome.key.review_version.to_string() +
        " / " +
        outcome.key.review_digest,
      ),
    ]),
    render_advanced_details("保存与准备", [
      p(
        "未成功的 Book 保留为缺口；历史审核决定不代表新研究已获批准。",
      ),
      p(
        "保存会读取所选 Book 路径的当前文件，并在普通编辑器中打开新草稿。请先保存现有草稿；之后可修改分工和来源路径，再执行准备。此处不会自动运行研究。",
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
            (if selected { "已选择：" } else { "选择：" }) + p.book_id,
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
          "原文片段 · " + p.book_id + "（最多 1000 字符）",
          multiline=true,
        ),
      )
      content.push(
        retained_inquiry_field(
          dispatch,
          state,
          "challenge_" + p.book_id,
          "独立质疑 · " + p.book_id,
          multiline=true,
        ),
      )
    }
  }
  content.push(
    button(
      attrs=@html.Attrs::build().disabled(state.busy()),
      on_click=dispatch(CollaborationEdit("inquiry_add_dossier", "add")),
      if state.inquiry_dossiers.any(d => d.origin == outcome.key) {
        "更新所选贡献"
      } else {
        "加入研究"
      },
    ),
  )
  if !state.inquiry_dossiers.is_empty() {
    content.push(h3("跨记录研究"))
    content.push(
      p("从上方切换记录继续选择；修改片段后重新加入。"),
    )
    for dossier in state.inquiry_dossiers {
      content.push(
        p(
          dossier.origin.draft_id +
          " / " +
          dossier.origin.revision +
          " / 审核 " +
          dossier.origin.review_version.to_string(),
        ),
      )
      for selection in dossier.contributions {
        content.push(
          p(
            selection.book_id +
            ": " +
            selection.quote +
            "\n质疑：" +
            selection.challenge,
          ),
        )
      }
      content.push(
        button(
          attrs=@html.Attrs::build().disabled(state.busy()),
          on_click=dispatch(
            CollaborationEdit(
              "inquiry_remove_dossier",
              dossier.origin.to_json().stringify(),
            ),
          ),
          "移除此记录",
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
  let cross_dossier = !state.inquiry_dossiers.is_empty()
  let validation = if cross_dossier {
    state.cross_dossier_inquiry_preview()
  } else {
    state.retained_inquiry_preview()
  }
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
      on_click=dispatch(
        CollaborationAction(
          if cross_dossier {
            "cross-dossier-inquiry"
          } else {
            "retained-inquiry"
          },
        ),
      ),
      if cross_dossier {
        "保存跨记录研究"
      } else {
        "保存并编辑研究"
      },
    ),
  )
  content.push(
    button(
      attrs=@html.Attrs::build().disabled(state.busy()),
      on_click=dispatch(CollaborationEdit("inquiry_mode", "off")),
      "取消继续研究",
    ),
  )
  div(class="request-desk-stack", content)
}
