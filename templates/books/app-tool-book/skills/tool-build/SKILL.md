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

Return the same result contract expected by `skills/tool-watch/SKILL.md`.
