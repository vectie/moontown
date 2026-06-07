# Tool Watch Skill

Use this skill when maintaining an App ToolBook standing watch.

Process:

1. Read `book.json`, `tool-manifest.json`, `wiki/methods/analysis-method.md`, and `wiki/tools/tool-spec.md`.
2. Check configured websites or data sources before local fallback.
3. Update `raw/data/latest.json` only with accepted data.
4. Update `wiki/reports/latest-analysis.md` only when analysis materially changes.
5. Decide whether the tool needs a UI/code update.
6. Return strict standing-watch markers including source counts, accepted facts, `book_changed`, `tool_changed`, and `tool_build_status`.

Do not inflate evidence counts with operational retries, wrapper files, or generated-site rebuilds.

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
