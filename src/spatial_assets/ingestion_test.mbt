///|
fn fixture() -> String raise {
  @fs.read_file_to_string(
    "src/spatial_assets/testdata/presentation.portable.json",
  )
}

///|
fn accepted(text : String) -> TownPresentationAsset raise {
  match
    ingest_moonmold_presentation(
      text,
      building_id="building-habitat",
      placement_id="placement-habitat-plaza",
      expected_engineering_digest="sha256:29ba21e38344f5e9cfcb47953c19b9a8e9023995fbba8951a9a5972e8f069c06",
    ) {
    Ok(value) => value
    Err(problem) => fail("unexpected rejection: \{problem.code}")
  }
}

///|
test "MoonTown accepts presentation and preserves building versus placement" {
  let asset = accepted(fixture())
  assert_eq(asset.building_id, "building-habitat")
  assert_eq(asset.placement_id, "placement-habitat-plaza")
  assert_true(asset.building_id != asset.placement_id)
  assert_eq(
    asset.engineering_parent_id,
    "arched-lunar-habitat:engineering-model",
  )
  assert_true(asset.declared_losses.length() == 2)
}

///|
test "MoonTown rejects engineering, manufacturing, stale and physical claims" {
  let base = fixture()
  let engineering_lane = base
    .replace(
      old="\"representation\":\"visual-styled-model\"",
      new="\"representation\":\"engineering-model\"",
    )
    .replace(
      old="\"child_representation\":\"visual-styled-model\"",
      new="\"child_representation\":\"engineering-model\"",
    )
  let manufacturing_lane = base
    .replace(
      old="\"representation\":\"visual-styled-model\"",
      new="\"representation\":\"manufacturing-candidate\"",
    )
    .replace(
      old="\"child_representation\":\"visual-styled-model\"",
      new="\"child_representation\":\"manufacturing-candidate\"",
    )
  let cases = [
    (engineering_lane, "wrong-representation-lane"),
    (manufacturing_lane, "wrong-representation-lane"),
    (
      base.replace(old="digital-artifact", new="physical-effect-claim"),
      "claim-ceiling-exceeded",
    ),
  ]
  for item in cases {
    let (candidate, expected) = item
    match
      ingest_moonmold_presentation(
        candidate,
        building_id="building-habitat",
        placement_id="placement-habitat-plaza",
        expected_engineering_digest="sha256:29ba21e38344f5e9cfcb47953c19b9a8e9023995fbba8951a9a5972e8f069c06",
      ) {
      Err(problem) => assert_eq(problem.code, expected)
      Ok(_) => fail("expected rejection")
    }
  }
  match
    ingest_moonmold_presentation(
      base,
      building_id="building-habitat",
      placement_id="placement-habitat-plaza",
      expected_engineering_digest="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    ) {
    Err(problem) => assert_eq(problem.code, "stale-engineering-parent")
    Ok(_) => fail("expected stale rejection")
  }
}

///|
test "MoonTown rejects loss stripping and identity conflation" {
  let no_losses = fixture().replace(
    old="\"declared_losses\":[\"engineering material fidelity\",\"collision fidelity\"]",
    new="\"declared_losses\":[]",
  )
  match
    ingest_moonmold_presentation(
      no_losses,
      building_id="building-habitat",
      placement_id="placement-habitat-plaza",
      expected_engineering_digest="sha256:29ba21e38344f5e9cfcb47953c19b9a8e9023995fbba8951a9a5972e8f069c06",
    ) {
    Err(problem) => assert_eq(problem.code, "undeclared-style-loss")
    Ok(_) => fail("expected loss rejection")
  }
  match
    ingest_moonmold_presentation(
      fixture(),
      building_id="same-id",
      placement_id="same-id",
      expected_engineering_digest="sha256:29ba21e38344f5e9cfcb47953c19b9a8e9023995fbba8951a9a5972e8f069c06",
    ) {
    Err(problem) => assert_eq(problem.code, "conflated-town-identity")
    Ok(_) => fail("expected identity rejection")
  }
}
