///|
test "accepted custom Place outside every parcel remains a visible rejection" {
  let source : EcosystemPlace = {
    id: ecosystem_scoped_id("place", "outside-parcel-test"),
    source_id: "player-delta",
    name: "Outside parcel test",
    kind: EcosystemCustomBuilding,
    district: "test",
    style: "custom-lab",
    footprint: { x: 20, y: 20, width: 2, depth: 2 },
    anchor: ecosystem_point(21, 21),
    traits: [],
    attention: { visual: 1, social: 1, activity: 1, urgency: 1, novelty: 1 },
    runtime: { runtime_key: None },
  }
  let snapshot : EcosystemWorldSnapshot = {
    schema: ecosystem_world_schema(),
    seed: (20260727 : Int).reinterpret_as_uint(),
    cols: 256,
    rows: 144,
    places: [source],
    entrances: [],
    road_frontages: [],
    pedestrian_spurs: [],
    roads: [],
    road_network: @energy_valley_contract.road_network([], [], []),
    affordances: [],
  }
  let id = ecosystem_contract_id(source.id)
  let accepted = @energy_valley_contract.place(
    id,
    source.name,
    @energy_valley_contract.Building,
    None,
    ecosystem_contract_footprint(source.footprint),
    [],
    [],
    [],
    Some(
      @energy_valley_contract.building_profile(
        source.style,
        2,
        8.4,
        @energy_valley_contract.Flat,
        17,
      ),
    ),
    None,
    energy_valley_world_delta_provenance(),
  )
  let rejections = ecosystem_contract_rejected_placements(snapshot, [accepted])
  assert_true(
    rejections.any(rejection => {
      rejection.candidate_id == id &&
      rejection.reason is @energy_valley_contract.OutsideParcel
    }),
  )
}
