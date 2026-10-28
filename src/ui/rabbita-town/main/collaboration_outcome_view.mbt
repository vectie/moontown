///|
fn render_collaboration_outcomes(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
) -> @rabbita.Html {
  section(id="collaboration-results", class="request-desk-stack", [
    h3("研究记录"),
    div(class="request-actions", [
      button(
        class="control-button",
        title="刷新成果",
        attrs=@html.Attrs::build()
          .aria_label("刷新成果")
          .disabled(state.busy()),
        on_click=dispatch(CollaborationAction("outcome-list")),
        town_ui_icon("reset"),
      ),
      button(
        class="control-button",
        on_click=dispatch(ImportedOutputsEvent(OpenImportedOutputs)),
        town_ui_label("download", "导入成果"),
      ),
      if state.busy() {
        button(on_click=dispatch(CollaborationCancel), "取消读取")
      } else {
        @html.nothing
      },
    ]),
    render_collaboration_notice(state),
    if state.outcomes.is_empty() {
      @html.nothing
    } else {
      render_advanced_details("筛选成果", [
        div(
          class="request-actions",
          ["", "pending_review", "accepted", "rejected", "deferred"].map(value => {
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
                "全部"
              } else {
                collaboration_status_label(value)
              },
            )
          }),
        ),
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
                "全部执行状态"
              } else {
                collaboration_status_label(value)
              },
            )
          }),
        ),
        p(
          "记录已审核不代表知识册已接受；这里读取已保存的成果。",
        ),
      ])
    },
    if state.visible_outcomes().is_empty() {
      p(
        if state.outcomes.is_empty() {
          "还没有成果。完成并收集研究结果后，会显示在这里。"
        } else {
          "没有符合筛选的成果。可调整高级筛选或刷新列表。"
        },
      )
    } else {
      div(
        class="request-desk-stack",
        state
        .visible_outcomes()
        .map(entry => {
          article([
            h3(entry.title),
            p(
              collaboration_status_label(entry.outcome_status) +
              " · " +
              collaboration_status_label(entry.review_status),
            ),
            p(entry.recorded_at),
            if entry.error.is_empty() {
              @html.nothing
            } else {
              p(entry.error)
            },
            button(
              class="control-button",
              attrs=@html.Attrs::build().disabled(
                state.busy() ||
                !["completed", "partial"].contains(entry.outcome_status),
              ),
              on_click=dispatch(CollaborationOutcomeOpen(entry.key())),
              "查看成果",
            ),
            render_advanced_details("成果版本", [
              p(entry.draft_id),
              p(entry.revision),
              p("审核版本 " + entry.review_version.to_string()),
            ]),
          ])
        }),
      )
    },
    match state.outcome {
      None => @html.nothing
      Some(outcome) =>
        render_collaboration_retained_result(dispatch, state, outcome)
    },
  ])
}

///|
fn render_collaboration_retained_result(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
  outcome : @collaboration.RetainedOutcome,
) -> @rabbita.Html {
  let work = outcome.work
  article(class="request-desk-stack", [
    h3(outcome.saved.draft.title),
    p(
      collaboration_status_label(work.status) +
      " · " +
      collaboration_status_label(outcome.review_status),
    ),
    p("研究问题：" + outcome.saved.draft.question),
    if outcome.saved.draft.objection.is_empty() {
      @html.nothing
    } else {
      p("保留异议：" + outcome.saved.draft.objection)
    },
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
          @html.pre(
            class="collaboration-retained-output",
            participant.output_text,
          ),
        ])
      }),
    ),
    h3("审核记录"),
    div(
      work.decisions.map(decision => {
        p(
          decision.reviewer_name +
          " · " +
          collaboration_status_label(decision.decision) +
          " · " +
          decision.rationale,
        )
      }),
    ),
    p(
      "这是所选历史版本。处理审核前需要读取任务的当前状态。",
    ),
    div(class="request-actions", [
      button(
        class="control-button",
        attrs=@html.Attrs::build().disabled(
          state.busy() || collaboration_has_unsaved_draft(state),
        ),
        on_click=dispatch(
          CollaborationReviewOpen(outcome.key.draft_id, outcome.key.revision),
        ),
        "打开任务处理",
      ),
      button(
        class="control-button",
        attrs=@html.Attrs::build().disabled(state.busy()),
        on_click=dispatch(CollaborationOutcomeDownload),
        town_ui_label("download", "下载成果包"),
      ),
    ]),
    if collaboration_has_unsaved_draft(state) {
      p(
        "先保存当前研究草稿，再打开另一项任务；查看和下载历史成果不会覆盖草稿。",
      )
    } else {
      @html.nothing
    },
    render_retained_inquiry(dispatch, state, outcome),
    render_advanced_details("来源、历史版本与完整证据", [
      p(outcome.key.draft_id + " · " + outcome.key.revision),
      p(outcome.key.result_digest),
      p("所选审核记录：" + outcome.key.review_digest),
      p("下载不提交知识册，也不改变任何审核决定。"),
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
            "查看审核版本 " + review.version.to_string(),
          )
        }),
      ),
      div(
        work.participants.map(participant => {
          p(
            participant.book_id +
            " · " +
            participant.run_id +
            " · " +
            participant.output_digest,
          )
        }),
      ),
      h3("完整结果记录"),
      @html.pre(class="collaboration-retained-output", work.result_text),
      h3("完整审核历史"),
      @html.pre(class="collaboration-retained-output", work.review_history_text),
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
      p(
        "成果包：" +
        outcome.archive_digest +
        " · " +
        outcome.archive_size_bytes.to_string() +
        " bytes",
      ),
    ]),
  ])
}
