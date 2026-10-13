# Contest Express participation

A competition team registers its captain and selected track. The captain invites
other residents; each invitation must be accepted by its intended recipient.
Submission packages preserve the material URLs, SHA-256 hashes, and benchmark
version at submission. Each later evaluation records the benchmark used for that
review, allowing existing submissions to be evaluated after a Mayor amendment.
Daily submission limits use UTC calendar days.

The action dispatcher returns `None` for an action belonging to another desk.

```mbt check
///|
test {
  let state = @hackathon.empty_hackathon_state()
  assert_true(
    @hackathon.apply_participation_action(state, "announce", {}, 100UL) is None,
  )
}
```

Structured registration requires an open Program and its registration window.

```mbt check
///|
test {
  try
    @hackathon.apply_participation_action(
      @hackathon.empty_hackathon_state(),
      "register-competition-team",
      {
        "team": {
          "id": "river-team",
          "challenge_id": "river-ai",
          "name": "River team",
          "members": ["captain"],
        },
        "profile": {
          "team_id": "river-team",
          "captain_id": "captain",
          "affiliation": "Residents",
          "track_id": "map",
        },
      },
      100UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("registration must have a configured competition")
  }
}
```
