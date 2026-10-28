///|
fn collaboration_status_label(value : String) -> String {
  match value {
    "not_started" => "尚未开始"
    "pending" => "待处理"
    "running" => "进行中"
    "completed" => "已完成"
    "partial" => "部分完成 · 有失败项"
    "failed" => "未完成"
    "pending_review" => "待审核"
    "accepted" | "approve" => "记录已审核"
    "rejected" | "reject" => "已拒绝"
    "deferred" | "defer" => "已暂缓"
    "not_retained" => "尚无成果"
    "not_ready" => "尚未进入审核"
    "unavailable" => "暂不可读取"
    "deliverable_review_required" => "等待知识册审阅成果"
    "assessment_review_required" => "等待知识册审阅评估"
    "proposal_review_required" => "等待知识册审阅提案"
    "closed_no_capability_change" => "知识册流程已完成"
    "reviewed_proposal_handed_off" => "已移交审核后的提案"
    "deliverable_rejected" | "assessment_rejected" | "proposal_rejected" =>
      "知识册已拒绝"
    "" => "未读取"
    _ => value
  }
}

///|
fn collaboration_has_unsaved_draft(state : @collaboration.Client) -> Bool {
  state.dirty &&
  (
    state.revision != "" ||
    state.draft != @collaboration.empty_draft(state.draft.draft_id)
  )
}

///|
fn collaboration_my_pending_reviews(work : @collaboration.OneoffWork) -> Int32 {
  if work.operator_id.is_empty() {
    return 0
  }
  work.decisions
  .filter(decision => {
    decision.reviewer_id == work.operator_id &&
    ["pending", "defer"].contains(decision.decision)
  })
  .length()
}

///|
fn render_collaboration_notice(state : @collaboration.Client) -> @rabbita.Html {
  let notice = state.notice
  if notice.is_empty() || notice == @collaboration.Client::new().notice {
    return @html.nothing
  }
  let label = if state.busy() {
    "正在处理…"
  } else if notice == "Saved drafts and existing Books loaded" {
    "知识册与草稿已载入。"
  } else if notice.has_prefix("Retained revisions loaded") {
    "成果列表已更新。"
  } else if notice.has_prefix("Unsaved ") {
    "有未保存的修改。"
  } else if notice.has_prefix("Exact retained result") {
    "成果已读取。"
  } else if notice.has_prefix("Saved source snapshots reopened") {
    "草稿已打开。"
  } else if notice.has_prefix("Prepared locally.") {
    "任务已准备好，尚未执行。"
  } else if notice.has_prefix("New research-salon inquiry saved") ||
    notice.has_prefix("Peer-challenge draft saved") {
    "研究草稿已保存。"
  } else if notice.contains("Directory is missing") {
    "当前工作区尚未连接知识册，请配置资料后重试。"
  } else if notice.contains("not configured") {
    "执行服务尚未配置，请联系管理员；草稿仍可保存。"
  } else if notice.contains("interrupted") ||
    notice.contains("Network") ||
    notice.contains("endpoint") ||
    notice.contains("HTTP") {
    "暂时无法完成请求。请确认已登录工作区，再重试原操作。"
  } else {
    notice
  }
  div([
    p(attrs=@html.Attrs::build().role("status").aria_live("polite"), label),
    if label != notice &&
      !state.busy() &&
      (
        notice.contains("HTTP") ||
        notice.contains("endpoint") ||
        notice.contains("not configured") ||
        notice.contains("interrupted") ||
        notice.contains("Network") ||
        notice.contains("Directory is missing")
      ) {
      render_advanced_details("服务返回详情", [p(notice)])
    } else {
      @html.nothing
    },
  ])
}

///|
/// Historical review states do not identify the signed-in reviewer. Only the
/// current work reply can supply that identity; never label the whole queue mine.
fn render_collaboration_attention(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
) -> @rabbita.Html {
  let pending = state.outcomes.filter(entry => {
    ["pending_review", "deferred", "rejected"].contains(entry.review_status) &&
    ["completed", "partial"].contains(entry.outcome_status)
  })
  section(id="collaboration-attention", class="request-desk-stack", [
    h3("工作区待处理"),
    div(class="request-actions", [
      button(
        class="control-button",
        title="刷新待处理",
        attrs=@html.Attrs::build()
          .disabled(state.busy())
          .aria_label("刷新待处理"),
        on_click=dispatch(CollaborationAction("outcome-list")),
        town_ui_icon("refresh"),
      ),
      button(
        class="control-button",
        on_click=dispatch(OpenWorkWorkspace(ResultsComposer)),
        town_ui_label("book", "全部成果"),
      ),
    ]),
    render_collaboration_notice(state),
    if state.revision.is_empty() {
      @html.nothing
    } else {
      div(class="request-desk-stack", [
        h3("当前任务 · " + state.draft.title),
        if state.work is Some(work) {
          if collaboration_my_pending_reviews(work) > 0 {
            p(
              "待我审核 · \{collaboration_my_pending_reviews(work)} 项决定",
            )
          } else if work.operator_id.is_empty() &&
            !work.result_digest.is_empty() {
            p("请以指定审阅人登录后处理；当前仅可查看。")
          } else {
            p(collaboration_status_label(work.status))
          }
        } else {
          p("尚未读取进度")
        },
        render_collaboration_work(dispatch, state),
      ])
    },
    if pending.is_empty() {
      p("暂无待处理记录")
    } else {
      div(
        class="request-desk-stack",
        pending.map(entry => {
          article([
            h3(entry.title),
            p(collaboration_status_label(entry.review_status)),
            p(entry.recorded_at),
            button(
              class="control-button",
              attrs=@html.Attrs::build().disabled(
                state.busy() || collaboration_has_unsaved_draft(state),
              ),
              on_click=dispatch(
                CollaborationReviewOpen(entry.draft_id, entry.revision),
              ),
              "处理",
            ),
          ])
        }),
      )
    },
    if collaboration_has_unsaved_draft(state) {
      p(
        "当前有未保存的研究草稿，请先保存，再打开另一项任务。",
      )
    } else {
      @html.nothing
    },
  ])
}
