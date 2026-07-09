///|
fn render_dashboard_ecosystem_preview() -> @rabbita.Html {
  section(class="town-ecosystem-preview", [
    div(class="town-ecosystem-preview-copy", [
      p(class="eyebrow", "Wenyu Map"),
      h2("Ecosystem"),
      div(class="town-ecosystem-preview-chips", [
        span(class="town-ecosystem-preview-chip", "Districts"),
        span(class="town-ecosystem-preview-chip", "Residents"),
        span(class="town-ecosystem-preview-chip", "Services"),
        span(class="town-ecosystem-preview-chip", "Signals"),
      ]),
    ]),
    div(class="town-ecosystem-preview-visual", [
      img(
        class="town-ecosystem-preview-image",
        src="tilemap/wenyu_reference_tilemap_iso.png",
        alt="Wenyu Valley rendered town map",
        loading="lazy",
      ),
    ]),
  ])
}
