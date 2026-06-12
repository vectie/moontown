///|
pub async fn save_packet_file(
  path : String,
  packet : ExternalProposalPacket,
) -> Unit {
  moonclaw_write_text_file(path, packet.to_json().stringify())
}

///|
pub async fn load_packet_file(path : String) -> ExternalProposalPacket? {
  let parsed = match moonclaw_read_optional_json_file(path) {
    Some(json) => json
    None => return None
  }
  Some(@json.from_json(parsed) catch { _ => return None })
}
