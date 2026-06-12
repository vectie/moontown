///|
pub fn render_civic_communication_patterns() -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Civic Communication Patterns\n\n")
  builder.write_string("| Pattern | Category | Protocol mode | Good for |\n")
  builder.write_string("| --- | --- | --- | --- |\n")
  for pattern in @civic.civic_communication_patterns() {
    builder.write_string(
      "|\{pattern.title}|\{pattern.category}|\{pattern.protocol_mode}|\{pattern.good_for.join(", ")}|\n",
    )
  }
  builder.to_string()
}
