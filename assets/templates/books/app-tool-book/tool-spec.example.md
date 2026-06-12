# Tool Specification

Define the usable web tool this book should maintain.

Example contract:

- Tool type: dashboard, calculator, comparator, explorer, simulator, or map.
- Inputs: accepted data files under `raw/data/`.
- Outputs: interactive UI under `app/` and `book/site/generated/tool.html`.
- Required interactions: filters, sorting, comparisons, scenario inputs, or drill-down panels.
- Validation: the tool must load without network-only assumptions and must show stale/missing data clearly.
- Civic binding: the linked Moontown building should expose "Open Tool", "Open Report", and "Configure in Moondesk".
