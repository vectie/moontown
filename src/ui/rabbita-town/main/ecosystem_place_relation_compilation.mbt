///|
/// Normalize historical presentation aliases to the stable runtime resource
/// identity carried by compiled Places.
fn ecosystem_relation_resource_id(value : String) -> String {
  match value {
    "vitality-dashboard" => "vitality-tower"
    "broadcast-tower" => "story-radar"
    other => other
  }
}

///|
/// Authored civic collaboration grammar. It is compiled once into semantic
/// PlaceRelation records; Canvas and inspectors never interpret this table.
fn ecosystem_relation_target_resources(source : String) -> Array[String] {
  match ecosystem_relation_resource_id(source) {
    "town-shell" => ["policy-hall", "vitality-tower"]
    "policy-hall" => ["research-opc", "town-shell"]
    "vitality-tower" => ["town-shell", "social-square"]
    "contest-express" => ["talent-avenue", "social-square"]
    "story-radar" => ["social-square", "ai-garden"]
    "resident-twins" => ["talent-avenue", "social-square"]
    "ai-garden" => ["research-ai-agents", "social-square"]
    "social-square" => ["valley-market", "talent-avenue"]
    "research-embodied-robotics" => ["physical-bridge", "ai-garden"]
    "research-ai-agents" => ["town-shell", "ai-garden"]
    "talent-avenue" => ["resident-twins", "contest-express"]
    "valley-market" => ["social-square", "physical-bridge"]
    "physical-bridge" => ["research-embodied-robotics", "valley-market"]
    "research-opc" => ["policy-hall", "story-radar"]
    "research-llm-training" => ["research-ai-hardware", "ai-garden"]
    "research-ai-hardware" => ["research-llm-training", "physical-bridge"]
    _ => []
  }
}

///|
fn ecosystem_place_for_relation_resource(
  places : ArrayView[@energy_valley_contract.Place],
  resource_id : String,
) -> @energy_valley_contract.Place? {
  let expected = ecosystem_relation_resource_id(resource_id)
  for place in places {
    match place.runtime_binding {
      Some(binding) =>
        if ecosystem_relation_resource_id(binding.resource_id) == expected {
          return Some(place)
        }
      _ => ()
    }
  }
  None
}

///|
fn ecosystem_contract_place_relations(
  places : ArrayView[@energy_valley_contract.Place],
) -> Array[@energy_valley_contract.PlaceRelation] {
  let result : Array[@energy_valley_contract.PlaceRelation] = []
  let provenance = @energy_valley_contract.provenance(
    "moontown-civic-relation-grammar",
    "v1",
    @energy_valley_contract.Derived,
    @energy_valley_contract.Bounded,
  )
  for source in places {
    guard source.runtime_binding is Some(binding) else { continue }
    for
      target_resource in ecosystem_relation_target_resources(
        binding.resource_id,
      ) {
      match ecosystem_place_for_relation_resource(places, target_resource) {
        Some(target) if target.id != source.id =>
          result.push(
            @energy_valley_contract.place_relation(
              ecosystem_contract_scoped_id(
                "place-relation",
                "\{source.id.local_key()}--\{target.id.local_key()}",
              ),
              source.id,
              target.id,
              @energy_valley_contract.Collaboration,
              "协作",
              provenance,
            ),
          )
        _ => ()
      }
    }
  }
  result
}
