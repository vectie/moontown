# Contest Express programs

A program grows a Mayor's civic challenge into a competition with tracks,
registration and submission windows, an evaluator roster, and editorial pages.
Save a draft with `save-program`, check `program_readiness`, and publish it with
`publish-program`. Published amendments retain the current lifecycle and create
history receipts. Finalization freezes the competition contract and scores.
The Mayor can continue publishing champion stories through announcements.

```mbt check
///|
test "program lookup and migration" {
  let state = @hackathon.decode_hackathon_state(
    @hackathon.empty_hackathon_state().to_json(),
  )
  assert_eq(@hackathon.program_readiness(state, "river-ai"), [
    "Save a competition program",
  ])
  assert_true(@hackathon.competition_program(state, "river-ai") is None)
  @hackathon.require_unfrozen_program(state, "river-ai")
  assert_true(
    @hackathon.apply_program_action(state, "other-action", {}, 1UL) is None,
  )
}
```

Metric tracks declare a registered runner key, measured quantities with `min`
or `max` direction and baseline weights, and optional qualification gates.
Rubric tracks use the existing challenge rubric and human review receipts.
Drafts can omit editorial fields while the preview lists what publication needs.
