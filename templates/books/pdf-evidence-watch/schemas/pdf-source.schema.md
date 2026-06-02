# PDF Source Schema

Use this schema for source pages under `wiki/sources/`.

```text
pdf_source: moontown.pdf_source.v1
title: <string>
url: <string>
publisher: <string or unknown>
publication_date: <date or unknown>
discovered_at: <timestamp>
download_path: raw/pdfs/<sha256>.pdf
extracted_text_path: raw/extracted/<sha256>.txt
sha256: <string>
extraction_status: full_text | partial_text | failed
relevance: <why this PDF matters>
acceptance_status: accepted | rejected | needs_review | duplicate
accepted_facts_count: <integer>
rejected_facts_count: <integer>
changed_pages:
- <path>
review_notes: <text>
```
