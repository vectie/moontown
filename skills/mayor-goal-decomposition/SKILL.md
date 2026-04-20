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
