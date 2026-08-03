# Raw Bootstrap Packet Schema

This schema defines the conservative raw packet shape for the current consolidation pass under `raw/bootstrap/`.

It is designed for raw-first MoonBook ingest:
- raw observations land first and remain separable from maintained wiki synthesis
- every evidence item carries provenance
- candidate wiki updates are proposals, not assertions
- weak material is called out explicitly through uncertainty and blocker sections

Use one packet file per consolidation slice, typically JSON named like `raw/bootstrap/<topic>-packet.json`.
The schema below is the canonical field contract to mirror in those packet files.

## Design Constraints

- Keep claims at evidence level unless they are already verified in durable project material.
- Prefer short source summaries plus evidence bullets over polished narrative prose.
- Preserve provenance granularly enough that a maintainer can reopen the underlying source.
- Record cross-project linkage hypotheses separately from confirmed relationships.
- When evidence is sparse, fill `uncertainty` and `blockers` rather than smoothing over gaps.
- Keep raw packets self-describing so MoonBook can ingest them before wiki updates are accepted.

## Recommended Shape

```json
{
  "packet_version": "moonbook.raw.bootstrap.packet.v1",
  "packet_kind": "raw_bootstrap_consolidation",
  "topic": "string",
  "generated_at": "ISO-8601 timestamp",
  "consolidation_pass": {
    "job_id": "string",
    "run_id": "string",
    "step_id": "string",
    "source_scope": "string",
    "notes": ["string"]
  },
  "book": {
    "book_id": "string",
    "workspace_root": "string",
    "target_paths": [
      "wiki/log.md",
      "wiki/synthesis/maintenance-plan.md",
      "wiki/synthesis/evidence.md",
      "raw/README.md"
    ]
  },
  "source_summaries": [
    {
      "source_id": "string",
      "title": "string",
      "source_type": "repo_file | prior_packet | note | transcript | external_reference | unknown",
      "locator": "path, URL, or durable identifier",
      "summary": "short factual summary",
      "relevance": "why this source matters to the topic",
      "confidence": "high | medium | low",
      "provenance": {
        "captured_from": "string",
        "captured_at": "ISO-8601 timestamp or null",
        "author": "string or null"
      }
    }
  ],
  "evidence_bullets": [
    {
      "evidence_id": "string",
      "claim": "specific observation stated narrowly",
      "status": "observed | partially_supported | unverified | conflicting",
      "importance": "high | medium | low",
      "provenance": [
        {
          "source_id": "string",
          "locator": "path/anchor/line range/URL fragment",
          "quote": "optional short supporting excerpt",
          "note": "optional explanation of how the source supports the observation"
        }
      ],
      "cross_project_tags": ["Moontown", "MoonBook", "MoonClaw"],
      "limitations": ["what is missing, ambiguous, or inferred"]
    }
  ],
  "candidate_wiki_updates": [
    {
      "page": "wiki/... or raw/... path",
      "section": "string or null",
      "intent": "create | extend | revise | verify_only",
      "priority": "high | medium | low",
      "proposed_change": "brief description of what should change",
      "backing_evidence_ids": ["string"],
      "status": "ready | needs_review | blocked",
      "cautions": ["reasons to avoid overstating the update"]
    }
  ],
  "cross_project_linkage_notes": [
    {
      "link_id": "string",
      "summary": "short note about a relationship across projects or boundaries",
      "projects": ["Moontown", "MoonBook", "MoonClaw"],
      "relationship_type": "confirmed_interface | inferred_dependency | workflow_handoff | terminology_overlap | unknown",
      "evidence_ids": ["string"],
      "confidence": "high | medium | low",
      "open_questions": ["string"]
    }
  ],
  "uncertainty": {
    "overall_strength": "strong | mixed | weak",
    "gaps": ["missing source coverage or unresolved ambiguity"],
    "conflicts": ["contradictory signals, if any"],
    "verification_needed": ["follow-up checks required before synthesis claims become durable"]
  },
  "blockers": [
    {
      "blocker_id": "string",
      "severity": "high | medium | low",
      "description": "what prevents stronger consolidation",
      "impact": "what cannot be claimed or updated until resolved",
      "needs": ["artifact, access, decision, or confirmation needed"]
    }
  ],
  "maintainer_notes": {
    "safe_to_materialize": false,
    "materialization_guidance": [
      "Only lift evidence into maintained wiki pages when supported by cited source summaries and evidence bullets.",
      "Keep uncertain cross-project relationships framed as hypotheses until confirmed.",
      "If blockers remain high severity, prefer updating `wiki/log.md` or `raw/README.md` over synthesis pages."
    ]
  }
}
```

