///|
pub fn wenyu_building_protocols() -> Array[BuildingProtocolDefinition] {
  wenyu_civic_services().map(wenyu_building_protocol_for_service)
}

///|
pub fn wenyu_building_protocol_for_service(
  service : CivicServiceDefinition,
) -> BuildingProtocolDefinition {
  {
    building_id: service.id,
    service_id: service.id,
    title: service.title,
    book_id: service.book_id,
    protocol_mode: protocol_mode_for_service(service),
    persistence_mode: service.persistence_mode,
    social_responsibility: social_responsibility_for_service(service),
    participant_roles: participant_roles_for_service(service),
    input_channels: input_channels_for_service(service),
    output_channels: output_channels_for_service(service),
    aggregation_policy: aggregation_policy_for_service(service),
    exchange_policy: exchange_policy_for_service(service),
    reduction_policy: reduction_policy_for_service(service),
    distribution_policy: distribution_policy_for_service(service),
    review_gates: review_gates_for_service(service),
    privacy_scope: privacy_scope_for_service(service),
    moonbook_role: service.book_role,
    skill_packs: ["wenyu-civic-service", service.skill_pack],
    projection_contract: service.output_contract,
  }
}

///|
pub fn wenyu_building_protocol_for_building_id(
  building_id : String,
) -> BuildingProtocolDefinition? {
  let key = civic_binding_key(building_id)
  for protocol in wenyu_building_protocols() {
    if civic_binding_key(protocol.building_id) == key {
      return Some(protocol)
    }
  }
  None
}

///|
pub fn wenyu_building_protocol_for_book_id(
  book_id : String,
) -> BuildingProtocolDefinition? {
  match wenyu_civic_service_for_book_id(book_id) {
    Some(service) => Some(wenyu_building_protocol_for_service(service))
    None => None
  }
}
