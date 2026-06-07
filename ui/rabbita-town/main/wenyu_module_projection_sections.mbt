fn render_projection_item(
  item : ProjectionItemSnapshot,
  kind : String,
) -> @rabbita.Html {
  article(class="module-book-item module-book-item-\{kind}", [
    h3(item.title),
    p(item.detail),
    span(item.meta),
  ])
}

///|
fn render_projection_item_group(
  title : String,
  empty : String,
  kind : String,
  items : Array[ProjectionItemSnapshot],
) -> @rabbita.Html {
  let children : Array[@rabbita.Html] = [h3(title)]
  if items.is_empty() {
    children.push(p(class="module-book-empty", empty))
  } else {
    for item in items {
      children.push(render_projection_item(item, kind))
    }
  }
  div(class="module-book-group", children)
}

///|
fn render_projection_journey(
  projection : BookProjectionFragment,
) -> @rabbita.Html {
  let rows : Array[@rabbita.Html] = [h3("Latest Journey")]
  if projection.journey.is_empty() {
    rows.push(
      p(
        class="module-book-empty",
        "No MoonBook journey entries were published yet.",
      ),
    )
  } else {
    for step in projection.journey {
      let highlights = if step.highlights.is_empty() {
        ""
      } else {
        " / \{step.highlights.join(" / ")}"
      }
      rows.push(
        article(class="module-book-journey-item", [
          span(
            class="module-book-journey-status",
            "\{step.stage} / \{step.status}",
          ),
          h3(step.title),
          p("\{step.summary}\{highlights}"),
        ]),
      )
    }
  }
  div(class="module-book-group module-book-journey", rows)
}

///|
fn render_projection_links(
  projection : BookProjectionFragment,
) -> @rabbita.Html {
  let links : Array[@rabbita.Html] = [h3("Outputs")]
  if projection.links.is_empty() {
    links.push(
      p(
        class="module-book-empty",
        "No generated HTML outputs were found for this book.",
      ),
    )
  } else {
    for link in projection.links {
      links.push(
        a(
          href=link.url,
          class="module-book-link module-book-link-\{link.kind}",
          "\{link.label}",
        ),
      )
    }
  }
  div(class="module-book-group module-book-links", links)
}
