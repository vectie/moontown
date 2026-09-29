///|
test "interior remains separate and exposes reference provenance" {
  guard @models.interior_study()
    is {
      "study": { "id": String(id), "parts": Array(parts), .. },
      "zones": Array(zones),
      "subdivisions": Array(subs),
      ..
    } else {
    fail("missing interior model")
  }
  assert_eq(id, "interior-g3")
  assert_eq(zones.length(), 14)
  assert_eq(subs.length(), 2)
  assert_true(parts.length() > 2000)
  for zone in zones {
    guard zone
      is { "evidence": String(evidence), "proposal": String(proposal), .. } else {
      fail("missing fidelity boundary")
    }
    assert_true(!evidence.is_empty())
    assert_true(proposal.length() > 5)
  }
}
