# Select source passages without copying quote text

MoonTown supports bottom-up inquiry from material owned by participating Books.
The material notebook already imports/searches exact text and saves an ordinary
Collaboration draft. `select` now captures inclusive line ranges directly from
that imported text, while `remove` lets you revise the selection.

Use the existing `material_notebook import`, `find` and `read` workflow from
[Material notebook](MATERIAL_NOTEBOOK.md). Search results include one-based line
numbers. To select a passage from lines 2 through 4:

```
material_notebook select notebook.json water raw/observations.md 2 4 "What I observed" "What could challenge it" > selected.json
material_notebook remove selected.json 1 > revised.json
```

Always redirect to a NEW output file. Shell redirection to the input path would
truncate it before the command reads it. A failed command produces no JSON;
inspect its error before replacing your working notebook.

Quotes preserve exact imported text, including CRLF and Unicode. The final
selected line's line-feed delimiter is excluded; CR characters remain as source
bytes. The command refuses unknown sources, invalid/blank or >2000-character
ranges, blank notes, duplicate passages and more than 16 excerpts. Observation
and challenge limits remain 4000 characters. Remove uses the one-based position
in the current `excerpts` array and preserves remaining order. Neither command
changes imported pages, other authored fields, source files or saved drafts.

Fill in your question, falsifier, dissent, assumptions and named owners as usual.
Select at least two Books, then use the existing `save` command. It independently
checks selected current source bytes against the imported notebook before saving.
Open the saved draft in Collaboration to edit, Prepare and export. Selecting
lines does not start participants, infer agreement, update Book truth or qualify
autonomous emergence. Browser, provider execution and production release gates
remain separate.

API: `MaterialNotebook.select_lines` and `remove_excerpt`. Focused contract tests
are in `src/collaboration_contract/material_selection_test.mbt`; the native CLI
journey imports two fictional Books, selects/removes/reselects, refuses a
duplicate, saves through the actual store and retries byte-identically.
