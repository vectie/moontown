///|
pub(all) struct ComparedClaim {
  claim_id : String
  book_id : String
  topic : String
  context : String
  value : String
  source_path : String
  quote : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ComparedSource {
  path : String
  digest : String
  size_bytes : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ComparedGroup {
  topic : String
  context : String
  state : String
  books : Array[String]
  claims : Array[ComparedClaim]
} derive(Debug, Eq, ToJson, FromJson)

///|
/// These are imported assertions, never catalog identities or authority.
pub(all) struct ClaimComparison {
  contract : String
  state : String
  policy : String
  table_digest : String
  table_size_bytes : Int
  sources : Array[ComparedSource]
  groups : Array[ComparedGroup]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn claim_digest_valid(value : String) -> Bool {
  value.length() == 71 &&
  value.has_prefix("sha256:") &&
  value[7:].iter().all(c => (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'))
}

///|
/// Read the actual claim-comparison v1 output without trusting its summary labels.
/// This bounded intake accepts reports up to 32 KiB; narrow larger comparisons.
///
/// ```mbt check
/// test {
///   assert_true(decode_claim_comparison("{}") is Err(_))
/// }
/// ```
pub fn decode_claim_comparison(raw : String) -> Result[ClaimComparison, String] {
  try {
    guard @utf8.encode(raw).length() <= 32768 else {
      fail("Narrow the report to at most 32 KiB")
    }
    let json = @json.parse(raw)
    let report : ClaimComparison = @json.from_json(json)
    guard report.to_json() == json &&
      report.contract == "moontown.claim-comparison.v1" &&
      report.state == "pending_review" &&
      claim_digest_valid(report.table_digest) &&
      report.table_size_bytes > 0 &&
      report.table_size_bytes <= 1048576 &&
      report.groups.length() > 0 &&
      report.groups.length() <= 200 &&
      report.sources.length() > 0 &&
      report.sources.length() <= 64 else {
      fail("Expected a complete pending moontown.claim-comparison.v1 report")
    }
    let paths : Array[String] = []
    let mut total_source_bytes = 0
    for source in report.sources {
      guard safe_source_path(source.path) &&
        !paths.contains(source.path) &&
        claim_digest_valid(source.digest) &&
        source.size_bytes >= 0 &&
        source.size_bytes <= 262144 else {
        fail(
          "Report source identity is invalid or outside this intake's path limits",
        )
      }
      paths.push(source.path)
      total_source_bytes += source.size_bytes
    }
    guard total_source_bytes <= 8388608 else {
      fail("Report sources exceed the producer's 8 MiB bound")
    }
    let ids : Array[String] = []
    let cells : Array[(String, String)] = []
    let used : Array[String] = []
    for group in report.groups {
      guard !group.claims.is_empty() &&
        !cells.contains((group.topic, group.context)) else {
        fail("Report contains an empty or duplicate comparison group")
      }
      cells.push((group.topic, group.context))
      let books : Array[String] = []
      let values : Array[String] = []
      for claim in group.claims {
        guard !ids.contains(claim.claim_id) &&
          claim.topic == group.topic &&
          claim.context == group.context &&
          paths.contains(claim.source_path) else {
          fail(
            "Report claim identity, group, or source reference is inconsistent",
          )
        }
        for
          text in [
            claim.claim_id,
            claim.book_id,
            claim.topic,
            claim.context,
            claim.value,
            claim.source_path,
            claim.quote,
          ] {
          guard !text.trim().is_empty() && text.length() <= 16384 else {
            fail("Invalid report claim text")
          }
        }
        ids.push(claim.claim_id)
        if !used.contains(claim.source_path) {
          used.push(claim.source_path)
        }
        if !books.contains(claim.book_id) {
          books.push(claim.book_id)
        }
        if !values.contains(claim.value) {
          values.push(claim.value)
        }
      }
      let state = if books.length() < 2 {
        "single_book"
      } else if values.length() == 1 {
        "same_value"
      } else {
        "different_values"
      }
      guard group.books == books && group.state == state else {
        fail("Report summary disagrees with its exact claim text")
      }
    }
    guard ids.length() <= 200 && used.length() == paths.length() else {
      fail("Report contains extra sources or too many claims")
    }
    report
  } catch {
    error => Err("\{error}")
  } noraise {
    value => Ok(value)
  }
}

///|
pub(all) struct ClaimSourceMapping {
  claim_id : String
  book_id : String
  source_path : String
  challenge : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ClaimChallenge {
  comparison : String
  group_index : Int
  draft_id : String
  title : String
  question : String
  falsifier : String
  reviewer_id : String
  reviewer_name : String
  objection : String
  objection_reviewer_id : String
  objection_reviewer_name : String
  mappings : Array[ClaimSourceMapping]
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Make an ordinary editable Draft. Native save must additionally verify the
/// exact captured bytes for every mapping before writing those same buffers.
pub fn claim_challenge_draft(
  input : ClaimChallenge,
  books : Array[CatalogBook],
) -> Result[Draft, String] {
  try {
    let report = match decode_claim_comparison(input.comparison) {
      Ok(v) => v
      Err(e) => fail(e)
    }
    guard report.groups.get(input.group_index) is Some(group) &&
      group.claims.length() >= 2 &&
      group.claims.length() <= 16 &&
      group.books.length() >= 2 else {
      fail("Select a cross-label group containing 2 to 16 claims")
    }
    guard safe_id(input.draft_id) && input.title.length() <= 200 else {
      fail("Choose a safe draft ID and title up to 200 characters")
    }
    for
      text in [
        input.title,
        input.question,
        input.falsifier,
        input.reviewer_name,
      ] {
      guard !text.trim().is_empty() && text.length() <= 4000 else {
        fail("Enter a title, question, falsifier and named human reviewer")
      }
    }
    guard input.objection.length() <= 4000 &&
      input.mappings.length() == group.claims.length() else {
      fail(
        "Map every selected claim exactly once; keep the objection within 4000 characters",
      )
    }
    let participants : Array[Participant] = []
    let provenance : Array[Json] = []
    let seen : Array[String] = []
    for claim in group.claims {
      let matches = input.mappings.filter(m => m.claim_id == claim.claim_id)
      guard matches.length() == 1 else {
        fail("Map each selected claim exactly once")
      }
      let mapping = matches[0]
      guard books.filter(b => b.book_id == mapping.book_id).length() == 1 &&
        safe_source_path(mapping.source_path) &&
        !mapping.challenge.trim().is_empty() &&
        mapping.challenge.length() <= 4000 else {
        fail(
          "Explicitly map every claim to a registered Book, relative path and authored independent challenge",
        )
      }
      let source = report.sources.filter(s => s.path == claim.source_path)[0]
      provenance.push({
        "imported_claim": claim.to_json(),
        "reported_source": source.to_json(),
        "explicit_mapping": mapping.to_json(),
      })
      if !seen.contains(mapping.book_id) {
        seen.push(mapping.book_id)
        let assignments = input.mappings.filter(m => {
          m.book_id == mapping.book_id
        })
        let selected : Array[String] = []
        for m in assignments {
          if !selected.contains(m.source_path) {
            selected.push(m.source_path)
          }
        }
        participants.push({
          book_id: mapping.book_id,
          source_paths: selected,
          focus_area: group.topic,
          perspective: "Challenge independently; imported labels do not establish ownership, truth, agreement or contradiction.",
          contribution: assignments
          .map(m => m.claim_id + ": " + m.challenge)
          .join("\n"),
          next_artifact: "A source-bound challenge note with counterexamples, missing evidence and a test of this falsifier: " +
          input.falsifier,
        })
      }
    }
    guard participants.length() >= 2 else {
      fail("Map the claims to at least two distinct registered Books")
    }
    let context : Json = {
      "contract": "moontown.source-claim-challenge.v1",
      "reported_table_digest": report.table_digest,
      "reported_table_size_bytes": report.table_size_bytes,
      "selected_group_index": input.group_index,
      "topic": group.topic,
      "context": group.context,
      "text_comparison": group.state,
      "claims": provenance,
      "falsifier": input.falsifier,
    }
    let draft : Draft = {
      draft_id: input.draft_id,
      title: input.title,
      question: input.question +
      "\n\nOperator-authored source challenge. Different exact values are candidate differences, not semantic contradictions; matching values do not verify truth. Imported labels and table digest are unverified assertions. Source bytes are checked at this initial save against the mapped registered Book files; later ordinary edits or reuse recapture current bytes and must be reviewed. No work has run and no review or Book acceptance is inherited.\n\n" +
      context.stringify(indent=2),
      reviewer_id: input.reviewer_id,
      reviewer_name: input.reviewer_name,
      decision_prompt: "Review the explicit mappings, source account, independent challenges and falsifier. This plan review does not execute work or accept an outcome into a Book.",
      objection: input.objection,
      objection_reviewer_id: input.objection_reviewer_id,
      objection_reviewer_name: input.objection_reviewer_name,
      participants,
    }
    let issues = preparation_issues({
      contract_version: "moontown.collaboration-draft.v1",
      draft,
      revision: "pending",
      previous_revision: "",
      recorded_at: "",
      sources: participants.map(p => {
        book_id: p.book_id,
        book_title: "pending capture",
        source_path: p.source_paths[0],
        artifact_ref: "pending",
        digest: "pending",
        size_bytes: 0,
      }),
    })
    guard issues.is_empty() else { fail(issues.join("; ")) }
    guard @utf8.encode(draft.to_json().stringify()).length() <= 65536 else {
      fail(
        "Narrow the selected group and authored challenges to fit the ordinary draft limit",
      )
    }
    draft
  } catch {
    error => Err("\{error}")
  } noraise {
    value => Ok(value)
  }
}