## Field Guidance

### `packet_version`

Use `moonbook.raw.bootstrap.packet.v1` so downstream tooling can distinguish this raw-first bootstrap packet from execution or keeper proposal packets.

### `source_summaries`

This is the durable inventory of source material seen during the pass.
Each item should summarize the source itself, not the final thesis. If a source was only partially visible or came from a prior step receipt, say so in `summary`, `confidence`, or `provenance`.

### `evidence_bullets`

This is the main ingest payload.
Keep each bullet narrow, source-backed, and reversible. Prefer:
- one observation per bullet
- explicit provenance entries
- `status: "unverified"` when the source is secondhand or incomplete
- `status: "conflicting"` when sources disagree or lifecycle state is unclear

Avoid merged conclusions like "the system definitely does X across all projects" unless the cited material directly supports that scope.

### `candidate_wiki_updates`

These are proposals for maintainers, not mandatory writes.
They align with current bootstrap task targets such as `wiki/log.md`, `wiki/synthesis/maintenance-plan.md`, `wiki/synthesis/evidence.md`, and `raw/README.md`.
If the evidence is thin, use `intent: "verify_only"` or `status: "needs_review"`.

### `cross_project_linkage_notes`

Use this section for Moontown/MoonBook/MoonClaw handoffs, shared terms, and interface edges.
Separate confirmed interfaces from inferred relationships with `relationship_type` and `confidence`.
If a linkage is only suggested by prompts, naming, or packet metadata, mark it low confidence.

### `uncertainty`

Always fill this section when material is weak, incomplete, or inherited from missing prior-step artifacts.
The goal is to make uncertainty visible to MoonBook ingest instead of hiding it in prose.

### `blockers`

List operational, evidentiary, or access blockers explicitly.
Typical examples:
- missing parent workflow packets
- unavailable receipts or generated artifacts
- absent source snapshots for a claimed cross-project relationship
- no durable wiki pages yet available to confirm a synthesis claim

## Minimal Example

