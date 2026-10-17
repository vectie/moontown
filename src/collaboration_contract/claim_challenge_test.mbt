///|
test "claim comparison intake accepts the actual producer report and keeps contexts distinct" {
  let report = @collaboration_contract.decode_claim_comparison(
    source_claim_fixture_report(),
  ).unwrap()
  assert_eq(report.groups.length(), 2)
  assert_eq(report.groups[0].state, "different_values")
  assert_eq(report.groups[1].state, "single_book")
  assert_eq(report.groups[0].claims[0].book_id, "Imported Water")
  let input : @collaboration_contract.ClaimChallenge = @json.from_json(
    @json.parse(source_claim_fixture_input()),
  )
  let books : Array[@collaboration_contract.CatalogBook] = [
    { book_id: "water", title: "Water", },
    { book_id: "mobility", title: "Mobility", },
  ]
  let draft = @collaboration_contract.claim_challenge_draft(input, books).unwrap()
  let saved : @collaboration_contract.SavedDraft = @json.from_json(
    @json.parse(source_claim_fixture_saved()),
  )
  assert_eq(draft, saved.draft)
  assert_true(draft.question.contains("week A"))
  assert_false(draft.question.contains("week B"))
  assert_true(draft.question.contains(report.sources[0].digest))
}

///|
test "claim intake refuses inconsistent source summary duplicate claims schema and bounds" {
  let report = @collaboration_contract.decode_claim_comparison(
    source_claim_fixture_report(),
  ).unwrap()
  let group = report.groups[0]
  for
    altered in [
      { ..report, contract: "invented", },
      { ..report, state: "accepted", },
      { ..report, table_digest: "unhashed", },
      { ..report, groups: [{ ..group, state: "same_value", }], },
      { ..report, groups: [{ ..group, books: ["trusted"], }], },
      {
        ..report,
        groups: [{ ..group, claims: [group.claims[0], group.claims[0]], }],
      },
      { ..report, sources: [report.sources[0], report.sources[0]], },
    ] {
    assert_true(
      @collaboration_contract.decode_claim_comparison(
        altered.to_json().stringify(),
      )
      is Err(_),
    )
  }
  assert_true(
    @collaboration_contract.decode_claim_comparison("x".repeat(32769)) is Err(_),
  )
  assert_true(@collaboration_contract.decode_claim_comparison("{}") is Err(_))
}

///|
test "claim draft requires explicit registered mappings independent challenges and human review" {
  let input : @collaboration_contract.ClaimChallenge = @json.from_json(
    @json.parse(source_claim_fixture_input()),
  )
  let books : Array[@collaboration_contract.CatalogBook] = [
    { book_id: "water", title: "Water", },
    { book_id: "mobility", title: "Mobility", },
  ]
  for
    altered in [
      { ..input, mappings: [], },
      { ..input, mappings: [input.mappings[0], input.mappings[0]], },
      {
        ..input,
        mappings: [
          { ..input.mappings[0], book_id: "Imported Water", },
          input.mappings[1],
        ],
      },
      {
        ..input,
        mappings: [
          { ..input.mappings[0], book_id: "mobility", },
          input.mappings[1],
        ],
      },
      {
        ..input,
        mappings: [{ ..input.mappings[0], challenge: "", }, input.mappings[1]],
      },
      { ..input, falsifier: "", },
      { ..input, reviewer_id: "town-composer", },
      { ..input, objection_reviewer_id: "", },
      { ..input, group_index: 1, },
      { ..input, group_index: -1, },
    ] {
    assert_true(
      @collaboration_contract.claim_challenge_draft(altered, books) is Err(_),
    )
  }
  assert_true(
    @collaboration_contract.claim_challenge_draft(input, []) is Err(_),
  )
}
