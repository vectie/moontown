///|
fn miniapp_publishing_building_by_id(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
) -> @miniapp_contracts.MiniappBuilding? {
  for building in snapshot.buildings {
    if building.id == building_id {
      return Some(building)
    }
  }
  None
}

///|
fn miniapp_publishing_book_by_id(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  book_id : String,
) -> @miniapp_contracts.MiniappBookSummary? {
  for book in snapshot.books {
    if book.id == book_id {
      return Some(book)
    }
  }
  None
}

///|
fn miniapp_publishing_replace_building(
  buildings : Array[@miniapp_contracts.MiniappBuilding],
  next : @miniapp_contracts.MiniappBuilding,
) -> Array[@miniapp_contracts.MiniappBuilding] {
  buildings.map(building => if building.id == next.id { next } else { building })
}

///|
fn miniapp_contains_banned_term(
  text : String,
  banned_terms : Array[String],
) -> Bool {
  let lowered = text.to_lower()
  for term in banned_terms {
    if lowered.contains(term.to_lower()) {
      return true
    }
  }
  false
}

///|
fn miniapp_has_duplicate_strings(items : Array[String]) -> Bool {
  for i in 0..<items.length() {
    for j in (i + 1)..<items.length() {
      if items[i] == items[j] {
        return true
      }
    }
  }
  false
}

///|
fn miniapp_array_contains_text(items : Array[String], needle : String) -> Bool {
  let lowered = needle.to_lower()
  for item in items {
    if item.to_lower().contains(lowered) {
      return true
    }
  }
  false
}

///|
fn miniapp_text_score(text : String, query : String, weight : Int) -> Int {
  let needle = query.trim().to_owned().to_lower()
  if needle != "" && text.to_lower().contains(needle) {
    weight
  } else {
    0
  }
}

///|
fn miniapp_optional_tag_match(tag : String?, tags : Array[String]) -> Bool {
  match tag {
    Some(value) => tags.contains(value)
    None => true
  }
}

///|
fn miniapp_optional_category_match(
  category_id : String?,
  kind : @miniapp_contracts.MiniappBuildingKind,
) -> Bool {
  match category_id {
    Some(value) => value == miniapp_building_category_id(kind)
    None => true
  }
}

///|
fn miniapp_optional_owner_match(owner_id : String?, actual : String) -> Bool {
  match owner_id {
    Some(value) => value == actual
    None => true
  }
}

///|
fn miniapp_optional_capability_match(
  capability : String?,
  capabilities : Array[String],
) -> Bool {
  match capability {
    Some(value) => capabilities.contains(value)
    None => true
  }
}

///|
fn miniapp_optional_freshness_match(
  min_updated_at_ms : UInt64?,
  actual : UInt64,
) -> Bool {
  match min_updated_at_ms {
    Some(value) => actual >= value
    None => true
  }
}

///|
fn miniapp_safe_preview_summary(summary : String) -> String {
  if summary.contains("/Users/") ||
    summary.contains(".moontown/") ||
    summary.contains("file://") {
    "Public preview withheld pending review."
  } else {
    summary
  }
}

///|
fn miniapp_sort_public_previews(
  input : Array[MiniappPublicBuildingPreview],
) -> Array[MiniappPublicBuildingPreview] {
  let output = input.copy()
  for i in 0..<output.length() {
    for j in (i + 1)..<output.length() {
      if output[j].score > output[i].score ||
        (
          output[j].score == output[i].score &&
          output[j].title < output[i].title
        ) {
        let tmp = output[i]
        output[i] = output[j]
        output[j] = tmp
      }
    }
  }
  output
}
