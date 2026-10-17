// Generated from the actual claim_comparison report and native save fixtures.

///|
fn source_claim_fixture_report() -> String {
  (
    #|{"contract":"moontown.claim-comparison.v1","state":"pending_review","policy":"Operator-labelled topic, context, value and book identity. Groups match topic and context exactly; values compare as exact text. different_values is a candidate difference, not an inferred contradiction. same_value is textual agreement, not verified truth. Different contexts remain separate; single_book lacks a cross-book comparison. Quotes are checked against captured UTF-8 bytes and sources are hashed; no source ownership, semantic entailment, freshness or Book acceptance is asserted. No source or Book is changed.","table_digest":"sha256:ea2fc9ffa445fb785036db4cb18cbb205e0ce5af812667d195a1a34ce31c1d76","table_size_bytes":231,"sources":[{"path":"export/water.txt","digest":"sha256:61490f3333d7916bd91052cc9c04306b585ef740a3d598fb8b4b256c1a8b3a1d","size_bytes":9},{"path":"export/travel.txt","digest":"sha256:82872a7b11a7c0f4a1bd4d3212868a7c9d283b7ddab8084552f129847aeb995a","size_bytes":9}],"groups":[{"topic":"wait","context":"week A","state":"different_values","books":["Imported Water","Imported Travel"],"claims":[{"claim_id":"a","book_id":"Imported Water","topic":"wait","context":"week A","value":"12","source_path":"export/water.txt","quote":"Wait: 12"},{"claim_id":"b","book_id":"Imported Travel","topic":"wait","context":"week A","value":"18","source_path":"export/travel.txt","quote":"Wait: 18"}]},{"topic":"wait","context":"week B","state":"single_book","books":["Imported Water"],"claims":[{"claim_id":"c","book_id":"Imported Water","topic":"wait","context":"week B","value":"12","source_path":"export/water.txt","quote":"Wait: 12"}]}]}
    #|
  )
}

///|
fn source_claim_fixture_input() -> String {
  (
    #|{
    #|  "comparison": "{\"contract\":\"moontown.claim-comparison.v1\",\"state\":\"pending_review\",\"policy\":\"Operator-labelled topic, context, value and book identity. Groups match topic and context exactly; values compare as exact text. different_values is a candidate difference, not an inferred contradiction. same_value is textual agreement, not verified truth. Different contexts remain separate; single_book lacks a cross-book comparison. Quotes are checked against captured UTF-8 bytes and sources are hashed; no source ownership, semantic entailment, freshness or Book acceptance is asserted. No source or Book is changed.\",\"table_digest\":\"sha256:ea2fc9ffa445fb785036db4cb18cbb205e0ce5af812667d195a1a34ce31c1d76\",\"table_size_bytes\":231,\"sources\":[{\"path\":\"export/water.txt\",\"digest\":\"sha256:61490f3333d7916bd91052cc9c04306b585ef740a3d598fb8b4b256c1a8b3a1d\",\"size_bytes\":9},{\"path\":\"export/travel.txt\",\"digest\":\"sha256:82872a7b11a7c0f4a1bd4d3212868a7c9d283b7ddab8084552f129847aeb995a\",\"size_bytes\":9}],\"groups\":[{\"topic\":\"wait\",\"context\":\"week A\",\"state\":\"different_values\",\"books\":[\"Imported Water\",\"Imported Travel\"],\"claims\":[{\"claim_id\":\"a\",\"book_id\":\"Imported Water\",\"topic\":\"wait\",\"context\":\"week A\",\"value\":\"12\",\"source_path\":\"export/water.txt\",\"quote\":\"Wait: 12\"},{\"claim_id\":\"b\",\"book_id\":\"Imported Travel\",\"topic\":\"wait\",\"context\":\"week A\",\"value\":\"18\",\"source_path\":\"export/travel.txt\",\"quote\":\"Wait: 18\"}]},{\"topic\":\"wait\",\"context\":\"week B\",\"state\":\"single_book\",\"books\":[\"Imported Water\"],\"claims\":[{\"claim_id\":\"c\",\"book_id\":\"Imported Water\",\"topic\":\"wait\",\"context\":\"week B\",\"value\":\"12\",\"source_path\":\"export/water.txt\",\"quote\":\"Wait: 12\"}]}]}\n",
    #|  "group_index": 0,
    #|  "draft_id": "source-challenge",
    #|  "title": "Check the waiting-time difference",
    #|  "question": "Could sampling account for the reported difference?",
    #|  "falsifier": "The difference remains after matching the sampled cohorts.",
    #|  "reviewer_id": "alex",
    #|  "reviewer_name": "Alex",
    #|  "objection": "The samples may not describe the same population.",
    #|  "objection_reviewer_id": "sam",
    #|  "objection_reviewer_name": "Sam",
    #|  "mappings": [
    #|    {
    #|      "claim_id": "a",
    #|      "book_id": "water",
    #|      "source_path": "raw/nested/source.bin",
    #|      "challenge": "Find a sampling difference that could explain the observation."
    #|    },
    #|    {
    #|      "claim_id": "b",
    #|      "book_id": "mobility",
    #|      "source_path": "raw/nested/source.bin",
    #|      "challenge": "Independently test a transport-delay explanation."
    #|    }
    #|  ]
    #|}
  )
}