```json
{
  "packet_version": "moonbook.raw.bootstrap.packet.v1",
  "packet_kind": "raw_bootstrap_consolidation",
  "topic": "proposal packet lifecycle bootstrap",
  "generated_at": "2026-04-17T20:19:24Z",
  "consolidation_pass": {
    "job_id": "job.proposal.20260417-201907-act-as-the-wiki-gather-usersk",
    "run_id": "run-20260417-201924-usersk",
    "step_id": "step_2_normalize_packet_schema",
    "source_scope": "current checkout plus exposed prior-step receipt",
    "notes": [
      "Parent gather outputs were not available in this step.",
      "Schema is defined conservatively to support best-effort ingest."
    ]
  },
  "book": {
    "book_id": "example-book",
    "workspace_root": ".",
    "target_paths": [
      "wiki/log.md",
      "wiki/synthesis/evidence.md",
      "raw/README.md"
    ]
  },
  "source_summaries": [
    {
      "source_id": "src-goal-run-bootstrap-task",
      "title": "Bootstrap ingest task definition",
      "source_type": "repo_file",
      "locator": "goal_run.mbt:411",
      "summary": "Defines a bootstrap ingest task that populates raw evidence and revises maintained wiki targets before answering a research question.",
      "relevance": "Shows the intended raw-first ingestion flow and default wiki targets.",
      "confidence": "high",
      "provenance": {
        "captured_from": "repository checkout",
        "captured_at": null,
        "author": null
      }
    }
  ],
  "evidence_bullets": [
    {
      "evidence_id": "ev-bootstrap-target-pages",
      "claim": "The bootstrap ingest task explicitly targets both maintained wiki pages and `raw/README.md`.",
      "status": "observed",
      "importance": "high",
      "provenance": [
        {
          "source_id": "src-goal-run-bootstrap-task",
          "locator": "goal_run.mbt:419",
          "quote": "target_pages=[\"wiki/log.md\", \"wiki/synthesis/maintenance-plan.md\", \"wiki/synthesis/evidence.md\", \"raw/README.md\"]",
          "note": "Directly names the paths expected during bootstrap work."
        }
      ],
      "cross_project_tags": ["MoonBook", "Moontown"],
      "limitations": [
        "This evidence shows task intent, not proof that all listed pages currently exist or were updated."
      ]
    }
  ],
  "candidate_wiki_updates": [
    {
      "page": "raw/README.md",
      "section": null,
      "intent": "extend",
      "priority": "high",
      "proposed_change": "Document the raw/bootstrap packet contract used for ingest-first consolidation.",
      "backing_evidence_ids": ["ev-bootstrap-target-pages"],
      "status": "ready",
      "cautions": [
        "Do not claim that downstream materialization is automated unless verified elsewhere."
      ]
    }
  ],
  "cross_project_linkage_notes": [
    {
      "link_id": "link-bootstrap-handoff",
      "summary": "Moontown defines bootstrap ingest tasks intended to populate MoonBook-managed raw and wiki surfaces before later synthesis.",
      "projects": ["Moontown", "MoonBook"],
      "relationship_type": "workflow_handoff",
      "evidence_ids": ["ev-bootstrap-target-pages"],
      "confidence": "medium",
      "open_questions": [
        "Whether MoonBook currently enforces this packet shape directly remains unverified in the available checkout."
      ]
    }
  ],
  "uncertainty": {
    "overall_strength": "mixed",
    "gaps": [
      "Parent workflow gather outputs and previously generated packet artifacts were not exposed to this step."
    ],
    "conflicts": [],
    "verification_needed": [
      "Confirm whether downstream MoonBook ingest tooling validates `packet_version` or only expects raw JSON shape."
    ]
  },
  "blockers": [
    {
      "blocker_id": "missing-parent-artifacts",
      "severity": "medium",
      "description": "Prior gather-lane packet outputs were unavailable during schema definition.",
      "impact": "The schema can align to visible bootstrap intent, but cannot mirror any hidden packet conventions from prior runs.",
      "needs": [
        "Expose parent step packet artifacts or receipts if stricter compatibility checks are required."
      ]
    }
  ],
  "maintainer_notes": {
    "safe_to_materialize": false,
    "materialization_guidance": [
      "Lift only directly supported observations into maintained wiki pages.",
      "Keep missing-artifact caveats attached to any synthesized summary."
    ]
  }
}
```

## Current Compatibility Notes

This schema is compatible with the repo's visible raw-first/bootstrap intent because:
- bootstrap work is explicitly aimed at `raw/README.md` plus maintained wiki targets in `goal_run.mbt:419`
- MoonClaw proposal packets already carry free-form JSON `metadata`, making this shape easy to embed or serialize alongside current packet flows in `adapters/moonclaw/client.mbt:120`
- existing task and execution structures already expect conservative, review-aware handoff behavior rather than fully materialized claims in `adapters/moonbook/client.mbt:186` and `roles/mayor.mbt:93`

What remains unverified from the visible checkout:
- whether MoonBook has a stricter on-disk `raw/bootstrap/` filename convention beyond plain JSON packets
- whether any hidden ingest worker expects additional top-level fields
- whether candidate wiki updates should eventually include patch-like payloads instead of descriptive proposals
