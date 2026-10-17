///|
fn Client::edit_retained_inquiry(
  self : Client,
  field : String,
  value : String,
) -> Client {
  if field == "inquiry_mode" && value == "off" {
    return {
      ..self.dismiss(),
      inquiry_fields: Map([]),
      notice: "Inquiry notes discarded. The ordinary draft is unchanged; reopen saved drafts if a save was interrupted.",
    }
  }
  if self.busy() || self.inquiry_fields.get(field) == Some(value) {
    return self
  }
  guard self.outcome is Some(outcome) && salon_ready(outcome.work) else {
    return {
      ..self,
      notice: "Inspect a retained dossier with two successful contributions first",
    }
  }
  let fields = self.inquiry_fields.copy()
  fields[field] = value
  { ..self, inquiry_fields: fields, generation: self.generation + 1, }
}

///|
pub fn Client::retained_inquiry_input(
  self : Client,
) -> Result[RetainedInquiry, String] {
  guard self.outcome is Some(outcome) && self.outcome_key == Some(outcome.key) else {
    return Err("Inspect an exact retained result before composing an inquiry")
  }
  fn text(fields : Map[String, String], key : String) -> String {
    fields.get("inquiry_" + key).unwrap_or("")
  }
  let fields = self.inquiry_fields
  Ok({
    origin: outcome.key,
    draft_id: text(fields, "id"),
    title: text(fields, "title"),
    question: text(fields, "question"),
    falsifier: text(fields, "falsifier"),
    dissent: text(fields, "dissent"),
    assumptions: text(fields, "assumptions"),
    reviewer_id: text(fields, "reviewer_id"),
    reviewer_name: text(fields, "reviewer_name"),
    objection_reviewer_id: text(fields, "objection_reviewer_id"),
    objection_reviewer_name: text(fields, "objection_reviewer_name"),
    contributions: salon_candidates(outcome.work)
    .filter(p => text(fields, "include_" + p.book_id) == "yes")
    .map(p => {
      book_id: p.book_id,
      quote: text(fields, "quote_" + p.book_id),
      challenge: text(fields, "challenge_" + p.book_id),
    }),
  })
}

///|
pub fn Client::retained_inquiry_preview(self : Client) -> Result[Draft, String] {
  match (self.retained_inquiry_input(), self.outcome) {
    (Ok(input), Some(outcome)) => retained_inquiry_draft(input, outcome)
    (Err(error), _) => Err(error)
    _ => Err("Inspect an exact retained result before composing an inquiry")
  }
}
