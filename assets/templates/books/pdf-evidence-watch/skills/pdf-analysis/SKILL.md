---
name: pdf-analysis
description: Analyze extracted PDF text according to a book-owned method, compare it against the current MoonBook baseline, and produce accepted/rejected findings with page update recommendations.
---

# PDF Analysis Skill

Use this skill after PDF text has been extracted for a PDF Evidence Watch Book.

## Mission

Convert extracted PDF text into durable knowledge only when it improves the
book. The analysis must be method-driven, source-grounded, and explicit about
uncertainty.

## Required Inputs

- extracted text file path
- source metadata
- OCR engine and extraction notes
- `wiki/methods/analysis-method.md`
- existing source pages and findings
- current synthesis or index pages

## Analysis Procedure

1. Identify the PDF's topic, issuer, date, and intended audience.
2. Extract claims, numbers, definitions, entities, dates, assumptions, and
   recommendations.
3. Compare each candidate finding against existing wiki pages.
4. Mark each candidate as accepted, rejected, duplicate, uncertain, or review.
5. Propose the smallest durable page updates needed.
6. Write notification text only if accepted knowledge changes.

## Result Contract

```text
pdf_analysis_result: moontown.pdf_evidence_watch.result.v1
source_title: <title>
source_url: <url>
source_sha256: <sha256>
extraction_status: full_text | partial_text | failed
ocr_engine: unlimited-ocr | other | none
analysis_decision: update | no_change | needs_review | failed
accepted_facts_count: <integer>
rejected_facts_count: <integer>
uncertain_claims_count: <integer>
changed_pages_count: <integer>
notification_required: yes | no
```

## Quality Bar

- A good result explains what changed and why it matters.
- A good result cites the source metadata and extracted text location.
- A good result separates facts from interpretation.
- A good result can say `no_change` after real checking.
- A bad result summarizes a PDF without comparing it to the baseline.

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
pdf_analysis_result: moontown.pdf_evidence_watch.result.v1
source_title: 2026 Regional Technology Outlook
source_url: https://example.org/2026-outlook.pdf
source_sha256: 9a1f...
extraction_status: full_text
analysis_decision: update
accepted_facts_count: 2
rejected_facts_count: 0
uncertain_claims_count: 1
changed_pages_count: 2
notification_required: yes

Accepted findings:
- The report introduces a new deployment metric not present in the current
  baseline.
- The report names two new policy constraints that change the adoption-risk
  section.

Review item:
- The cost table appears inconsistent with the narrative section and should be
  checked against the original PDF before promotion.
```
