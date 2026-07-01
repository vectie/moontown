# PDF Evidence Watch Contract

This is a specialized `research-book`. It should not become a new top-level
book family unless many non-PDF source types need incompatible lifecycle rules.

## Purpose

The book watches configured websites for relevant PDFs, downloads and extracts
the PDFs, analyzes extracted text with the method owned by this book, and
updates durable wiki pages only when the analysis produces accepted new
knowledge. MoonClaw owns OCR execution through registered tools; the current
default OCR capability is the `unlimited_ocr` MoonTool, and fallbacks must be
recorded as such.

## Ownership

- Moondesk owns human creation, source-list editing, method editing, and export.
- Moontown owns standing-goal cadence, routing, live status, and notification.
- MoonBook owns the durable book, PDFs, extracted text, wiki, review queues,
  generated site, and acceptance decisions.
- MoonClaw owns one bounded execution packet: discover, fetch, extract,
  analyze, and package results.
- The bookkeeper decides whether the result is accepted knowledge, rejected
  evidence, no-change patrol, or review debt.

## Required Flow

```text
configured websites
  -> discover candidate PDFs
  -> download new PDFs
  -> extract full text through MoonClaw's registered OCR tool
  -> normalize source metadata
  -> analyze with wiki/methods/analysis-method.md
  -> compare against existing baseline
  -> update wiki only on accepted delta
  -> notify operator when useful knowledge changes
```

## Durable Layout

```text
raw/pdfs/
  <sha256>.pdf
raw/extracted/
  <sha256>.txt
raw/analysis-runs/
  <timestamp>-<run-id>.md
wiki/sources/
  <source-slug>.md
wiki/findings/
  <finding-slug>.md
wiki/reviews/
  pdf-watch-review.md
wiki/history/
  standing-watch.md
```

## Acceptance Rule

Do not count a PDF as domain evidence just because it was downloaded or
extracted. A source becomes accepted evidence only when the bookkeeper records:

- source identity
- why it is relevant
- extracted text location
- OCR engine and fallback reason, when relevant
- analysis result
- accepted facts or accepted uncertainty
- changed wiki pages, if any
- rejection reason, if not accepted

## Standing-Watch Marker

Every watch cycle must end with:

```text
standing_goal_decision: update | no_change | needs_review | failed
delta_score: 0-100
new_source_count: <integer>
next_check_hint: normal | slower | faster | review
checked_sources_count: <integer>
new_sources_found: <integer>
accepted_facts_count: <integer>
rejected_facts_count: <integer>
wiki_pages_changed_count: <integer>
book_changed: yes | no
pdfs_downloaded_count: <integer>
pdfs_extracted_count: <integer>
ocr_engine: unlimited-ocr | other | none
notification_required: yes | no
```

## Notification Rule

Notify only when at least one of these is true:

- accepted new fact
- accepted new uncertainty or question
- changed conclusion
- changed recommendation
- new high-value source that needs operator review

No-change scans, failed downloads, duplicate PDFs, and generated-site rebuilds
must not notify as knowledge updates.
