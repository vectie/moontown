# Mayor Goal Decomposition

Use this skill when the Mayor claw must decide whether a town goal should stay in one MoonBook or decompose into multiple isolated MoonBooks.

## Responsibility

- decide `single-book` vs `multi-book`
- decide whether lanes can run in parallel
- create one lane per durable knowledge subject
- avoid artificial fragmentation
- keep each lane objective self-contained

## Hard Rules

- Do not decompose only because the goal is large.
- Decompose when the goal names distinct durable subjects that benefit from isolated wiki growth.
- Each lane must be able to build its own `raw/`, `wiki/sources/`, `wiki/entities/`, `wiki/concepts/`, and synthesis pages.
- If later synthesis is needed, keep that as a later town-level step, not as an excuse to avoid decomposition.
- If the user explicitly binds a book, do not decompose outside that book.
- If the request is about implementation, create or update a PlanBook lane
  rather than pretending it is research.
- If the request is about teaching, create or update a Course Book lane.
- If the request asks for a usable webpage tool, dashboard, calculator,
  comparator, explorer, map, simulation, or app backed by watched data or book
  knowledge, create an `app-tool-book` template request instead of treating it
  as only research or only UI.
- If the request is about stable operating definitions, route impact to the
  Cookbook after the plan is accepted.
- If the request is a civic/social exchange, route it to a building protocol
  pattern and name the participant books that should receive returned outputs.
- Keep durable truth in books/documents and keep workers temporary.

## Output Contract

Return `mayor.goal.decomposition.v1`:

```json
{
  "parallelizable": true,
  "summary": "Mayor split the goal into isolated research lanes.",
  "lanes": [
    {
      "book_id": "research-moontown",
      "objective": "Own only the Moontown research lane.",
      "rationale": "parallel research lane for moontown"
    }
  ]
}
```

## Examples

### Example: parallel research

Goal:

```text
research moontown, moonbook, and moonclaw
```

Output:

```json
{
  "parallelizable": true,
  "summary": "Mayor split the goal into 3 isolated research lanes because the request names multiple knowledge subjects.",
  "lanes": [
    {
      "book_id": "research-moontown",
      "objective": "Own only the moontown research lane. Build durable source, entity, concept, and synthesis coverage for this lane. Cross-reference other lanes only through durable outputs. Global town goal: research moontown, moonbook, and moonclaw",
      "rationale": "parallel research lane for moontown"
    },
    {
      "book_id": "research-moonbook",
      "objective": "Own only the moonbook research lane. Build durable source, entity, concept, and synthesis coverage for this lane. Cross-reference other lanes only through durable outputs. Global town goal: research moontown, moonbook, and moonclaw",
      "rationale": "parallel research lane for moonbook"
    },
    {
      "book_id": "research-moonclaw",
      "objective": "Own only the moonclaw research lane. Build durable source, entity, concept, and synthesis coverage for this lane. Cross-reference other lanes only through durable outputs. Global town goal: research moontown, moonbook, and moonclaw",
      "rationale": "parallel research lane for moonclaw"
    }
  ]
}
```

### Example: single lane

Goal:

```text
improve coding task review flow
```

Output:

```json
{
  "parallelizable": false,
  "summary": "Mayor kept the goal inside one book because the request reads as one domain lane.",
  "lanes": [
    {
      "book_id": "coding",
      "objective": "improve coding task review flow",
      "rationale": "single-lane book objective"
    }
  ]
}
```

### Example: civic exchange

Goal:

```text
let robotics, agents, hardware, and LLM books exchange ideas every 30 minutes
```

Output:

```json
{
  "parallelizable": true,
  "summary": "Mayor routes the request to a building protocol pattern rather than a single worker job.",
  "lanes": [
    {
      "book_id": "wenyu-social-square",
      "objective": "Run a recurring communication-pattern round where robotics, agents, hardware, and LLM books exchange packets, reduce tensions into reviewable ideas, and return outputs home.",
      "rationale": "civic building protocol for cross-book exchange"
    }
  ]
}
```

### Example: generated tool book

Goal:

```text
watch public market data, analyze the trend, and give me a dashboard tool in the town
```

Output:

```json
{
  "parallelizable": false,
  "summary": "Mayor routes the request to an App ToolBook because the durable output includes both analysis and a usable web tool.",
  "lanes": [
    {
      "book_id": "toolbook-market-data-dashboard",
      "objective": "Create an app-tool-book request that watches configured data sources, maintains accepted analysis, generates or repairs the dashboard tool, and binds it to the appropriate civic building.",
      "rationale": "ToolBook lane for durable watched data plus generated app"
    }
  ]
}
```
