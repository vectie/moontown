///|
fn collaboration_field(
  id : String,
  label : String,
  value : String,
  disabled : Bool,
  on_input : (String) -> Cmd,
  multiline~ : Bool = false,
) -> @rabbita.Html {
  div(class="request-field", [
    @html.label(
      class="request-label",
      for_=id,
      collaboration_compact_label(label),
    ),
    if multiline {
      textarea(
        id~,
        class="request-textarea request-textarea-compact",
        value~,
        disabled~,
        on_input~,
        no_children(),
      )
    } else {
      input(
        id~,
        class="request-input",
        value~,
        attrs=@html.Attrs::build().disabled(disabled),
        on_input~,
      )
    },
  ])
}

///|
fn collaboration_compact_label(label : String) -> String {
  match label {
    "Collaboration title" => "名称"
    "Question for the participant Books" => "研究问题"
    "Human reviewer name" => "审阅人"
    "Human reviewer ID" => "审阅人标识"
    "Decision the reviewer must make" => "需要决定什么"
    "Collaboration draft ID" => "草稿标识"
    "Objection to retain (optional)" => "保留异议（选填）"
    "Objection decision owner ID" => "异议处理人标识"
    "Objection decision owner name" => "异议处理人"
    _ => label
  }
}

///|
fn collaboration_form_field(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
  field : String,
  label : String,
  value : String,
  multiline~ : Bool = false,
) -> @rabbita.Html {
  collaboration_field(
    "collaboration-" + field,
    label,
    value,
    state.busy(),
    v => dispatch(CollaborationEdit(field, v)),
    multiline~,
  )
}

///|
fn collaboration_participant_fields(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
  p : @collaboration.Participant,
) -> @rabbita.Html {
  let fields = [
    (
      "source_paths",
      "资料路径（每行一条）",
      p.source_paths.join("\n"),
    ),
    ("focus_area", "关注范围", p.focus_area),
    ("perspective", "独立研究角度", p.perspective),
    ("contribution", "需要回答什么", p.contribution),
    ("next_artifact", "交付什么", p.next_artifact),
  ]
  div(class="request-desk-stack", [
    h3(p.book_id),
    button(
      attrs=@html.Attrs::build().disabled(state.busy()),
      on_click=dispatch(CollaborationBrowseSources(p.book_id)),
      "选择资料",
    ),
    if state.source_book == p.book_id {
      render_source_picker(dispatch, state, p)
    } else {
      span("")
    },
    div(
      class="request-form-grid",
      fields
      .filter(field => field.0 != "source_paths")
      .map(field => {
        collaboration_field(
          "collaboration-" + p.book_id + "-" + field.0,
          field.1,
          field.2,
          state.busy(),
          value => {
            dispatch(CollaborationParticipantEdit(p.book_id, field.0, value))
          },
          multiline=field.0 != "focus_area",
        )
      }),
    ),
    render_advanced_details(
      "资料路径与任务细节",
      [
        @html.p(
          "也可填写知识册内的准确路径。保存时会记录所选资料，不会运行任务。",
        ),
        ..fields
        .filter(field => field.0 == "source_paths")
        .map(field => {
          collaboration_field(
            "collaboration-" + p.book_id + "-" + field.0,
            field.1,
            field.2,
            state.busy(),
            value => {
              dispatch(CollaborationParticipantEdit(p.book_id, field.0, value))
            },
            multiline=true,
          )
        }),
      ],
    ),
  ])
}

