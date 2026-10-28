///|
fn render_collective_experiment(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
  work : @collaboration.OneoffWork,
) -> @rabbita.Html {
  let disabled = state.busy() || state.dirty || state.revision.is_empty()
  if !@collaboration.salon_ready(work) {
    return @html.nothing
  }
  if state.work_fields.get("work_collective_mode") != Some("compose") {
    return button(
      attrs=@html.Attrs::build().disabled(disabled),
      on_click=dispatch(CollaborationEdit("work_collective_mode", "compose")),
      "继续研究 · 验证新假设",
    )
  }
  let saved : @collaboration.SavedDraft = {
    contract_version: "moontown.collaboration-draft.v1",
    draft: state.draft,
    revision: state.revision,
    previous_revision: state.previous_revision,
    recorded_at: "",
    sources: state.sources,
  }
  let validation = @collaboration.collective_followup(
    saved,
    work,
    collaboration_work_payload(state),
  )
  div(class="request-desk-stack", [
    h3("继续研究 · 验证新假设"),
    p(
      "连接已有证据，提出可验证的新假设，并请各知识册独立质疑。这里只创建研究草稿，不执行实验。",
    ),
    render_advanced_details(
      "新研究的保存标识",
      needs_attention=state.work_fields
        .get("work_collective_new_id")
        .unwrap_or("")
        .is_empty(),
      [work_field(dispatch, state, "collective_new_id", "新草稿标识")],
    ),
    work_field(
      dispatch, state, "collective_title", "Experiment title (up to 200 characters)",
    ),
    work_field(
      dispatch,
      state,
      "collective_hypothesis",
      "Combined hypothesis: what becomes possible by connecting these contributions?",
      multiline=true,
    ),
    div(
      @collaboration.salon_candidates(work).map(candidate => {
        div(class="request-desk-stack", [
          h3("Connect " + candidate.book_id),
          render_advanced_details("执行来源", [
            p(
              "Retained run " +
              candidate.run_id +
              " · " +
              candidate.output_digest,
            ),
          ]),
          @html.pre(
            class="collaboration-retained-output",
            candidate.output_text,
          ),
          work_field(
            dispatch,
            state,
            "collective_quote_" + candidate.book_id,
            "Exact supporting passage (up to 1000 characters)",
            multiline=true,
          ),
          work_field(
            dispatch,
            state,
            "collective_connection_" + candidate.book_id,
            "How does this evidence change the combined hypothesis?",
            multiline=true,
          ),
          work_field(
            dispatch,
            state,
            "collective_challenge_" + candidate.book_id,
            "What should this Book challenge or try to disprove?",
            multiline=true,
          ),
        ])
      }),
    ),
    work_field(
      dispatch,
      state,
      "collective_experiment",
      "Smallest experiment: method, observation and constraints",
      multiline=true,
    ),
    work_field(
      dispatch,
      state,
      "collective_falsifier",
      "What observable result would disprove the hypothesis?",
      multiline=true,
    ),
    p("Original independently owned objection: " + state.draft.objection),
    work_field(
      dispatch,
      state,
      "collective_dissent",
      "Contradictions and dissent the next round must preserve",
      multiline=true,
    ),
    work_field(
      dispatch,
      state,
      "collective_assumptions",
      "Unresolved assumptions and missing evidence",
      multiline=true,
    ),
    p(
      "保留失败项与原始引文，重新采集当前来源。新研究不继承审核；保存不会运行 Agent 或实验。",
    ),
    p(
      match validation {
        Ok(_) =>
          "可以保存并进入研究编辑。准备与执行仍需分别确认。"
        Err(error) => error
      },
    ),
    button(
      attrs=@html.Attrs::build().disabled(disabled || validation is Err(_)),
      on_click=dispatch(CollaborationAction("oneoff-followup")),
      "保存并编辑研究",
    ),
    button(
      attrs=@html.Attrs::build().disabled(disabled),
      on_click=dispatch(CollaborationEdit("work_collective_mode", "off")),
      "取消继续研究",
    ),
  ])
}
