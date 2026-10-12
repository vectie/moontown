///|
fn comparison_fixture() -> @collaboration_contract.RetainedOutcome {
  let base = outcome_reply(0, outcome_key()).outcome.unwrap()
  let sources : Array[@collaboration_contract.SourceSnapshot] = [
    {
      book_id: "water",
      book_title: "Water",
      source_path: "raw/claim.md",
      artifact_ref: "r1/water/claim.md",
      digest: "sha256:water",
      size_bytes: 12,
    },
    {
      book_id: "mobility",
      book_title: "Mobility",
      source_path: "raw/claim.md",
      artifact_ref: "r1/mobility/claim.md",
      digest: "sha256:mobility",
      size_bytes: 14,
    },
  ]
  let assignments = sources.map(s => @collaboration_contract.Participant::{
    book_id: s.book_id,
    source_paths: [s.source_path],
    focus_area: "Evidence",
    perspective: "Independent",
    contribution: "Compare observations",
    next_artifact: "Review note",
  })
  let participants = sources.map(s => @collaboration_contract.ParticipantWork::{
    book_id: s.book_id,
    packet_id: "packet-" + s.book_id,
    proposal_id: "proposal-" + s.book_id,
    run_id: "run-" + s.book_id,
    status: "completed",
    detail: "Retained",
    output_ref: "output/" + s.book_id,
    output_digest: "sha256:output-" + s.book_id,
    output_text: "Finding from " + s.book_id,
  })
  {
    ..base,
    saved: {
      ..base.saved,
      draft: {
        ..base.saved.draft,
        title: "River",
        question: "What changed?",
        participants: assignments,
      },
      sources,
    },
    work: {
      ..base.work,
      status: "completed",
      participants,
      decisions: [
        {
          decision_id: "review-result",
          reviewer_id: "keeper",
          reviewer_name: "Keeper",
          prompt: "Review the evidence",
          decision: "pending",
          rationale: "",
        },
      ],
    },
    review_status: "pending_review",
  }
}

///|
test "comparison pairs reordered books and same-path sources by identity with no positional changes" {
  let before = comparison_fixture()
  let after = {
    ..before,
    saved: {
      ..before.saved,
      sources: [before.saved.sources[1], before.saved.sources[0]],
      draft: {
        ..before.saved.draft,
        participants: [
          before.saved.draft.participants[1],
          before.saved.draft.participants[0],
        ],
      },
    },
    work: {
      ..before.work,
      participants: [before.work.participants[1], before.work.participants[0]],
    },
  }
  let result = @collaboration_contract.compare_outcomes(before, after)
  assert_true(result.sources.all(row => row.change == "unchanged"))
  assert_true(result.contributions.all(row => row.change == "unchanged"))
  assert_true(result.assignments.all(row => row.change == "unchanged"))
  assert_eq(result.sources[0].identity, "water:raw/claim.md")
  assert_eq(result.sources[1].identity, "mobility:raw/claim.md")
  assert_true(result.markdown().contains("0 changed entries; 2 unchanged."))
}

///|
test "comparison reports added removed and changed attributed contributions without inventing text for failure" {
  let before = comparison_fixture()
  let failed = {
    ..before.work.participants[0],
    status: "failed",
    detail: "Source unavailable",
    output_text: "",
    output_digest: "",
    output_ref: "",
  }
  let added = {
    ..before.work.participants[1],
    book_id: "energy",
    output_text: "New evidence",
  }
  let after = {
    ..before,
    work: { ..before.work, status: "partial", participants: [added, failed], },
  }
  let result = @collaboration_contract.compare_outcomes(before, after)
  assert_eq(result.contributions.map(row => (row.identity, row.change)), [
    ("water", "changed"),
    ("mobility", "removed"),
    ("energy", "added"),
  ])
  assert_eq(result.contributions[0].after.unwrap().output_text, "")
  assert_eq(result.contributions[1].after, None)
  assert_eq(result.contributions[2].before, None)
  let text = result.markdown()
  assert_true(text.contains("Source unavailable"))
  assert_true(text.contains("Finding from water"))
  assert_true(text.contains("New evidence"))
  assert_true(text.contains("Absent from this selected outcome."))
  let reversed = @collaboration_contract.compare_outcomes(after, before)
  assert_eq(reversed.contributions[0].change, "removed")
}

///|
test "comparison preserves changed source digests and ignores revision-only paths and execution identities" {
  let before = comparison_fixture()
  let after = {
    ..before,
    saved: {
      ..before.saved,
      sources: [
        { ..before.saved.sources[0], digest: "sha256:new", size_bytes: 15, },
        { ..before.saved.sources[1], artifact_ref: "r2/mobility/claim.md", },
      ],
    },
    work: {
      ..before.work,
      participants: before.work.participants.map(p => {
        ..p,
        run_id: "another-run",
        proposal_id: "another-proposal",
        packet_id: "another-packet",
        output_ref: "r2/report.md",
      }),
    },
  }
  let result = @collaboration_contract.compare_outcomes(before, after)
  assert_eq(result.sources.map(row => row.change), ["changed", "unchanged"])
  assert_eq(result.sources[0].before.unwrap().digest, "sha256:water")
  assert_eq(result.sources[0].after.unwrap().digest, "sha256:new")
  assert_true(result.contributions.all(row => row.change == "unchanged"))
  assert_eq(result.contributions[0].after.unwrap().run_id, "another-run")
  let json = result.to_json()
  let roundtrip : @collaboration_contract.OutcomeComparison = @json.from_json(
    json,
  )
  assert_eq(roundtrip, result)
}

