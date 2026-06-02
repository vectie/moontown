# Analysis Result Schema

Use this schema for analysis run notes under `raw/analysis-runs/` and for
bookkeeper review summaries.

```text
pdf_analysis_result: moontown.pdf_evidence_watch.result.v1
run_id: <string>
source_title: <string>
source_url: <string>
source_sha256: <string>
extraction_status: full_text | partial_text | failed
analysis_decision: update | no_change | needs_review | failed
delta_score: 0-100
accepted_facts_count: <integer>
rejected_facts_count: <integer>
uncertain_claims_count: <integer>
changed_pages_count: <integer>
notification_required: yes | no
next_action: <text>
```
