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
