# Tool Build Skill

Use this skill when generating or repairing the runnable web tool for an App ToolBook.

Requirements:

- Preserve `tool-manifest.json` as the route/build/review source of truth.
- Keep tool source under `app/`.
- Publish the usable page to `book/site/generated/tool.html`.
- Keep `book/site/generated/index.html` as the report/tool landing page.
- Prefer simple, inspectable HTML/CSS/JavaScript unless the book explicitly asks for a heavier stack.
- Validate that the tool loads and has useful empty, stale, and error states.
- Record tool changes in `wiki/reviews/tool-review.md`.

## Exploration Quality Contract

Every run should improve the book's ability to answer deeper and broader
questions about its topic.

- Go deeper: explain the mechanism, evidence chain, confidence boundary,
  contradiction, or internal dependency that makes the result true, weak, or
  blocked.
- Go broader: connect the result to adjacent entities, concepts, source pages,
  downstream decisions, and book-maintenance consequences.
- Generate new questions: record follow-up questions that would change the
  answer, expose missing evidence, or open a useful next investigation.
- Generate new directions: name the next durable page, review item, experiment,
  comparison, or synthesis update that should grow from this work.
- Prefer longer meaningful text over short status output when evidence exists:
  give enough context that a future keeper can resume without the chat history.

Return the same result contract expected by `skills/tool-watch/SKILL.md`.