///|
fn render_collaboration_composer(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
) -> @rabbita.Html {
  if state.books.is_empty() &&
    state.drafts.is_empty() &&
    state.revision.is_empty() &&
    !state.busy() &&
    !collaboration_has_unsaved_draft(state) &&
    (
      state.notice.contains("Directory is missing") ||
      state.notice.contains("HTTP") ||
      state.notice == "Saved drafts and existing Books loaded"
    ) {
    return div(id="collaboration-compose", class="request-composer", [
      h3("连接研究资料"),
      p(
        "当前没有可参与协作的知识册。连接资料后重试，或先创建资料研究。",
      ),
      render_collaboration_notice(state),
      div(class="request-actions", [
        button(on_click=dispatch(CollaborationAction("list")), "重试连接"),
        button(
          on_click=dispatch(SetRequestComposer(EvidenceBookComposer)),
          "创建资料研究",
        ),
      ]),
    ])
  }
  let disabled = state.busy()
  let fields = [
    collaboration_form_field(
      dispatch,
      state,
      "draft_id",
      "Collaboration draft ID",
      state.draft.draft_id,
    ),
    collaboration_form_field(
      dispatch,
      state,
      "title",
      "Collaboration title",
      state.draft.title,
    ),
    collaboration_form_field(
      dispatch,
      state,
      "question",
      "Question for the participant Books",
      state.draft.question,
      multiline=true,
    ),
    collaboration_form_field(
      dispatch,
      state,
      "reviewer_id",
      "Human reviewer ID",
      state.draft.reviewer_id,
    ),
    collaboration_form_field(
      dispatch,
      state,
      "reviewer_name",
      "Human reviewer name",
      state.draft.reviewer_name,
    ),
    collaboration_form_field(
      dispatch,
      state,
      "decision_prompt",
      "Decision the reviewer must make",
      state.draft.decision_prompt,
      multiline=true,
    ),
    collaboration_form_field(
      dispatch,
      state,
      "objection",
      "Objection to retain (optional)",
      state.draft.objection,
      multiline=true,
    ),
    collaboration_form_field(
      dispatch,
      state,
      "objection_reviewer_id",
      "Objection decision owner ID",
      state.draft.objection_reviewer_id,
    ),
    collaboration_form_field(
      dispatch,
      state,
      "objection_reviewer_name",
      "Objection decision owner name",
      state.draft.objection_reviewer_name,
    ),
  ]
  div(id="collaboration-compose", class="request-composer", [
    h3("协作研究"),
    p(
      "选择资料和参与知识册，写下问题，再指定审阅人。保存草稿不会启动任务。",
    ),
    div(class="request-actions", [
      button(
        class="control-button",
        attrs=@html.Attrs::build().disabled(disabled),
        on_click=dispatch(CollaborationAction("list")),
        town_ui_label("book", "载入知识册"),
      ),
      button(
        class="control-button",
        on_click=dispatch(CollaborationReset),
        town_ui_label("plus", "新建研究"),
      ),
    ]),
    div(
      class="request-actions",
      state.drafts.map(saved => {
        button(
          attrs=@html.Attrs::build().disabled(disabled),
          title=saved.draft.draft_id,
          on_click=dispatch(
            CollaborationOpen(saved.draft.draft_id, saved.revision),
          ),
          "打开：" + saved.draft.title,
        )
      }),
    ),
    div(class="request-form-grid", [
      fields[1],
      fields[2],
      fields[4],
      fields[3],
      fields[5],
    ]),
    render_advanced_details(
      "草稿标识与可选异议",
      compact_label="草稿选项",
      needs_attention=!@collaboration.safe_id(state.draft.draft_id) ||
        !state.draft.objection.is_empty(),
      [
        p(
          "审阅人标识必须对应实际登录账户；显示姓名本身不能授予审核权限。",
        ),
        fields[0],
        fields[6],
        fields[7],
        fields[8],
      ],
    ),
    @html.details(class="collaboration-book-picker", [
      @html.summary(
        town_ui_label(
          "book",
          "参与知识册 · 已选 \{state.draft.participants.length()}",
        ),
      ),
      div(
        class="request-actions collaboration-book-options",
        state.books.map(book => {
          let selected = state.draft.participants.any(p => {
            p.book_id == book.book_id
          })
          button(
            class=if selected {
              "request-action-button is-active"
            } else {
              "request-action-button"
            },
            attrs=@html.Attrs::build()
              .disabled(disabled)
              .aria_pressed(if selected { "true" } else { "false" }),
            on_click=dispatch(CollaborationToggleBook(book.book_id)),
            title=book.book_id,
            book.title,
          )
        }),
      ),
    ]),
    div(
      class="request-desk-stack",
      state.draft.participants.map(participant => {
        collaboration_participant_fields(dispatch, state, participant)
      }),
    ),
    div(class="request-actions", [
      button(
        class="request-submit",
        title="保存草稿并记录当前来源",
        attrs=@html.Attrs::build().disabled(disabled),
        on_click=dispatch(CollaborationAction("save")),
        "保存草稿",
      ),
      button(
        class="request-submit",
        attrs=@html.Attrs::build().disabled(
          disabled || state.dirty || state.revision.is_empty(),
        ),
        on_click=dispatch(CollaborationAction("prepare")),
        "准备任务",
      ),
    ]),
    render_advanced_details(
      "来源记录与草稿复用",
      compact_label="来源记录",
      [
        if state.revision.is_empty() {
          span("")
        } else {
          p("Saved revision: " + state.revision)
        },
        div(
          state.sources.map(source => {
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
        collaboration_form_field(
          dispatch,
          state,
          "new_draft_id",
          "继续研究的新草稿标识",
          state.new_draft_id,
        ),
        button(
          attrs=@html.Attrs::build().disabled(
            disabled ||
            state.revision.is_empty() ||
            state.dirty ||
            !@collaboration.safe_id(state.new_draft_id),
          ),
          on_click=dispatch(CollaborationAction("reuse")),
          "继续研究 · 复用此问题",
        ),
        p(
          "复用会重新记录当前资料，不会继承原来的审核决定。",
        ),
      ],
    ),
    match state.prepared {
      None => span("")
      Some(prepared) =>
        div(class="request-desk-stack", [
          button(
            class="request-submit",
            attrs=@html.Attrs::build().disabled(disabled),
            on_click=dispatch(CollaborationDownload("")),
            "下载任务包",
          ),
          render_advanced_details("任务包文件与来源", [
            p(
              "完整任务包保留资料路径、来源记录与历史审核；下方为单文件副本。",
            ),
            div(
              class="request-actions",
              prepared.artifacts
              .filter(a => {
                a.path.has_prefix("revisions/" + state.revision + "/") &&
                !a.path.contains("/sources/")
              })
              .map(artifact => {
                button(
                  attrs=@html.Attrs::build().disabled(disabled),
                  on_click=dispatch(CollaborationDownload(artifact.path)),
                  "Download " +
                  artifact.path
                  .split("/")
                  .last()
                  .unwrap_or("artifact")
                  .to_owned(),
                )
              }),
            ),
          ]),
        ])
    },
    render_collaboration_notice(state),
    if state.prepared is Some(_) || state.work is Some(_) {
      render_collaboration_work(dispatch, state)
    } else {
      @html.nothing
    },
    render_advanced_details(
      "从声明比较继续研究",
      compact_label="导入比较",
      [render_claim_challenge(dispatch, state)],
    ),
  ])
}
