///|
fn dashboard_test_dispatch() -> Dispatch[Msg] {
  Emit(fn(_msg) { @rabbita.none })
}

///|
fn render_default_dashboard_test_html(model : Model) -> String {
  @rabbita.render_to_string(
    @rabbita.static_cell(
      render_dashboard_page(
        dashboard_test_dispatch(),
        model,
        render_scene_context(model),
      ),
    ),
  )
}

///|
fn default_dashboard_forbidden_copy() -> Array[String] {
  [
    ".json", "daemon.json", "standing-goals.json", "book-template-requests.json",
    "Live spine", "Snapshot bridge", "Switch Source", "State sources", "endpoint",
    "payload", "dispatch tick", "Inspector Inject Budget", "Inspector Relieve Queue",
    "Inspector Stability Drill", ">Pause<", ">Step<", ">Inject Budget<", ">Relieve Queue<",
    ">Stability Drill<",
  ]
}

///|
test "default dashboard hides developer and rare runtime controls" {
  let html = render_default_dashboard_test_html(init_model())
  for copy in default_dashboard_forbidden_copy() {
    if html.contains(copy) {
      fail("default dashboard contains forbidden copy: \{copy}")
    }
  }
}

///|
test "default dashboard keeps professional operating actions visible" {
  let html = render_default_dashboard_test_html(init_model())
  assert_true(html.contains("Current town pulse"))
  assert_true(html.contains("Open Wenyu Viewport"))
  assert_true(html.contains("Save Watch"))
  assert_true(html.contains("Queue PDF Watch Book"))
  assert_true(html.contains("Operating Brief"))
}
