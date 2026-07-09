///|
fn render_attention_workbench(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
  events : Array[@core.TownEvent],
) -> @rabbita.Html {
  let focus = attention_focus_view(model, workers, executions)
  let feed = feed_items(model, workers, executions, events)
  section(class="attention-workbench attention-workbench-\{focus.tone}", [
    div(class="attention-workbench-head", [
      div([
        p(class="eyebrow", "Attention Workbench"),
        h2(focus.title),
        p(class="summary", focus.detail),
      ]),
      div(class="attention-workbench-signal", [
        p(class="metric-label", "Signal"),
        p(class="attention-workbench-value", focus.signal),
      ]),
    ]),
    div(class="attention-workbench-grid", [
      article(class="attention-next-card", [
        p(class="metric-label", focus.next_label),
        p(class="attention-workbench-detail", focus.next_detail),
      ]),
      render_attention_signal_card(attention_recent_feed_item(feed)),
    ]),
  ])
}

///|
fn attention_recent_feed_item(feed : Array[FeedItem]) -> FeedItem {
  match feed.length() {
    0 => no_new_town_messages_feed_item()
    1 => feed[0]
    _ => feed[1]
  }
}

///|
fn render_attention_signal_card(item : FeedItem) -> @rabbita.Html {
  article(class=attention_signal_card_class(item), [
    p(class="metric-label", "Recent signal"),
    h3(item.title),
    p(class="attention-workbench-detail", item.detail),
  ])
}

///|
fn attention_signal_card_class(item : FeedItem) -> String {
  "attention-signal-card attention-signal-\{item.tone}"
}
