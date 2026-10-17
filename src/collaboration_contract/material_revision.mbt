///|
/// Revise the operator's notes for an existing passage without selecting a new
/// quote or changing imported source bytes. Position is one-based.
pub fn MaterialNotebook::revise_excerpt(
  self : MaterialNotebook,
  position : Int,
  observation : String,
  challenge : String,
) -> MaterialNotebook raise {
  self.validate_pages()
  guard position >= 1 && position <= self.excerpts.length() else {
    fail("Select an existing one-based excerpt position")
  }
  guard !observation.trim().is_empty() &&
    !challenge.trim().is_empty() &&
    observation.length() <= 4000 &&
    challenge.length() <= 4000 else {
    fail("Write an observation and challenge, at most 4000 characters each")
  }
  let excerpts = self.excerpts.mapi((index, excerpt) => {
    if index == position - 1 {
      { ..excerpt, observation, challenge, }
    } else {
      excerpt
    }
  })
  { ..self, excerpts, }
}
