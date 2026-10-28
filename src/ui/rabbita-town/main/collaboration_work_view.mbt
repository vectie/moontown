///|
fn work_field(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
  name : String,
  label : String,
  multiline~ : Bool = false,
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
fn collaboration_book_assessment_needs_attention(
  state : @collaboration.Client,
) -> Bool {
  let mut has_gap = false
  for name in ["information", "recognition", "decisiveness"] {
    let severity = @string.parse_int(
      state.work_fields.get("work_" + name + "_severity").unwrap_or("").trim(),
    ) catch {
      _ => return true
    }
    if severity < 0 ||
      severity > 5 ||
      state.work_fields
      .get("work_" + name + "_summary")
      .unwrap_or("")
      .trim()
      .is_empty() {
      return true
    }
    has_gap = has_gap || severity > 0
  }
  has_gap &&
  ["capability_id", "capability_version", "capability_summary"].any(name => {
    state.work_fields.get("work_" + name).unwrap_or("").trim().is_empty()
  })
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
    h3("任务进度"),
    p(collaboration_status_label(work.status)),
    div(class="request-actions", [
      if work.status == "not_started" && state.prepared is Some(_) {
        button(
          class="request-submit",
          attrs=@html.Attrs::build().disabled(disabled),
          on_click=dispatch(CollaborationAction("oneoff-start")),
          "开始执行",
        )
      } else {
        @html.nothing
      },
      button(
        class="control-button",
        attrs=@html.Attrs::build().disabled(disabled),
        on_click=dispatch(CollaborationAction("oneoff-read")),
        if state.work is None {
          "读取任务进度"
        } else {
          "刷新进度"
        },
      ),
    ]),
    div(
      work.participants.map(participant => {
        div(class="request-desk-stack", [
          h3(
            participant.book_id +
            " · " +
            collaboration_status_label(participant.status),
          ),
          if participant.status == "failed" {
            p(participant.detail)
          } else {
            @html.nothing
          },
          if state.work_fields.get("work_salon_mode") == Some("compare") &&
            participant.status == "completed" {
            @html.nothing
          } else {
            @html.pre(
              class="collaboration-retained-output",
              participant.output_text,
            )
          },
        ])
      }),
    ),
    render_idea_salon(dispatch, state, work),
    render_collective_experiment(dispatch, state, work),
    if work.result_digest.is_empty() {
      span("")
    } else {
      div(class="request-desk-stack", [
        h3(id="collaboration-review", "审核结果"),
        p(collaboration_status_label(work.review_status)),
        if collaboration_my_pending_reviews(work) > 0 {
          p(
            "待我审核 · \{collaboration_my_pending_reviews(work)} 项决定",
          )
        } else {
          @html.nothing
        },
        if work.operator_id.is_empty() {
          p("仅指定审阅人可审核。")
        } else {
          @html.nothing
        },
        div(
          work.decisions.map(decision => {
            div(class="request-desk-stack", [
              p(decision.reviewer_name + " · " + decision.prompt),
              p(
                collaboration_status_label(decision.decision) +
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
                "处理这项决定",
              ),
            ])
          }),
        ),
        p("选择上方属于你的决定，再提交结论和理由。"),
        div(
          class="request-actions",
          ["approve", "reject", "defer"].map(choice => {
            button(
              attrs=@html.Attrs::build().disabled(
                disabled || work.operator_id.is_empty(),
              ),
              on_click=dispatch(CollaborationEdit("work_decision", choice)),
              match choice {
                "approve" => "批准记录"
                "reject" => "拒绝"
                _ => "暂缓"
              },
            )
          }),
        ),
        p(
          "所选结论：" +
          collaboration_status_label(
            state.work_fields.get("work_decision").unwrap_or(""),
          ),
        ),
        work_field(dispatch, state, "rationale", "决定理由", multiline=true),
        button(
          attrs=@html.Attrs::build().disabled(
            disabled || work.operator_id.is_empty(),
          ),
          on_click=dispatch(CollaborationAction("oneoff-decide")),
          "提交我的决定",
        ),
      ])
    },
    if !["completed", "partial"].contains(work.status) ||
      work.review_status != "accepted" {
      span("")
    } else {
      div(class="request-desk-stack", [
        h3("送入知识册"),
        p(
          work.participants
          .filter(p => p.status == "completed")
          .length()
          .to_string() +
          " 项成功 · " +
          work.participants
          .filter(p => p.status == "failed")
          .length()
          .to_string() +
          " 项失败。提交后仍由知识册独立审核。",
        ),
        p("选择目标知识册，说明成果与局限。"),
        div(
          class="request-actions",
          state.books.map(book => {
            button(
              attrs=@html.Attrs::build().disabled(disabled),
              on_click=dispatch(CollaborationEdit("work_book_id", book.book_id)),
              book.title,
            )
          }),
        ),
        p(
          "目标知识册：" +
          state.work_fields.get("work_book_id").unwrap_or("未选择"),
        ),
        work_field(
          dispatch,
          state,
          "outcome_summary",
          "成果说明与局限",
          multiline=true,
        ),
        render_advanced_details(
          "知识册要求的缺口评估与能力提案",
          compact_label="专业评估",
          needs_attention=collaboration_book_assessment_needs_attention(state),
          [
            div(
              ["information", "recognition", "decisiveness"].map(name => {
                let label = match name {
                  "information" => "信息"
                  "recognition" => "认知"
                  _ => "决策"
                }
                div([
                  work_field(
                    dispatch,
                    state,
                    name + "_severity",
                    label + "缺口（0 无，1–5 有）",
                  ),
                  work_field(
                    dispatch,
                    state,
                    name + "_summary",
                    label + "缺口说明（无缺口也需说明依据）",
                    multiline=true,
                  ),
                ])
              }),
            ),
            p(
              "请如实填写知识册要求的缺口评估；不能省略为零。若有缺口，填写建议能力变更；这不会激活能力。",
            ),
            work_field(
              dispatch, state, "capability_id", "建议能力标识（有缺口时填写）",
            ),
            work_field(
              dispatch, state, "capability_version", "建议能力版本",
            ),
            work_field(
              dispatch,
              state,
              "capability_summary",
              "建议能力变更",
              multiline=true,
            ),
          ],
        ),
        button(
          attrs=@html.Attrs::build().disabled(disabled),
          on_click=dispatch(CollaborationAction("oneoff-book")),
          if state.work_fields.get("work_salon_mode") == Some("compare") {
            "送入知识册 · 所选方案"
          } else {
            "提交到知识册"
          },
        ),
      ])
    },
    if work.package_digest.is_empty() {
      span("")
    } else {
      div([
        h3("知识册处理状态"),
        p(collaboration_status_label(work.book_status)),
        p(
          "这是上次读取的状态。刷新不会接受知识、激活能力或重跑任务。",
        ),
        button(
          attrs=@html.Attrs::build().disabled(disabled),
          on_click=dispatch(CollaborationAction("oneoff-read-book")),
          "刷新知识册状态",
        ),
      ])
    },
    render_advanced_details("执行证据、历史版本与恢复", [
      p(work.detail),
      p("当前账户：" + work.operator_id),
      p(work.result_digest),
      p(work.package_digest),
      div(
        work.participants.map(participant => {
          p(
            participant.book_id +
            " · Proposal: " +
            participant.proposal_id +
            " · Run: " +
            participant.run_id +
            " · " +
            participant.output_digest,
          )
        }),
      ),
      h3("完整审核历史"),
      @html.pre(class="collaboration-retained-output", work.review_history_text),
      if work.status == "running" {
        button(
          attrs=@html.Attrs::build().disabled(
            disabled || state.prepared is None,
          ),
          on_click=dispatch(CollaborationAction("oneoff-start")),
          "恢复原任务 · 不创建新执行",
        )
      } else {
        @html.nothing
      },
      if state.previous_revision.is_empty() {
        @html.nothing
      } else {
        button(
          attrs=@html.Attrs::build().disabled(disabled),
          on_click=dispatch(
            CollaborationOpen(state.draft.draft_id, state.previous_revision),
          ),
          "查看上一来源版本",
        )
      },
    ]),
  ])
}
