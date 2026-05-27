///|
fn building_protocol_markdown(
  protocol : @civic.BuildingProtocolDefinition,
) -> String {
  [
    "# \{protocol.title} Building Protocol",
    "",
    protocol.social_responsibility,
    "",
    "## Protocol",
    "",
    "- Building: `\{protocol.building_id}`",
    "- Mode: `\{protocol.protocol_mode}`",
    "- Book: `\{protocol.book_id}`",
    "- MoonBook role: `\{protocol.moonbook_role}`",
    "- Projection contract: `\{protocol.projection_contract}`",
    "",
    "## Input Channels",
    "",
    protocol_markdown_bullets(protocol.input_channels),
    "",
    "## Output Channels",
    "",
    protocol_markdown_bullets(protocol.output_channels),
    "",
    "## Review Gates",
    "",
    protocol_markdown_bullets(protocol.review_gates),
    "",
    "## AI Reducer Boundary",
    "",
    "- Moontown owns the envelope, channels, ledgers, idempotency, and review gates.",
    "- MoonClaw chooses the building-native reduction strategy through the skill packs.",
    "- MoonBook persists accepted civic records and review queues.",
  ].join("\n")
}

///|
fn protocol_markdown_bullets(items : Array[String]) -> String {
  let builder = StringBuilder::new()
  for item in items {
    builder.write_string("- \{item}\n")
  }
  builder.to_string().trim().to_owned()
}

///|
fn protocol_one_line(text : String) -> String {
  text.replace(old="\n", new=" ").trim().to_owned()
}
