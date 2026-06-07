# Planbook Contract

This contract defines how a MoonBook planbook should behave when Moontown asks
for code, product, UI, docs, daemon, or civic implementation planning.

## Inputs

- operator request
- screenshots, error text, or voice transcript if present
- current repository files
- related docs
- previous planbook plans
- relevant research or course books only when needed

## Required Output

Write a durable plan under:

```text
plans/<yyyy-mm-dd>-<slug>/plan.md
```

The plan must follow:

```text
templates/planbook/PLAN_TEMPLATE.md
```

## Rules

- Planning is not execution.
- Do not modify production code while creating the plan unless explicitly asked.
- Prefer concrete repository facts over generic advice.
- Use checkboxes for acceptance criteria.
- Name ownership boundaries between Moontown, MoonBook, MoonClaw, and Moondesk.
- Preserve the operating architecture: durable truth lives in MoonBook
  documents/ledgers, active behavior is a protocol, civic buildings are
  protocol places, Mayor owns routing/cadence, Bookkeepers own memory, and
  MoonClaw workers are bounded freelance executors.
- Say how the output returns home: which book, ledger, review queue, projection,
  or cookbook stable-state entry changes after execution.
- Say what should grow over time: book content, civic protocol ledgers,
  PlanBook evidence, code/tests, UI projections, or explicit no-change records.
- If execution changes Moontown source used by the live daemon, include a
  post-validation reload step:
  `moon run cmd/main -- daemon restart "validated source patch"`.
  Fresh packets after that reload are the live proof; pre-reload daemon output
  does not prove the new code path.
- If the request is actually research, route to a research book.
- If the request is actually teaching, route to a course book.
- If the request asks for a usable web tool backed by watched data, book
  knowledge, reports, dashboards, calculators, explorers, maps, simulations, or
  other interactive output, route it to an `app-tool-book` request. Do not
  hand-author a one-off Moontown page. The ToolBook owns `tool-manifest.json`,
  `wiki/reports/latest-analysis.md`, `wiki/tools/tool-spec.md`, `app/`, and
  `book/site/generated/tool.html`; Moontown only schedules it and links it from
  the civic building.
- If the request changes stable operating definitions, mark cookbook impact.

## Quality Gate

A plan is ready only when:

- problem and goal are clear
- affected files are named
- implementation steps are ordered
- validation commands are present
- risks and rollback are described
- the plan can survive context loss

## Result Contract

When used through MoonClaw provider execution, return JSON with:

- `task_id`
- `summary`
- `artifacts`
- `memory_candidates`
- `requires_review`
- `notify_town`

The `artifacts` list should include the generated `plan.md`.
