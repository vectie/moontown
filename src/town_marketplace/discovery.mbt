///|
fn json_card_string(card : Json, key : String) -> String {
  guard card is Object(fields) else { return "" }
  match fields.get(key) {
    Some(String(value)) => value
    _ => ""
  }
}

///|
fn json_card_strings(card : Json, key : String) -> Array[String] {
  guard card is Object(fields) else { return [] }
  match fields.get(key) {
    Some(Array(values)) =>
      values.filter_map(value => {
        match value {
          String(text) => Some(text)
          _ => None
        }
      })
    _ => []
  }
}

///|
fn json_card_int(card : Json, key : String) -> Int {
  guard card is Object(fields) else { return 0 }
  match fields.get(key) {
    Some(Number(value, ..)) => value.to_int()
    _ => 0
  }
}

///|
fn query_terms(query : String) -> Array[String] {
  normalized_terms(
    query
    .to_lower()
    .split(" ")
    .map(part => part.trim(chars=",.;:!?()[]{}\"").to_owned())
    .to_array(),
  )
}

///|
fn organic_listing_score(card : Json, terms : Array[String]) -> Int {
  let title = json_card_string(card, "title").to_lower()
  let summary = json_card_string(card, "summary").to_lower()
  let capabilities = json_card_strings(card, "capabilities")
  let tags = json_card_strings(card, "tags")
  if terms.is_empty() {
    return 10 + json_card_int(card, "quality_score") / 10
  }
  let mut score = 0
  for term in terms {
    if title.contains(term) {
      score += 40
    }
    if summary.contains(term) {
      score += 20
    }
    if capabilities.any(value => value.to_lower().contains(term)) {
      score += 15
    }
    if tags.any(value => value.to_lower().contains(term)) {
      score += 10
    }
  }
  score
}

///|
/// Organic search is deterministic and contains no sponsored placements.
pub fn marketplace_organic_search(
  state : MarketplaceState,
  query : String,
) -> Array[Json] {
  let terms = query_terms(query)
  let results : Array[Json] = []
  for card in public_listing_cards(state) {
    let score = organic_listing_score(card, terms)
    if score > 0 {
      results.push({
        "listing": card,
        "organic_score": score,
        "reason": if terms.is_empty() {
          "Published and quality-ranked"
        } else {
          "Matched your explicit search terms"
        },
      })
    }
  }
  results.sort_by(fn(left, right) {
    let score_order = json_card_int(right, "organic_score") -
      json_card_int(left, "organic_score")
    if score_order != 0 {
      score_order
    } else {
      let left_id = match left {
        Object(fields) =>
          fields
          .get("listing")
          .map(card => json_card_string(card, "listing_id"))
          .unwrap_or("")
        _ => ""
      }
      let right_id = match right {
        Object(fields) =>
          fields
          .get("listing")
          .map(card => json_card_string(card, "listing_id"))
          .unwrap_or("")
        _ => ""
      }
      left_id.compare(right_id)
    }
  })
  results
}

///|
fn recommendation_for_card(
  principal : MarketplacePrincipal,
  card : Json,
) -> Recommendation {
  let tags = json_card_strings(card, "tags")
  let capabilities = json_card_strings(card, "capabilities")
  let matches : Array[String] = []
  for interest in principal.interest_tags {
    if tags.contains(interest) || capabilities.contains(interest) {
      matches.push(interest)
    }
  }
  let quality = json_card_int(card, "quality_score")
  let reliability = json_card_int(card, "reliability_score")
  let score = 10 + matches.length() * 25 + quality / 5 + reliability / 10
  let reason = if matches.is_empty() {
    "Recommended for verified public quality and reliability"
  } else {
    "Recommended because your interests include \{matches.join(", ")}"
  }
  { listing: card, score, reason }
}

///|
/// Recommendations are deterministic and explain every score-driving match.
pub fn marketplace_recommendations(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
) -> Array[Recommendation] {
  let recommendations = public_listing_cards(state).map(card => {
    recommendation_for_card(principal, card)
  })
  recommendations.sort_by(fn(left, right) {
    if left.score != right.score {
      right.score - left.score
    } else {
      json_card_string(left.listing, "listing_id").compare(
        json_card_string(right.listing, "listing_id"),
      )
    }
  })
  recommendations
}

///|
pub fn marketplace_active_sponsored(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  now_ms : UInt64,
) -> Array[Json] {
  let placements : Array[Json] = []
  for sponsored in state.sponsored_placements {
    if sponsored.active &&
      sponsored.starts_at_ms <= now_ms &&
      sponsored.ends_at_ms > now_ms {
      let interest_match = sponsored.interest_tags.is_empty() ||
        sponsored.interest_tags.any(tag => principal.interest_tags.contains(tag))
      if interest_match {
        match
          public_listing_by_ref(
            state,
            sponsored.listing_kind,
            sponsored.listing_id,
          ) {
          Some(listing) =>
            placements.push({
              "contract_id": "moontown.sponsored-placement.v1",
              "placement_id": sponsored.placement_id,
              "label": "Sponsored",
              "why_shown": sponsored.why_shown,
              "listing": listing,
            })
          None => ()
        }
      }
    }
  }
  placements
}

///| Feed lanes stay structurally separate so advertisements cannot silently

///|
/// change organic rank or recommendation explanations.
pub fn marketplace_discovery_feed(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  query : String,
  now_ms : UInt64,
) -> Json {
  {
    "contract_id": "moontown.discovery-feed.v1",
    "organic_results": marketplace_organic_search(state, query).to_json(),
    "recommendations": marketplace_recommendations(state, principal).to_json(),
    "sponsored_placements": marketplace_active_sponsored(
      state, principal, now_ms,
    ).to_json(),
    "policy": {
      "organic_and_sponsored_separated": true,
      "recommendations_explainable": true,
    },
  }
}
