///|
fn ranked_fixture() -> State raise {
  let config = builtin_config()
  let mut state = advance_voting(voting_works(), config, 1100UL)
  for
    (i, creator) in [
      "creator-a", "creator-a", "creator-a", "creator-b", "creator-b", "creator-c",
    ].mapi((i, name) => (i, name)) {
    state = vote_for(state, "voter-\{i}", work_id(state, creator), "choice")
  }
  advance_voting(state, config, 1200UL)
}

///|
test "builtin awards use the sealed vote order and cannot be manually assigned" {
  let config = builtin_config()
  let state = ranked_fixture()
  assert_true(
    try {
      ignore(transition(state, config, "award", {}, 1300UL, "host", true))
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  let published = transition(
    state,
    config,
    "publish-results",
    {},
    1300UL,
    "host",
    true,
  )
  assert_true(published.results_published)
  assert_eq(published.awards.map(award => award.entry_id), [
    work_id(state, "creator-a"),
    work_id(state, "creator-b"),
    work_id(state, "creator-c"),
  ])
  assert_eq(published.awards.map(award => award.prize), [
    "creative", "popular", "coffee",
  ])
  assert_eq(
    Json::array(published.vote_events.map(event => event.to_json())),
    Json::array(state.vote_events.map(event => event.to_json())),
  )
  assert_eq(
    Json::array(published.voting_settlements.map(value => value.to_json())),
    Json::array(state.voting_settlements.map(value => value.to_json())),
  )
  assert_true(
    try {
      ignore(
        transition(state, config, "publish-results", {}, 1299UL, "host", true),
      )
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  assert_true(
    try {
      ignore(
        transition(
          state,
          config,
          "publish-results",
          {},
          1300UL,
          "stranger",
          false,
        ),
      )
      false
    } catch {
      Denied => true
      _ => false
    },
  )
}

///|
test "ties and missing votes never select arbitrary prize recipients" {
  let config = builtin_config()
  let mut tied = advance_voting(voting_works(), config, 1100UL)
  for creator in ["creator-a", "creator-b", "creator-c"] {
    tied = vote_for(tied, "voter-" + creator, work_id(tied, creator), "choice")
  }
  tied = advance_voting(tied, config, 1200UL)
  assert_true(
    try {
      ignore(ranked_awards(tied, "host", 1300UL))
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  let no_votes = advance_voting(voting_works(), config, 1200UL)
  assert_true(
    try {
      ignore(ranked_awards(no_votes, "host", 1300UL))
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
}

///|
test "withdrawing a sealed winner blocks publication instead of promoting another work" {
  let config = builtin_config()
  let state = ranked_fixture()
  let withdrawn = transition(
    state,
    config,
    "withdraw",
    { "entry_id": work_id(state, "creator-a") },
    1250UL,
    "creator-a",
    false,
  )
  assert_true(
    try {
      ignore(ranked_awards(withdrawn, "host", 1300UL))
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
}
