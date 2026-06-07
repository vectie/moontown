///|
async fn write_civic_projection(
  root : String,
  service : @civic.CivicServiceDefinition,
) -> Unit {
  write_text_file(
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
  write_text_file("\{root}/book/Home.html", html)
  write_text_file("\{root}/book/site/generated/index.html", html)
}
