///|
fn knowledge_book_state_class(state : KnowledgeBookDisplayState) -> String {
  "knowledge-book-state knowledge-book-state-\{state.key}"
}

///|
fn render_knowledge_domain_stat(
  label : String,
  value : String,
) -> @rabbita.Html {
  div(class="knowledge-library-stat", [
    span(class="knowledge-library-stat-value", value),
    span(class="knowledge-library-stat-label", label),
  ])
}

///|
fn render_knowledge_book_tags(book : KnowledgeDomainBook) -> @rabbita.Html {
  let tags : Array[@rabbita.Html] = []
  let shown = if book.tags.length() < 3 { book.tags.length() } else { 3 }
  for index in 0..<shown {
    tags.push(span(class="knowledge-book-tag", book.tags[index]))
  }
  if book.tags.length() > shown {
    tags.push(
      span(
        class="knowledge-book-tag knowledge-book-tag-more",
        "+\{book.tags.length() - shown}",
      ),
    )
  }
  div(class="knowledge-book-tags", tags)
}

///|
fn render_knowledge_book_projection_signal(
  projection : BookProjectionFragment,
) -> @rabbita.Html {
  let signals : Array[@rabbita.Html] = []
  let shown = if projection.status_chips.length() < 2 {
    projection.status_chips.length()
  } else {
    2
  }
  for index in 0..<shown {
    let chip = projection.status_chips[index]
    signals.push(
      span(
        class="knowledge-book-signal \{projection_tone_class(chip.tone)}",
        chip.label,
      ),
    )
  }
  if !projection.review_queue.is_empty() {
    signals.push(
      span(
        class="knowledge-book-signal knowledge-book-signal-review",
        "\{projection.review_queue.length()} review",
      ),
    )
  }
  div(class="knowledge-book-signals", signals)
}

///|
fn knowledge_projection_first_safe_link(
  projection : BookProjectionFragment,
) -> ProjectionLinkSnapshot? {
  for link in projection.links {
    if energy_valley_runtime_result_url_is_safe(link.url) {
      return Some(link)
    }
  }
  None
}

///|
fn render_knowledge_book_card(
  model : Model,
  book : KnowledgeDomainBook,
  is_primary : Bool,
) -> @rabbita.Html {
  let state = knowledge_book_display_state(model, book)
  let projection = find_exact_book_projection(model, book.book_id)
  let card_children : Array[@rabbita.Html] = [
    div(class="knowledge-book-card-head", [
      div(class="knowledge-book-card-title-wrap", [
        div(class="knowledge-book-card-title-line", [
          h3(class="knowledge-book-card-title", book.title),
          if is_primary {
            span(class="knowledge-book-primary", "Primary synthesis")
          } else {
            @html.nothing
          },
        ]),
        span(class="knowledge-book-id", book.book_id),
      ]),
      span(
        class=knowledge_book_state_class(state),
        title=state.explanation,
        state.label,
      ),
    ]),
    p(class="knowledge-book-question", book.question),
  ]
  match projection {
    Some(value) => {
      card_children.push(
        p(class="knowledge-book-projection-summary", value.summary),
      )
      card_children.push(render_knowledge_book_projection_signal(value))
      match knowledge_projection_first_safe_link(value) {
        Some(link) =>
          card_children.push(
            a(
              href=link.url,
              class="knowledge-book-open",
              title=link.label,
              attrs=@html.Attrs::build().aria_label(
                "Open MoonBook \{book.title}: \{link.label}",
              ),
              "↗ Open",
            ),
          )
        None => ()
      }
    }
    None =>
      card_children.push(
        p(
          class="knowledge-book-declaration",
          "Catalog declaration · \{book.status} · not a completed-work claim",
        ),
      )
  }
  card_children.push(render_knowledge_book_tags(book))
  card_children.push(
    div(class="knowledge-book-meta", [
      span("Tier · \{book.schedule_tier}"),
      span("Cadence · \{book.cadence_ticks} ticks"),
      span("Role · \{book.role}"),
    ]),
  )
  card_children.push(
    p(
      class="knowledge-book-source-policy",
      "Source policy · \{book.source_policy}",
    ),
  )
  let primary_class = if is_primary {
    " knowledge-book-card-primary"
  } else {
    ""
  }
  article(
    class="knowledge-book-card knowledge-book-card-\{state.key}" + primary_class,
    card_children,
  )
}

///|
fn render_knowledge_domain_policy(
  model : Model,
  domain : KnowledgeDomain,
) -> @rabbita.Html {
  match find_knowledge_domain_policy(model, domain.policy_id) {
    None =>
      div(class="knowledge-policy knowledge-policy-missing", [
        span(class="knowledge-policy-title", "Policy not connected"),
        span(class="knowledge-policy-id", domain.policy_id),
      ])
    Some(policy) => {
      let reviewers : Array[@rabbita.Html] = []
      for index, reviewer in policy.review_chain {
        if index > 0 {
          reviewers.push(span(class="knowledge-review-arrow", "→"))
        }
        reviewers.push(span(class="knowledge-reviewer", reviewer))
      }
      section(class="knowledge-policy", [
        div(class="knowledge-policy-summary", [
          div([
            span(class="knowledge-policy-title", "Policy & review"),
            span(
              class="knowledge-policy-id",
              "\{policy.id} · v\{policy.version}",
            ),
          ]),
          span(
            class="knowledge-policy-quality",
            "≥ \{policy.quality_threshold}",
          ),
        ]),
        div(class="knowledge-policy-body", [
          div(class="knowledge-review-chain", reviewers),
          div(class="knowledge-policy-grid", [
            span("Cadence · \{policy.cadence}"),
            span("Budget · \{policy.budget_class}"),
            span("Revisions · ≤ \{policy.max_revision_rounds}"),
            span("Template · \{policy.template_id}"),
          ]),
          p("Evidence · \{policy.evidence_policy}"),
          p("Completion claim · \{policy.completion_claim}"),
        ]),
      ])
    }
  }
}

