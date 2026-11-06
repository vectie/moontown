///|
/// A selection remains attached to the exact historical result/review version.
pub(all) struct InquiryDossier {
  origin : OutcomeKey
  contributions : Array[InquiryContribution]
} derive(Debug, Eq, ToJson, FromJson)

///|
/// The first inquiry supplies operator-authored fields and its first selection;
/// additional selections carry their own historical identities, never authority.
pub(all) struct CrossDossierInquiry {
  inquiry : RetainedInquiry
  additional : Array[InquiryDossier]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn cross_dossier_inquiry_draft(
  input : CrossDossierInquiry,
  outcomes : Array[RetainedOutcome],
) -> Result[Draft, String] {
  let selections : Array[InquiryDossier] = [
      {
        origin: input.inquiry.origin,
        contributions: input.inquiry.contributions,
      },
    ] +
    input.additional
  guard selections.length() >= 2 && selections.length() <= 16 else {
    return Err(
      "Add contributions from at least two distinct historical dossiers",
    )
  }
  let seen : Array[OutcomeKey] = []
  let drafts : Array[Draft] = []
  let participants : Array[Participant] = []
  let mut count = 0
  for selection in selections {
    guard !seen.contains(selection.origin) else {
      return Err(
        "Each pinned dossier can appear only once; replace its selection instead",
      )
    }
    seen.push(selection.origin)
    count = count + selection.contributions.length()
    let matches = outcomes.filter(o => o.key == selection.origin)
    guard matches.length() == 1 else {
      return Err("Inspect every selected historical dossier before composing")
    }
    let draft = match
      inquiry_dossier_draft(
        {
          ..input.inquiry,
          origin: selection.origin,
          contributions: selection.contributions,
        },
        matches[0],
        1,
      ) {
      Ok(draft) => draft
      Err(error) => return Err(error)
    }
    drafts.push(draft)
    for participant in draft.participants {
      let mut existing : Int32? = None
      for i = 0; i < participants.length(); i = i + 1 {
        if participants[i].book_id == participant.book_id {
          existing = Some(i)
        }
      }
      match existing {
        None => participants.push(participant)
        Some(index) => {
          let previous = participants[index]
          let paths = previous.source_paths.copy()
          for path in participant.source_paths {
            if !paths.contains(path) {
              paths.push(path)
            }
          }
          participants[index] = {
            ..previous,
            source_paths: paths,
            focus_area: previous.focus_area + "\n" + participant.focus_area,
            perspective: previous.perspective + "\n" + participant.perspective,
          }
        }
      }
    }
  }
  guard count <= 16 && participants.length() >= 2 else {
    return Err(
      "Choose up to sixteen contributions involving at least two Books",
    )
  }
  let draft : Draft = {
    ..drafts[0],
    question: input.inquiry.question +
    "\n\nCross-dossier historical evidence (each context retains its own origin, disagreements and decisions; no consensus is implied):\n" +
    drafts.map(d => d.question).join("\n\n--- Next pinned dossier ---\n\n"),
    objection: drafts
    .map(d => d.objection)
    .join("\n\n--- Next dossier objection ---\n\n"),
    participants,
  }
  guard @utf8.encode(draft.to_json().stringify()).length() <= 65536 else {
    return Err(
      "Cross-dossier inquiry exceeds 64 KiB; narrow the selected excerpts",
    )
  }
  Ok(draft)
}
