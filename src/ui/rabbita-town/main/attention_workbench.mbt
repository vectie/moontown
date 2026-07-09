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
    div(class="attention-review-strip", [
      div(class="attention-review-copy", [
        p(class="eyebrow", "Attention Workbench"),
        h2(focus.title),
        p(class="summary", focus.detail),
      ]),
      div(class="attention-strip-chips", [
        render_attention_focus_chip("Signal", focus.signal, "primary"),
        render_attention_focus_chip(focus.next_label, focus.next_detail, "next"),
        render_attention_recent_chip(attention_recent_feed_item(feed)),
      ]),
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
  article(class="attention-strip-chip attention-strip-\{tone}", [
    p(class="metric-label", label),
    p(class="attention-strip-value", value),
  ])
}

///|
fn render_attention_recent_chip(item : FeedItem) -> @rabbita.Html {
  article(class=attention_recent_chip_class(item), [
    p(class="metric-label", "Recent signal"),
    h3(item.title),
    p(class="attention-strip-detail", item.detail),
  ])
}

///|
fn attention_recent_chip_class(item : FeedItem) -> String {
  "attention-strip-chip attention-strip-recent attention-strip-\{item.tone}"
}
