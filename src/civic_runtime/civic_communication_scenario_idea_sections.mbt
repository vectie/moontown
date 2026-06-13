///|
fn civic_communication_output_sections(
  ideas : Array[CivicCommunicationIdea],
) -> String {
  let builder = StringBuilder::new()
  for idea in ideas {
    builder.write_string("### ")
    builder.write_string(idea.title)
    builder.write_string("\n\n")
    builder.write_string(idea.summary)
    builder.write_string("\n\n")
    builder.write_string("Participating internal workspaces: `")
    builder.write_string(idea.participating_books.join("`, `"))
    builder.write_string("`.\n\n")
    builder.write_string("Why it matters: ")
    builder.write_string(idea.why_it_matters)
    builder.write_string("\n\n")
    builder.write_string("Follow-up questions:\n")
    for question in idea.research_questions {
      builder.write_string("- ")
      builder.write_string(question)
      builder.write_char('\n')
    }
    builder.write_string("\nNext artifact/action: ")
    builder.write_string(idea.next_experiment)
    builder.write_string("\n\n")
  }
  builder.to_string().trim().to_owned()
}
