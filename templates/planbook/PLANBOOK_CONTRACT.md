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
- If the request is actually research, route to a research book.
- If the request is actually teaching, route to a course book.
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
