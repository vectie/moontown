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
      inquiry_dossiers: [],
      inquiry_outcomes: [],
      notice: "Inquiry notes discarded. The ordinary draft is unchanged; reopen saved drafts if a save was interrupted.",
    }
  }
  if self.busy() || self.inquiry_fields.get(field) == Some(value) {
    return self
  }
  if field == "inquiry_add_dossier" {
    return self.add_inquiry_dossier()
  }
  if field == "inquiry_remove_dossier" {
    let dossiers = self.inquiry_dossiers.filter(d => {
      d.origin.to_json().stringify() != value
    })
    return {
      ..self,
      inquiry_dossiers: dossiers,
      inquiry_outcomes: self.inquiry_outcomes.filter(o => {
        dossiers.any(d => d.origin == o.key)
      }),
      generation: self.generation + 1,
      notice: "Dossier removed from the cross-dossier inquiry",
    }
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
fn Client::add_inquiry_dossier(self : Client) -> Client {
  guard self.retained_inquiry_input() is Ok(input) &&
    self.outcome is Some(outcome) else {
    return { ..self, notice: "Inspect a retained dossier first", }
  }
  guard !input.contributions.is_empty() &&
    input.contributions.all(c => {
      !c.quote.trim().is_empty() &&
      c.quote.length() <= 1000 &&
      !c.challenge.trim().is_empty() &&
      c.challenge.length() <= 4000 &&
      salon_candidates(outcome.work).any(p => {
        p.book_id == c.book_id && p.output_text.contains(c.quote)
      })
    }) else {
    return {
      ..self,
      notice: "Select successful contributions with exact quotes and independent challenges before adding this dossier",
    }
  }
  let dossiers = self.inquiry_dossiers.filter(d => d.origin != input.origin)
  dossiers.push({ origin: input.origin, contributions: input.contributions, })
  let outcomes = self.inquiry_outcomes.filter(o => o.key != input.origin)
  outcomes.push(outcome)
  {
    ..self,
    inquiry_dossiers: dossiers,
    inquiry_outcomes: outcomes,
    generation: self.generation + 1,
    notice: "Selection added. Inspect another retained dossier, choose its excerpts and add it; then save the cross-dossier inquiry.",
  }
}

///|
pub fn Client::cross_dossier_inquiry_input(
  self : Client,
) -> Result[CrossDossierInquiry, String] {
  guard !self.inquiry_dossiers.is_empty() else {
    return Err("Add selected contributions to the inquiry first")
  }
  let authored = match self.retained_inquiry_input() {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let first = self.inquiry_dossiers[0]
  Ok({
    inquiry: {
      ..authored,
      origin: first.origin,
      contributions: first.contributions,
    },
    additional: self.inquiry_dossiers.filter(d => d.origin != first.origin),
  })
}

///|
pub fn Client::cross_dossier_inquiry_preview(
  self : Client,
) -> Result[Draft, String] {
  match self.cross_dossier_inquiry_input() {
    Ok(input) => cross_dossier_inquiry_draft(input, self.inquiry_outcomes)
    Err(error) => Err(error)
  }
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
