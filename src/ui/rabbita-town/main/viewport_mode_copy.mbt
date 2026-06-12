///|
fn viewport_mode_label(mode : ViewportMode) -> String {
  match mode {
    ViewMode => "View Mode"
    EditorMode => "Editor Mode"
    OutputMode => "Final Output"
  }
}

///|
fn viewport_mode_slug(mode : ViewportMode) -> String {
  match mode {
    ViewMode => "view"
    EditorMode => "editor"
    OutputMode => "output"
  }
}

///|
fn viewport_mode_summary(mode : ViewportMode) -> String {
  match mode {
    ViewMode =>
      "Clean town presentation. Click buildings to inspect live module interiors."
    EditorMode =>
      "Designer workspace. Validate module placement, runtime bindings, and output coverage without changing MoonBook state."
    OutputMode =>
      "Final retrieval surface. Browse generated MoonBook websites, reports, reviews, and page families from one place."
  }
}
