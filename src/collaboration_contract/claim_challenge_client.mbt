///|
fn Client::edit_claim_challenge(
  self : Client,
  field : String,
  value : String,
) -> Client {
  if field == "claim_mode" && value == "off" {
    return {
      ..self.dismiss(),
      claim_fields: Map([]),
      notice: "Claim challenge notes discarded. The ordinary draft is unchanged; an interrupted save may already be durable. Reopen to check.",
    }
  }
  if self.busy() {
    return self
  }
  if (field == "claim_group" || field == "claim_report") &&
    self.claim_fields.get(field) == Some(value) {
    return self
  }
  if field == "claim_mode" && self.claim_fields.get(field) == Some(value) {
    return self
  }
  let fields = if field == "claim_report" || field == "claim_group" {
    let clean : Map[String, String] = { "claim_mode": "compose" }
    clean["claim_report"] = if field == "claim_report" {
      value
    } else {
      self.claim_fields.get("claim_report").unwrap_or("")
    }
    if field == "claim_group" {
      clean[field] = value
    }
    clean
  } else {
    self.claim_fields.copy()
  }
  fields[field] = value
  { ..self, claim_fields: fields, generation: self.generation + 1, }
}

///|
/// The same typed input is used for local preview and the native save request.
pub fn Client::claim_challenge_input(
  self : Client,
) -> Result[ClaimChallenge, String] {
  try {
    let fields = self.claim_fields
    fn text(fields : Map[String, String], name : String) -> String {
      fields.get("claim_" + name).unwrap_or("")
    }
    let comparison = text(fields, "report")
    let report = match decode_claim_comparison(comparison) {
      Ok(v) => v
      Err(e) => fail(e)
    }
    let group_index = @string.parse_int(text(fields, "group")) catch {
      _ => fail("Select one report group")
    }
    guard report.groups.get(group_index) is Some(group) else {
      fail("Select one report group")
    }
    {
      comparison,
      group_index,
      draft_id: text(fields, "id"),
      title: text(fields, "title"),
      question: text(fields, "question"),
      falsifier: text(fields, "falsifier"),
      reviewer_id: text(fields, "reviewer_id"),
      reviewer_name: text(fields, "reviewer_name"),
      objection: text(fields, "objection"),
      objection_reviewer_id: text(fields, "objection_reviewer_id"),
      objection_reviewer_name: text(fields, "objection_reviewer_name"),
      mappings: group.claims.mapi((index, claim) => {
        claim_id: claim.claim_id,
        book_id: text(fields, "book_" + index.to_string()),
        source_path: text(fields, "path_" + index.to_string()),
        challenge: text(fields, "challenge_" + index.to_string()),
      }),
    }
  } catch {
    error => Err("\{error}")
  } noraise {
    input => Ok(input)
  }
}