///|
fn source_claim_fixture_saved() -> String {
  (
    #|{
    #|  "contract_version": "moontown.collaboration-draft.v1",
    #|  "draft": {
    #|    "draft_id": "source-challenge",
    #|    "title": "Check the waiting-time difference",
    #|    "question": "Could sampling account for the reported difference?\n\nOperator-authored source challenge. Different exact values are candidate differences, not semantic contradictions; matching values do not verify truth. Imported labels and table digest are unverified assertions. Source bytes are checked at this initial save against the mapped registered Book files; later ordinary edits or reuse recapture current bytes and must be reviewed. No work has run and no review or Book acceptance is inherited.\n\n{\n  \"contract\": \"moontown.source-claim-challenge.v1\",\n  \"reported_table_digest\": \"sha256:ea2fc9ffa445fb785036db4cb18cbb205e0ce5af812667d195a1a34ce31c1d76\",\n  \"reported_table_size_bytes\": 231,\n  \"selected_group_index\": 0,\n  \"topic\": \"wait\",\n  \"context\": \"week A\",\n  \"text_comparison\": \"different_values\",\n  \"claims\": [\n    {\n      \"imported_claim\": {\n        \"claim_id\": \"a\",\n        \"book_id\": \"Imported Water\",\n        \"topic\": \"wait\",\n        \"context\": \"week A\",\n        \"value\": \"12\",\n        \"source_path\": \"export/water.txt\",\n        \"quote\": \"Wait: 12\"\n      },\n      \"reported_source\": {\n        \"path\": \"export/water.txt\",\n        \"digest\": \"sha256:61490f3333d7916bd91052cc9c04306b585ef740a3d598fb8b4b256c1a8b3a1d\",\n        \"size_bytes\": 9\n      },\n      \"explicit_mapping\": {\n        \"claim_id\": \"a\",\n        \"book_id\": \"water\",\n        \"source_path\": \"raw/nested/source.bin\",\n        \"challenge\": \"Find a sampling difference that could explain the observation.\"\n      }\n    },\n    {\n      \"imported_claim\": {\n        \"claim_id\": \"b\",\n        \"book_id\": \"Imported Travel\",\n        \"topic\": \"wait\",\n        \"context\": \"week A\",\n        \"value\": \"18\",\n        \"source_path\": \"export/travel.txt\",\n        \"quote\": \"Wait: 18\"\n      },\n      \"reported_source\": {\n        \"path\": \"export/travel.txt\",\n        \"digest\": \"sha256:82872a7b11a7c0f4a1bd4d3212868a7c9d283b7ddab8084552f129847aeb995a\",\n        \"size_bytes\": 9\n      },\n      \"explicit_mapping\": {\n        \"claim_id\": \"b\",\n        \"book_id\": \"mobility\",\n        \"source_path\": \"raw/nested/source.bin\",\n        \"challenge\": \"Independently test a transport-delay explanation.\"\n      }\n    }\n  ],\n  \"falsifier\": \"The difference remains after matching the sampled cohorts.\"\n}",
    #|    "reviewer_id": "alex",
    #|    "reviewer_name": "Alex",
    #|    "decision_prompt": "Review the explicit mappings, source account, independent challenges and falsifier. This plan review does not execute work or accept an outcome into a Book.",
    #|    "objection": "The samples may not describe the same population.",
    #|    "objection_reviewer_id": "sam",
    #|    "objection_reviewer_name": "Sam",
    #|    "participants": [
    #|      {
    #|        "book_id": "water",
    #|        "source_paths": [
    #|          "raw/nested/source.bin"
    #|        ],
    #|        "focus_area": "wait",
    #|        "perspective": "Challenge independently; imported labels do not establish ownership, truth, agreement or contradiction.",
    #|        "contribution": "a: Find a sampling difference that could explain the observation.",
    #|        "next_artifact": "A source-bound challenge note with counterexamples, missing evidence and a test of this falsifier: The difference remains after matching the sampled cohorts."
    #|      },
    #|      {
    #|        "book_id": "mobility",
    #|        "source_paths": [
    #|          "raw/nested/source.bin"
    #|        ],
    #|        "focus_area": "wait",
    #|        "perspective": "Challenge independently; imported labels do not establish ownership, truth, agreement or contradiction.",
    #|        "contribution": "b: Independently test a transport-delay explanation.",
    #|        "next_artifact": "A source-bound challenge note with counterexamples, missing evidence and a test of this falsifier: The difference remains after matching the sampled cohorts."
    #|      }
    #|    ]
    #|  },
    #|  "revision": "r-78742338a819c0e777da6ef60fd23794b390d15e8f4d485f58c273ca3c4bad60",
    #|  "previous_revision": "",
    #|  "recorded_at": "2026-10-14T00:00:00Z",
    #|  "sources": [
    #|    {
    #|      "book_id": "water",
    #|      "book_title": "water Book",
    #|      "source_path": "raw/nested/source.bin",
    #|      "artifact_ref": "sources/water/raw/nested/source.bin",
    #|      "digest": "sha256:61490f3333d7916bd91052cc9c04306b585ef740a3d598fb8b4b256c1a8b3a1d",
    #|      "size_bytes": 9
    #|    },
    #|    {
    #|      "book_id": "mobility",
    #|      "book_title": "mobility Book",
    #|      "source_path": "raw/nested/source.bin",
    #|      "artifact_ref": "sources/mobility/raw/nested/source.bin",
    #|      "digest": "sha256:82872a7b11a7c0f4a1bd4d3212868a7c9d283b7ddab8084552f129847aeb995a",
    #|      "size_bytes": 9
    #|    }
    #|  ]
    #|}
  )
}
