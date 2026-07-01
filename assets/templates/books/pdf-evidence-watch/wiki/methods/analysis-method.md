# Analysis Method

Describe how this book should analyze extracted PDF text.

## Research Question

What new knowledge should this watcher detect?

## Inclusion Criteria

- The PDF is from an allowed or intentionally searched source.
- The PDF is relevant to the book purpose.
- The PDF contains enough text to analyze.
- The content can change the baseline, add a useful source, or create a
  meaningful question.

## Extraction Checks

- Confirm title, publication date, author or organization, URL, and checksum.
- Confirm whether the PDF text was extracted fully or partially.
- Confirm the registered `unlimited_ocr` MoonTool was used for OCR, or record
  the fallback.
- Record extraction limitations such as scanned pages, missing tables, or bad
  OCR.

## Analysis Steps

1. Summarize the PDF's thesis or practical claim.
2. Extract claims, measurements, dates, named entities, and source-specific
   assumptions.
3. Compare against the current wiki baseline.
4. Decide whether the source changes facts, confidence, questions, or actions.
5. Separate accepted facts from rejected or uncertain claims.
6. Update wiki pages only when the change is useful.

## Output Standard

Prefer specific, cited, falsifiable findings over generic summaries. If the PDF
does not change the book, say so and explain why.

## Example Result

```text
source_title: 2026 Annual Domain Report
source_url: https://example.org/report.pdf
source_sha256: abc123
extraction_status: full_text
ocr_engine: unlimited-ocr
analysis_decision: update
accepted_facts_count: 3
rejected_facts_count: 1
changed_pages:
- wiki/sources/2026-annual-domain-report.md
- wiki/findings/new-adoption-pattern.md
notification_required: yes
reason: The report adds a new measured adoption trend not present in the baseline.
```
