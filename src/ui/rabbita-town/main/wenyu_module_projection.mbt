///|
fn projection_tone_class(tone : String) -> String {
  match tone {
    "alert" => "projection-tone-alert"
    "review" => "projection-tone-review"
    "healthy" => "projection-tone-healthy"
    "success" => "projection-tone-healthy"
    "warning" => "projection-tone-review"
    "info" => "projection-tone-info"
    _ => "projection-tone-info"
  }
}

///|
fn render_projection_chips(
  projection : BookProjectionFragment,
) -> @rabbita.Html {
  let chips = projection.status_chips.map(chip => {
    span(
      class="module-book-chip \{projection_tone_class(chip.tone)}",
      chip.label,
    )
  })
  if chips.is_empty() {
    chips.push(span(class="module-book-chip projection-tone-info", "No chips"))
  }
  div(class="module-book-chip-row", chips)
}

///|
fn render_projection_metrics(
  projection : BookProjectionFragment,
) -> @rabbita.Html {
  let cards = projection.metrics.map(render_projection_metric)
  if cards.is_empty() {
    cards.push(
      article(class="module-book-metric projection-tone-info", [
        span(class="module-book-metric-label", "MoonBook"),
        span(class="module-book-metric-value", "waiting"),
        p("No generated UI metrics were published for this book yet."),
      ]),
    )
  }
  div(class="module-book-metric-grid", cards)
}

///|
fn render_projection_metric(metric : ProjectionMetricSnapshot) -> @rabbita.Html {
  article(class="module-book-metric \{projection_tone_class(metric.tone)}", [
    span(class="module-book-metric-label", metric.label),
    span(class="module-book-metric-value", metric.value),
    p(metric.note),
  ])
}

///|
fn render_module_book_projection(
  model : Model,
  civic : WenyuTownModule,
) -> @rabbita.Html {
  match find_module_book_projection(model, civic) {
    Some(projection) =>
      section(class="module-book-projection", [
        div(class="module-book-heading", [
          div([p(class="eyebrow", "MoonBook Projection"), h2(projection.title)]),
          span(class="module-book-id", projection.book_id),
        ]),
        p(class="module-book-summary", projection.summary),
        render_module_civic_health(model, civic),
        render_projection_chips(projection),
        render_projection_metrics(projection),
        div(class="module-book-grid", [
          render_projection_item_group(
            "Readiness",
            "MoonBook has not published readiness items for this module.",
            "readiness",
            projection.readiness,
          ),
          render_projection_item_group(
            "Review Queue",
            "No pending review items were published for this module.",
            "review",
            projection.review_queue,
          ),
          render_projection_item_group(
            "Page Families",
            "No generated page-family summary was published for this module.",
            "pages",
            projection.page_families,
          ),
          render_projection_links(projection),
        ]),
        render_projection_journey(projection),
      ])
    None =>
      section(class="module-book-projection module-book-projection-missing", [
        div(class="module-book-heading", [
          div([
            p(class="eyebrow", "MoonBook Projection"),
            h2("Projection Not Connected"),
          ]),
          span(class="module-book-id", civic.book_id),
        ]),
        p(
          class="module-book-summary",
          "This building is configured, but its MoonBook projection is not connected yet.",
        ),
        p(
          class="module-book-empty",
          "This is now a real integration gap, not a decorative fallback: create the bound civic book or publish its MoonBook UI state to make this interior useful.",
        ),
        render_module_civic_health(model, civic),
      ])
  }
}
