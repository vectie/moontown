///|
fn render_attention_workbench(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
  events : Array[@core.TownEvent],
) -> @rabbita.Html {
  let focus = attention_focus_view(model, workers, executions)
  let feed = feed_items(model, workers, executions, events)
  section(class="attention-dock attention-dock-\{focus.tone}", [
    div(class="attention-dock-heading", [
      p(class="eyebrow", "Attention"),
      h2(focus.title),
    ]),
    div(class="attention-dock-items", [
      render_attention_focus_chip(focus.next_label, focus.next_detail, "next"),
      render_attention_recent_chip(attention_recent_feed_item(feed)),
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
fn render_attention_focus_chip(
  label : String,
  value : String,
  tone : String,
) -> @rabbita.Html {
  article(class="attention-dock-chip attention-dock-\{tone}", [
    p(class="metric-label", label),
    p(class="attention-dock-value", value),
  ])
}

///|
fn render_attention_recent_chip(item : FeedItem) -> @rabbita.Html {
  article(class=attention_recent_chip_class(item), [
    p(class="metric-label", "Latest signal"),
    h3(item.title),
    p(class="attention-dock-detail", item.detail),
  ])
}

///|
fn attention_recent_chip_class(item : FeedItem) -> String {
  "attention-dock-chip attention-dock-recent attention-dock-\{item.tone}"
}
