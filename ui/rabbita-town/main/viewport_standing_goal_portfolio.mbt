priv struct StandingGoalCardView {
  remaining_ticks : Int
  progress : Int
  target_book_id : String
  decision : String
  detail : String
  latest_tick : String
  checked_sources : String
  accepted_facts : String
  new_sources_found : String
  rejected_facts : String
  changed_pages : String
  book_changed : String
  record_count : Int
  update_count : Int
  review_count : Int
  no_change_count : Int
  failed_count : Int
}

///|
fn standing_goal_card_view(
  model : Model,
  goal : StandingGoalSnapshot,
) -> StandingGoalCardView {
  let latest = latest_watcher_record_for_goal(model, goal.id)
  let latest_view = latest_watcher_record_card_view(latest)
  let decision_summary = watcher_decision_summary_for_goal(model, Some(goal.id))
  {
    remaining_ticks: ticks_until_next_goal_check(model, goal),
    progress: standing_goal_progress(model, goal),
    target_book_id: goal.target_book_id.unwrap_or("mayor-selected-book"),
    decision: latest_view.decision,
    detail: latest_view.detail,
    latest_tick: latest_view.latest_tick,
    checked_sources: latest_view.checked_sources,
    accepted_facts: latest_view.accepted_facts,
    new_sources_found: latest_view.new_sources_found,
    rejected_facts: latest_view.rejected_facts,
    changed_pages: latest_view.changed_pages,
    book_changed: latest_view.book_changed,
    record_count: watcher_record_count_for_goal(model, goal.id),
    update_count: decision_summary.update_count,
    review_count: decision_summary.review_count,
    no_change_count: decision_summary.no_change_count,
    failed_count: decision_summary.failed_count,
  }
}

///|
priv struct LatestWatcherRecordCardView {
  decision : String
  detail : String
  latest_tick : String
  checked_sources : String
  accepted_facts : String
  new_sources_found : String
  rejected_facts : String
  changed_pages : String
  book_changed : String
}

///|
fn latest_watcher_record_card_view(
  latest : WatcherRunRecordSnapshot?,
) -> LatestWatcherRecordCardView {
  match latest {
    Some(record) => {
      let metrics = watcher_record_metric_labels(record)
      LatestWatcherRecordCardView::{
        decision: record.decision,
        detail: one_line(record.detail),
        latest_tick: "latest tick \{record.tick}",
        checked_sources: metrics.checked,
        accepted_facts: metrics.accepted,
        new_sources_found: metrics.found,
        rejected_facts: metrics.rejected,
        changed_pages: metrics.wiki,
        book_changed: metrics.book_changed,
      }
    }
    None => LatestWatcherRecordCardView::{
      decision: "Waiting",
      detail: "No ledger row has been recorded for this standing watch yet.",
      latest_tick: "no completed tick",
      checked_sources: "n/a",
      accepted_facts: "n/a",
      new_sources_found: "n/a",
      rejected_facts: "n/a",
      changed_pages: "n/a",
      book_changed: "unknown",
    }
  }
}

///|
fn render_standing_goal_card(
  model : Model,
  goal : StandingGoalSnapshot,
) -> @rabbita.Html {
  let view = standing_goal_card_view(model, goal)
  article(class=watcher_decision_class("watch-goal-card", view.decision), [
    div(class="standing-progress-head", [
      div([p(class="eyebrow", "Standing Watch"), h3(goal.title)]),
      status_chip(view.decision, watcher_decision_chip_class(view.decision)),
    ]),
    p(class="standing-progress-copy", view.detail),
    p(class="watch-goal-prompt", one_line(goal.prompt)),
    div(class="standing-progress-track", [
      div(
        class="standing-progress-fill",
        style=["width: \{view.progress}%"],
        no_children(),
      ),
    ]),
    div(class="standing-progress-meta", [
      span("goal `\{goal.id}`"),
      span("book `\{view.target_book_id}`"),
      span(
        if view.remaining_ticks == 0 {
          "due now"
        } else {
          "next in \{view.remaining_ticks} ticks"
        },
      ),
      span(view.latest_tick),
      span("cadence \{goal.cadence_ticks} ticks"),
      span("quality \{goal.quality_threshold}%"),
      span(goal.source_policy),
      span("checked \{view.checked_sources}"),
      span("found \{view.new_sources_found}"),
      span("accepted \{view.accepted_facts}"),
      span("rejected \{view.rejected_facts}"),
      span("wiki \{view.changed_pages}"),
      span("book changed \{view.book_changed}"),
      span("records \{view.record_count}"),
      span(
        "U\{view.update_count} / R\{view.review_count} / N\{view.no_change_count} / F\{view.failed_count}",
      ),
    ]),
  ])
}

///|
fn render_standing_goal_portfolio(model : Model) -> @rabbita.Html {
  let cards : Array[@rabbita.Html] = []
  for goal in model.standing_goals {
    if goal.enabled {
      cards.push(render_standing_goal_card(model, goal))
    }
  }
  if cards.is_empty() {
    cards.push(
      article(class="watch-goal-card", [
        div(class="standing-progress-head", [
          div([
            p(class="eyebrow", "Standing Watch Portfolio"),
            h3("No active standing goals"),
          ]),
          status_chip("Waiting", "chip-neutral"),
        ]),
        p(
          class="standing-progress-copy",
          "Add a standing goal in `.moontown/standing-goals.json` or submit one from the operator panel to start durable topic monitoring.",
        ),
      ]),
    )
  }
  section(class="watch-portfolio", [
    div(class="watch-portfolio-head", [
      div([p(class="eyebrow", "Watch Portfolio"), h3("Long-horizon topics")]),
      status_chip("\{cards.length()} configured", "chip-neutral"),
    ]),
    div(class="watch-portfolio-grid", cards),
  ])
}