///|
fn render_knowledge_domain_library(
  model : Model,
  domain : KnowledgeDomain,
) -> @rabbita.Html {
  let total = domain.books.length()
  let real = knowledge_domain_real_book_count(model, domain)
  let review = knowledge_domain_review_book_count(model, domain)
  let accepted = knowledge_domain_accepted_book_count(model, domain)
  let cards : Array[@rabbita.Html] = []
  for book in domain.books {
    cards.push(
      render_knowledge_book_card(
        model,
        book,
        book.book_id == domain.primary_book_id,
      ),
    )
  }
  section(class="knowledge-library", [
    div(class="knowledge-library-heading", [
      div(class="knowledge-library-identity", [
        span(class="knowledge-library-icon", domain.icon),
        div([
          span(class="knowledge-library-eyebrow", "Domain MoonBook library"),
          h2(class="knowledge-library-title", domain.title),
        ]),
      ]),
      span(class="knowledge-library-kind", domain.kind),
    ]),
    p(class="knowledge-library-summary", domain.summary),
    div(class="knowledge-library-stats", [
      render_knowledge_domain_stat("Books", total.to_string()),
      render_knowledge_domain_stat("Real joins", real.to_string()),
      render_knowledge_domain_stat("Review", review.to_string()),
      render_knowledge_domain_stat("Accepted", accepted.to_string()),
    ]),
    div(class="knowledge-library-tier-row", [
      span("Primary tier"),
      span(
        class="knowledge-library-tier",
        knowledge_domain_primary_tier(domain),
      ),
      span(class="knowledge-library-policy-ref", domain.policy_id),
    ]),
    render_knowledge_domain_policy(model, domain),
    div(class="knowledge-library-list-head", [
      div([
        span(class="knowledge-library-list-title", "Books in this building"),
        span(
          class="knowledge-library-list-note",
          "Declared ≠ produced. Real states require a matching MoonBook projection.",
        ),
      ]),
      span(class="knowledge-library-total", total.to_string()),
    ]),
    if cards.is_empty() {
      div(
        class="knowledge-library-empty",
        "This domain is registered, but no books have been declared yet.",
      )
    } else {
      div(class="knowledge-library-books", cards)
    },
  ])
}

///|
fn render_knowledge_domain_runtime_strip(
  model : Model,
  building : GoldenValleyBuilding,
) -> @rabbita.Html {
  let tasks = golden_valley_runtime_tasks_for_building(
    model.energy_valley_runtime,
    building,
  )
  let agents = golden_valley_runtime_known_agents_for_building(
    model.energy_valley_runtime,
    building,
  )
  let task_cards : Array[@rabbita.Html] = []
  let shown = if tasks.length() < 3 { tasks.length() } else { 3 }
  for index in 0..<shown {
    let task = tasks[index]
    task_cards.push(
      div(class="knowledge-runtime-task", [
        span(class="knowledge-runtime-task-title", task.title),
        span(
          class="knowledge-runtime-task-meta",
          "\{task.status} · \{task.runId.unwrap_or("no run")}",
        ),
      ]),
    )
  }
  section(class="knowledge-runtime-strip", [
    div(class="knowledge-runtime-head", [
      div([
        span(class="knowledge-runtime-title", "Real runtime"),
        span(
          class="knowledge-runtime-truth",
          if model.energy_valley_runtime.phase is Live {
            "Live evidence"
          } else {
            "No live claim"
          },
        ),
      ]),
      div(class="knowledge-runtime-counts", [
        span("\{agents.length()} agents"),
        span("\{tasks.length()} tasks"),
      ]),
    ]),
    if tasks.is_empty() {
      p(
        class="knowledge-runtime-empty",
        if model.energy_valley_runtime.phase is Live {
          "Connected, with no current runtime task assigned here."
        } else {
          "Preview movement is illustrative and is never counted as work."
        },
      )
    } else {
      div(class="knowledge-runtime-tasks", task_cards)
    },
  ])
}

///|
fn render_knowledge_domain_inspector_shell(
  dispatch : Dispatch[Msg],
  model : Model,
  building : GoldenValleyBuilding,
  domain : KnowledgeDomain,
) -> @rabbita.Html {
  div(
    class="knowledge-library-inspector pointer-events-auto rounded-2xl bg-slate-950/85 p-4 backdrop-blur-md border border-white/10 shadow-2xl",
    [
      div(class="knowledge-inspector-toolbar", [
        div(class="knowledge-inspector-building", [
          span(golden_valley_building_kind_label(building)),
          span("·"),
          span(building.name),
        ]),
        button(
          class="knowledge-inspector-close min-h-11 min-w-11 rounded-lg text-slate-400 hover:bg-white/10",
          on_click=dispatch(CloseEnergyInspector),
          attrs=@html.Attrs::build().aria_label("关闭建筑详情"),
          "✕",
        ),
      ]),
      render_knowledge_domain_library(model, domain),
      render_knowledge_domain_runtime_strip(model, building),
    ],
  )
}