///|
test "comparison shows review-only decisions and changed scope without reusing approval" {
  let before = comparison_fixture()
  let after = {
    ..before,
    key: { ..before.key, review_version: 3, review_digest: "sha256:review3", },
    review_status: "deferred",
    saved: {
      ..before.saved,
      draft: { ..before.saved.draft, question: "What needs re-review?", },
    },
    work: {
      ..before.work,
      review_version: 3,
      decisions: [
        {
          ..before.work.decisions[0],
          decision: "defer",
          rationale: "Different observation periods",
        },
      ],
    },
  }
  let result = @collaboration_contract.compare_outcomes(before, after)
  assert_eq(result.decisions[0].change, "changed")
  assert_eq(result.after.review_version, 3)
  assert_eq(result.before.review_version, 2)
  assert_true(
    result.fields.any(row => {
      row.identity == "question" && row.change == "changed"
    }),
  )
  assert_true(result.markdown().contains("Different observation periods"))
  assert_true(result.markdown().contains("not inferred contradictions"))
}

///|
test "comparison literal report keeps multiline unicode and source markup inert" {
  let before = comparison_fixture()
  let literal = "水 café 🚲\n# Forged heading\n<script>alert(1)</script>\n```"
  let after = {
    ..before,
    work: {
      ..before.work,
      participants: [
        { ..before.work.participants[0], output_text: literal, },
        before.work.participants[1],
      ],
    },
  }
  let result = @collaboration_contract.compare_outcomes(before, after)
  let text = result.markdown()
  assert_true(
    text.contains("    水 café 🚲\n    # Forged heading\n    <script>"),
  )
  assert_false(text.contains("\n# Forged heading"))
  let carriage = {
    ..after,
    work: {
      ..after.work,
      participants: [
        {
          ..after.work.participants[0],
          output_text: "line\r<script>bare CR</script>\r\n# CRLF",
        },
      ],
    },
  }
  let safe = @collaboration_contract.compare_outcomes(before, carriage).markdown()
  assert_true(
    safe.contains("    line\n    <script>bare CR</script>\n    # CRLF"),
  )
  assert_false(safe.contains("\r"))
  assert_eq(result.contributions[0].after.unwrap().output_text, literal)
}

///|
test "comparison refuses ambiguous duplicate identities and mismatched selected keys" {
  let before = comparison_fixture()
  let duplicate = {
    ..before,
    saved: {
      ..before.saved,
      sources: [before.saved.sources[0], before.saved.sources[0]],
    },
  }
  assert_true(
    (try? @collaboration_contract.compare_outcomes(before, duplicate)) is Err(_),
  )
  let wrong = { ..before, key: { ..before.key, revision: "other", }, }
  assert_true(
    (try? @collaboration_contract.compare_outcomes(before, wrong)) is Err(_),
  )
  let duplicate = {
    ..before,
    work: {
      ..before.work,
      participants: [before.work.participants[0], before.work.participants[0]],
    },
  }
  assert_true(
    (try? @collaboration_contract.compare_outcomes(duplicate, before)) is Err(_),
  )
}

///|
test "comparison source additions removals and assignment changes stay distinct from output changes" {
  let before = comparison_fixture()
  let after = {
    ..before,
    saved: {
      ..before.saved,
      sources: [
        before.saved.sources[1],
        { ..before.saved.sources[0], source_path: "raw/new.md", },
      ],
      draft: {
        ..before.saved.draft,
        participants: [
          {
            ..before.saved.draft.participants[0],
            perspective: "Different observation period",
          },
          before.saved.draft.participants[1],
        ],
      },
    },
  }
  let result = @collaboration_contract.compare_outcomes(before, after)
  assert_eq(result.sources.map(row => row.change), [
    "removed", "unchanged", "added",
  ])
  assert_eq(result.assignments[0].change, "changed")
  assert_true(result.contributions.all(row => row.change == "unchanged"))
  let text = result.markdown()
  assert_true(text.contains("question: What changed?"))
  assert_true(text.contains("Different observation period"))
}

///|
test "comparison oversized briefs fail explicitly rather than silently truncating contributions" {
  let before = comparison_fixture()
  let after = {
    ..before,
    work: {
      ..before.work,
      participants: [
        { ..before.work.participants[0], output_text: "x".repeat(4194304), },
      ],
    },
  }
  let result = @collaboration_contract.compare_outcomes(before, after)
  assert_true((try? result.markdown()) is Err(_))
}
