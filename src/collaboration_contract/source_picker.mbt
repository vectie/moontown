///|
/// A bounded live observation, never a captured source or revision identity.
pub(all) struct SourceListing {
  book_id : String
  paths : Array[String]
  scanned_entries : Int
  excluded_entries : Int
  unreadable_entries : Int
  truncated : Bool
  detail : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn Client::select_source_book(self : Client, id : String) -> Client {
  if !self.draft.participants.any(p => p.book_id == id) {
    return self
  }
  {
    ..self.dismiss(),
    source_book: id,
    source_listing: None,
    source_filter: "",
  }
}

///|
pub fn Client::visible_source_paths(self : Client) -> Array[String] {
  match self.source_listing {
    Some(listing) if listing.book_id == self.source_book =>
      listing.paths.filter(path => {
        path.to_lower().contains(self.source_filter.to_lower())
      })
    _ => []
  }
}

///|
pub fn Client::toggle_source(self : Client, path : String) -> Client {
  if self.busy() || !self.visible_source_paths().contains(path) {
    return self
  }
  guard self.draft.participants
    .filter(p => p.book_id == self.source_book)
    .get(0)
    is Some(p) else {
    return self
  }
  let paths = if p.source_paths.contains(path) {
    p.source_paths.filter(value => value != path)
  } else {
    if p.source_paths.length() >= 16 {
      return { ..self, notice: "Choose at most 16 files per Book", }
    }
    p.source_paths + [path]
  }
  {
    ..self,
    draft: {
      ..self.draft,
      participants: self.draft.participants.map(participant => {
        if participant.book_id == p.book_id {
          { ..participant, source_paths: paths, }
        } else {
          participant
        }
      }),
    },
    sources: [],
    prepared: None,
    work: None,
    work_fields: clear_collective_fields(clear_salon_fields(self.work_fields)),
    dirty: true,
    generation: self.generation + 1,
    notice: "Selected paths only. Save draft and capture sources rechecks and captures current bytes.",
  }
}
