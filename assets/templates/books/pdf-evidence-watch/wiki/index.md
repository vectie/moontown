# PDF Evidence Watch Book

This MoonBook is a source-first research workspace for recurring PDF-based
knowledge monitoring.

## Current Configuration

- Book type: `research-book`
- Specialization: `pdf-evidence-watch`
- Source policy: `web-first`
- Default cadence: `30 minutes`
- Method: `wiki/methods/analysis-method.md`

## Operating Rule

The book grows only when a watch cycle accepts new knowledge. Downloads,
extractions, failed fetches, duplicate checks, and operational patrols are
useful telemetry, but they are not accepted domain evidence by themselves.

## Main Surfaces

- `raw/pdfs/`: downloaded source PDFs
- `raw/extracted/`: extracted full text
- `raw/analysis-runs/`: per-run analysis notes
- `wiki/sources/`: accepted or reviewable source pages
- `wiki/findings/`: accepted findings, questions, and synthesis
- `wiki/reviews/`: bookkeeper review queue
- `wiki/history/standing-watch.md`: watch decisions and accounting

## Human Setup Checklist

- Add source websites in `book.json`.
- Write the analysis method in `wiki/methods/analysis-method.md`.
- Register a standing goal in `.moontown/standing-goals.json`.
- Run one manual watch cycle before enabling long-horizon operation.
- Check that notifications happen only for accepted knowledge changes.
