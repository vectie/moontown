# Example PDF Analysis Method

Use this file as the operator-owned method for a PDF Evidence Watch book.

## Extract

- Bibliographic metadata: title, authors, organization, date, URL, PDF hash.
- OCR status: registered `unlimited_ocr` MoonTool by default, plus engine
  version or fallback reason.
- Core claims and the exact page/section where each claim appears.
- Numeric tables, assumptions, units, and caveats.
- Definitions, changed terminology, and new concepts.
- Decision implications: what the operator should now believe, watch, or question.

## Compare

- Compare every new claim against existing `wiki/findings/` and `wiki/sources/`.
- Mark repeated material as no-change.
- Mark contradictory or weak material as review-needed.
- Promote only claims with enough provenance and relevance.

## Notify

Notify only when at least one accepted finding changes the book baseline.
No-change patrols should update `wiki/history/standing-watch.md` but should not
inflate domain evidence.
