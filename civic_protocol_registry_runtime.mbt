///|
priv struct BuildingProtocolRegistryDocument {
  generated_at : String
  description : String
  protocols : Array[@civic.BuildingProtocolDefinition]
} derive(ToJson)

///|
pub fn default_wenyu_protocol_registry_path() -> String {
  ".moontown/civic/protocols.json"
}

///|
pub fn default_wenyu_protocol_status_path() -> String {
  ".moontown/civic/protocol-status.json"
}

///|
pub async fn bootstrap_wenyu_building_protocols(
  registry_path? : String = default_wenyu_protocol_registry_path(),
  status_path? : String = default_wenyu_protocol_status_path(),
) -> String {
  let protocols = @civic.wenyu_building_protocols()
  let registry_document = BuildingProtocolRegistryDocument::{
    generated_at: "bootstrap",
    description: "Wenyu building protocol registry. Buildings are protocol places for aggregation, exchange, AI-guided reduction, review, and distribution.",
    protocols,
  }
  write_text_file(
    registry_path,
    registry_document.to_json().stringify(indent=2),
  )
  for protocol in protocols {
    write_text_file_if_missing(
      protocol_contract_path(protocol.building_id),
      building_protocol_markdown(protocol),
    )
  }
  match @civic.wenyu_building_protocol_for_building_id("social-square") {
    Some(protocol) => seed_social_square_protocol_slice(protocol)
    None => ()
  }
  ignore(write_wenyu_building_protocol_status(status_path~, registry_path~))
  "Bootstrapped \{protocols.length()} Wenyu building protocol definition(s), including a Social Square inbox/reduction/outbox proof slice."
}
