# Explore local material before commissioning a research salon

Start from observations in registered Books, before a participant run exists.
Import exact local text, search it across Books, select passages, and write your
own question, possible connection and independent challenges. The result is an
ordinary editable Collaboration draft. It does not manufacture a contribution
or imply that two observations prove a pattern.

## Import, explore, edit, save

Build `src/cmd/material_notebook` with the paired MoonChat source layout described
in [Collaboration composer](COLLABORATION_COMPOSER.md). In the commands below,
`material_notebook` means that native executable. All paths refer to your local
machine. Use your existing registered Book catalog; this tool never registers
or changes a Book.

1. Write `selection.json`, choosing Book IDs and their exact workspace-relative
   text paths. For example:

   ```json
   [
     {"book_id":"water","source_paths":["raw/observations.md"]},
     {"book_id":"mobility","source_paths":["raw/observations.md"]}
   ]
   ```

2. Import the current bytes into a new local working document:

   ```sh
   material_notebook import /absolute/catalog.json shade-question selection.json > notebook.json
   material_notebook find notebook.json south
   material_notebook read notebook.json water raw/observations.md
   ```

   Import chooses no passages and writes no Town state. The notebook contains
   full UTF-8 source text, Book/path identity, byte size and SHA-256 digest.
   `find` is case-sensitive literal line search across every imported page. It
   reports the real matching-line count and returns up to 100 matches with
   Book, path, digest and one-based line number; truncation is explicit. `read`
   prints the exact imported file text. Neither reads newer live files.

3. Edit `notebook.json` with your usual text editor. Leave `pages` unchanged.
   Fill in `title`, `question`, `falsifier`, `dissent`, `assumptions`, and the
   named human reviewer/objection owner IDs and names. Use explicit uncertainty
   rather than an empty field. Add 2–16 `excerpts` drawn from at least two Books:

   ```json
   {
     "book_id":"water",
     "source_path":"raw/observations.md",
     "quote":"The south plot stayed dry after rain.",
     "observation":"Dry soil after rain raises a possible exposure question.",
     "challenge":"Check the actual rainfall and irrigation record."
   }
   ```

   The quote must be an exact nonempty passage, at most 2,000 characters.
   `observation` and `challenge` are your authored notes, kept separate from
   the source passage. Multiple distinct passages from a file share one input
   snapshot. Imported pages without selected excerpts are excluded from the
   resulting draft and cannot be counted as evidence or participants. The
   [fictional example](../examples/material-notebook/notebook.json) illustrates
   a shade hypothesis with an objection that the path and plot may differ.

4. Save explicitly into the same local collaboration store used by your host:

   ```sh
   material_notebook save /absolute/collaboration-store /absolute/catalog.json notebook.json 2026-10-14T08:00:00Z > saved.json
   ```

   The host independently resolves every selected Book, captures each selected
   current file, then checks its digest, size and full text against your notebook
   before persisting those very buffers. If material changed or the imported
   copy was edited, save is refused. Re-import and review the current passages;
   do not copy a new digest over an old quote to bypass review. Changed excluded
   pages do not block saving because they are not used.

5. Open **Collaboration → Load Books and saved drafts**, reopen the
   saved ID, and use the ordinary composer to edit assignments or wording,
   save a new revision, **Prepare one-off handoff**, and download its package.
   Preparation retains exact selected sources, the attributed passages and
   notes, an empty ideas array and the existing pending named-human review.
   No participant is started by import, search, save or preparation.

## Interruption and revisions

### Inspect matching material in context

Use `material_notebook context notebook.json south 1` to inspect each literal
match with one neighboring line on each side. Choose 0–10 neighbors. The output
retains the original Book, path, digest and matching line plus inclusive
`first_line` and `last_line` for each window. Copy those positions into the
existing `select` command after reading the context and writing your own notes.
The original imported text, including CRLF, is preserved. Windows are not
merged or selected automatically. A window longer than the existing 2,000
character excerpt limit must be narrowed explicitly before selecting it.

As with `find`, the query is a case-sensitive literal single line, the total
matching-line count is exact and only the first 100 matches are returned, with
an explicit truncation flag. Neighbor windows are clipped at page boundaries.
Search reads imported bytes only; the ordinary `save` still checks current
registered sources and requires a completed multi-Book inquiry.

### Revise notes on a selected passage

After selecting passages, revise an observation and its independent challenge
without removing or retyping the quote:

```sh
material_notebook revise notebook.json 1 "Consider an exposure difference" "Compare irrigation records" > revised.json
material_notebook save /absolute/collaboration-store /absolute/catalog.json revised.json 2026-10-14T11:47:00Z > saved.json
```

Positions are one-based in the notebook's `excerpts` array. Both notes must be
nonblank and at most 4,000 characters. The command replaces only those two
authored fields and retains imported pages, quote, Book/path identity, excerpt
order and all other inquiry fields. It prints a new notebook to stdout. Always
redirect to a new file: redirecting to the input truncates it before reading.
The ordinary save still verifies live selected source bytes and named reviewers.
Use a fresh draft ID for a separate inquiry if that ID was already saved with
different content. This edits an unsaved working notebook, not a persisted
collaboration revision, and does not turn an observation into a verified fact.

The local notebook is an editable file you retain. Import does not overwrite it
unless you choose the same shell output path. On an uncertain save, retry the
same notebook or reopen its ID: an exact retry returns the original revision.
The save command creates a fresh draft; it refuses different content under an
existing ID. Use the ordinary composer for subsequent revisions, or a new ID for
a separate notebook inquiry. Reopening verifies captured files and never silently
substitutes live Book content.

Ordinary composer saves can recapture current files. The original notebook's
passage/digest context remains historical authored context in the question;
if you want to re-establish notebook byte equality after source changes, import
and review a fresh notebook with a new draft ID.

## Bounds and meaning

Import accepts up to 16 regular nonhidden files, each at most 64 KiB, with at most
256 KiB of text in total. Paths must be relative, nontraversing and symlink-free
under existing registered Book roots. Binary/non-UTF-8 and NUL-containing files
are refused. The CLI accepts JSON inputs up to 1 MiB. A draft is at most 64 KiB;
select shorter passages if it does not fit. Owners, falsifier, dissent and
assumptions are required before notebook save. These bounds are smaller than
the ordinary binary-capable source composer by design.

This is source-visible bottom-up human inquiry authoring. It neither discovers
semantic relationships nor establishes causation, independent corroboration,
consensus, contradiction resolution or genuine autonomous emergence. No schedule,
provider, external transmission, Book truth change, company authority or saved
time is inferred. `research-salon` remains scenario configuration, not an
operation ID. Configured execution, meaningful human acceptance, live browser,
installed desktop, multi-day service and production authority remain separate
qualification gates.

## API and focused checks

- `Store.import_material(draft_id, selections)` returns a blank MaterialNotebook.
- `MaterialNotebook.find(literal)` returns attributed line matches.
- `MaterialNotebook.draft()` validates authored notes and constructs a draft.
- `Store.save_material_notebook(notebook, recorded_at)` verifies actual selected
  bytes and performs the ordinary immutable save.

Run contract tests with `moon test src/collaboration_contract --target js` and
native material tests with `moon test src/collaboration_authoring/material_notebook_wbtest.mbt --target native --strip -j 1` plus
`material_notebook_test.mbt`. Follow normal private HOME/XDG, external target and
serialized native build conventions. The feature tests use fictional local
observations; they do not qualify real Book findings or provider execution.
