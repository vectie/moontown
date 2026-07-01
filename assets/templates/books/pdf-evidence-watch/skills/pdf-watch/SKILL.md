---
name: pdf-watch
description: Watch configured websites for relevant PDFs, dedupe them, download new PDFs, extract text, and emit strict standing-watch accounting for a PDF Evidence Watch Book.
---

# PDF Watch Skill

Use this skill when a MoonClaw worker or MoonBook keeper is running a
`pdf-evidence-watch` standing goal.

## Mission

Find relevant PDFs from configured websites, preserve source metadata, extract
the full text when possible, and hand off analysis to the book's analysis
method. Use MoonClaw's registered `unlimited_ocr` MoonTool as the default OCR
capability when scanned or image-heavy PDFs need OCR. The goal is not to
produce noise. The goal is to identify whether new knowledge entered the
domain.

## Inputs

- `book.json`
- `raw/bootstrap/PDF_WATCH_CONTRACT.md`
- `wiki/methods/analysis-method.md`
- previous `wiki/history/standing-watch.md`
- existing `wiki/sources/*.md`
- configured websites and search hints

## Required Procedure

1. Read `book.json` and the analysis method before searching.
2. Search configured websites first. If source policy is `web-first`, use web
   search before local fallback.
3. Identify candidate PDFs with title, URL, publisher, date when available,
   and relevance reason.
4. Dedupe by URL, title, and checksum when a PDF is fetched.
5. Download only relevant PDFs.
6. Extract full text into `raw/extracted/<sha256>.txt`, using the registered
   `unlimited_ocr` MoonTool by default for PDF OCR.
7. If the OCR MoonTool is unavailable or extraction is partial, record the
   engine, fallback, and limitation.
8. Analyze extracted text using `skills/pdf-analysis/SKILL.md`.
9. Write a per-run note under `raw/analysis-runs/`.
10. End with the strict standing-watch marker.

## Output Contract

Every run must include:

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

## Decision Rules

- `update`: at least one accepted fact, accepted question, source page, finding,
  or conclusion changed.
- `no_change`: sources were checked, but nothing useful changed.
- `needs_review`: the source may be important but extraction, evidence, legal,
  policy, or interpretation uncertainty requires human or keeper review.
- `failed`: the run could not perform a meaningful check.

## Quality Rules

- Do not notify for duplicate PDFs.
- Do not count downloads as accepted knowledge.
- Do not hide extraction failure.
- Do not silently replace the registered OCR MoonTool with another extractor;
  write the reason.
- Do not rewrite the whole book when one source changes.
- Prefer precise source pages and small finding updates over broad generic
  summaries.

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

## Concrete Example

```text
standing_goal_decision: update
delta_score: 72
new_source_count: 2
next_check_hint: normal
checked_sources_count: 7
new_sources_found: 2
accepted_facts_count: 4
rejected_facts_count: 1
wiki_pages_changed_count: 3
book_changed: yes
pdfs_downloaded_count: 2
pdfs_extracted_count: 2
notification_required: yes

Summary:
Two new annual reports were found. One added four accepted facts and changed
the baseline adoption estimate. The second was kept as a review source because
its table extraction was incomplete.
```
