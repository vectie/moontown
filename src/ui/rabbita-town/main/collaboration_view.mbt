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
      "Exact source paths in " + p.book_id + " (one per line)",
      p.source_paths.join("\n"),
    ),
    ("focus_area", "Focus for " + p.book_id, p.focus_area),
    ("perspective", "Perspective for " + p.book_id, p.perspective),
    ("contribution", "Contribution from " + p.book_id, p.contribution),
    ("next_artifact", "Next artifact from " + p.book_id, p.next_artifact),
  ]
  div(class="request-desk-stack", [
    h3(p.book_id),
    button(
      attrs=@html.Attrs::build().disabled(state.busy()),
      on_click=dispatch(CollaborationBrowseSources(p.book_id)),
      "Browse current sources in " + p.book_id,
    ),
    if state.source_book == p.book_id {
      render_source_picker(dispatch, state, p)
    } else {
      span("")
    },
    @html.p(
      "Paths are relative to this Book, such as raw/notes.md. Saving captures exact bytes; each source is limited to 1 MiB.",
    ),
    div(
      class="request-form-grid",
      fields.map(field => {
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
  ])
}

///|
fn render_collaboration_composer(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
) -> @rabbita.Html {
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
  div(class="request-composer", [
    h3("协作研究"),
    p("选择至少两个知识册，分配任务并指定审阅人。"),
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
        town_ui_label("plus", "新草稿"),
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
      [fields[0], fields[6], fields[7], fields[8]],
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
        "准备交接",
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
          "New ID for reuse",
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
          "Reuse saved question as a fresh draft",
        ),
        p(
          "Reuse copies this exact saved revision's assignments and recaptures the selected current files. Prior review decisions are not carried forward.",
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
            "Download prepared plan package (.tar)",
          ),
          p(
            "The package retains nested source paths, prior review history, and SHA-256 manifest. Individual files below are convenient copies; use the complete package for review.",
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
                artifact.path.split("/").last().unwrap_or("artifact").to_owned(),
              )
            }),
          ),
        ])
    },
    if state.notice ==
      "Choose existing Books and exact source paths. Save incomplete drafts; prepare when assignments and reviewers are ready." {
      @html.nothing
    } else {
      p(
        attrs=@html.Attrs::build().role("status").aria_live("polite"),
        state.notice,
      )
    },
    if state.prepared is Some(_) || state.work is Some(_) {
      render_collaboration_work(dispatch, state)
    } else {
      @html.nothing
    },
    render_advanced_details(
      "历史成果与声明复核",
      compact_label="历史复核",
      [
        render_collaboration_outcomes(dispatch, state),
        render_claim_challenge(dispatch, state),
      ],
    ),
  ])
}
