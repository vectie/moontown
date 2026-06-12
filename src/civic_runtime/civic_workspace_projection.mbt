///|
async fn write_civic_projection(
  root : String,
  service : @civic.CivicServiceDefinition,
) -> Unit {
  @support.write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    civic_projection_state(service).to_json().stringify(indent=2),
  )
}

///|
async fn write_civic_html_pages(
  root : String,
  service : @civic.CivicServiceDefinition,
) -> Unit {
  let html = civic_generated_site_html(service)
  @support.write_text_file("\{root}/book/Home.html", html)
  @support.write_text_file(
    @civic.civic_generated_site_workspace_path(root),
    html,
  )
}
