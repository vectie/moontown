# App ToolBook Contract

An App ToolBook is a MoonBook whose durable output includes both knowledge pages and a runnable web tool.

Ownership split:

- Moondesk edits the book config, analysis method, tool spec, and review decisions.
- Moontown installs the book, registers the standing goal, and exposes the civic building link.
- MoonBook owns durable sources, data, reports, tool source, generated site, and review state.
- MoonClaw watches sources, analyzes deltas, generates or repairs the tool, validates it, and returns strict result markers.

Required outputs:

- `tool-manifest.json`
- `raw/data/latest.json`
- `wiki/reports/latest-analysis.md`
- `wiki/reviews/tool-review.md`
- `app/index.html`
- `book/site/generated/tool.html`

Standing-watch result markers must include:

```text
standing_goal_decision: update | no_change | needs_review | failed
book_changed: yes | no
new_source_count: <integer>
checked_sources_count: <integer>
accepted_facts_count: <integer>
wiki_pages_changed_count: <integer>
tool_changed: yes | no
tool_build_status: passed | failed | skipped
next_check_hint: normal | slower | faster | review
```

Operational logs, retries, generated wrappers, and failed no-change checks are not domain evidence.
