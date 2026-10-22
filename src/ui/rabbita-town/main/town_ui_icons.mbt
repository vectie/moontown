///|
/// Small, single-stroke UI glyphs. The enclosing control owns its name/state.
/// Keep navigation labels visible; only conventional utility controls go icon-only.
fn town_ui_icon(name : String) -> @rabbita.Html {
  let path = match name {
    "close" => "M6 6l12 12M18 6L6 18"
    "back" => "M15 5l-7 7 7 7M8 12h13"
    "work" => "M8 6V4h8v2M3 7h18v13H3zM3 12h18M10 12v3h4v-3"
    "book" =>
      "M12 5v16M12 5C8 2 4 3 2 4v15c4-1 7-1 10 2 3-3 6-3 10-2V4c-2-1-6-2-10 1"
    "people" =>
      "M9 3a4 4 0 1 0 0 8 4 4 0 0 0 0-8M2 21v-3a7 7 0 0 1 14 0v3M17 4a4 4 0 0 1 0 8M19 15c2 1 3 3 3 6"
    "chat" => "M4 3h16a1 1 0 0 1 1 1v13H8l-5 4V4a1 1 0 0 1 1-1M7 8h10M7 12h7"
    "server" => "M3 3h18v7H3zM3 14h18v7H3zM6 6h1M6 17h1M11 6h7M11 17h7"
    "clock" => "M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20M12 6v6l4 2"
    "sliders" =>
      "M4 3v6m0 6v6M12 3v12m0 4v2M20 3v2m0 6v10M1 9h6v6H1zM9 15h6v4H9zM17 5h6v6h-6z"
    "menu" => "M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z"
    "download" => "M12 3v12m-5-5 5 5 5-5M4 15v6h16v-6"
    "train" =>
      "M6 3h12l2 2v13H4V5zM4 12h16M9 3v9m6-9v9M7 16h1m8 0h1M7 18l-3 4m13-4 3 4"
    "chart" => "M3 3v18h19M7 17v-5m5 5V7m5 10V3"
    "help" =>
      "M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20M9 9a3 3 0 1 1 5 2c-2 1-2 2-2 3m0 3h.01"
    "reset" => "M3 9a9 9 0 1 1 0 7M3 3v6h6"
    "pin" =>
      "M12 22S4 14 4 9a8 8 0 1 1 16 0c0 5-8 13-8 13M12 6a3 3 0 1 0 0 6 3 3 0 0 0 0-6"
    "road" => "M8 2L3 22M16 2l5 20M12 3v3m0 4v4m0 4v3"
    "tree" => "M12 2l-6 8h3l-6 7h18l-6-7h3zM12 17v5"
    "building" =>
      "M5 22V3h14v19M2 22h20M9 7h1m4 0h1M9 11h1m4 0h1M9 15h1m4 0h1M10 22v-4h4v4"
    "inspect" => "M10 2a8 8 0 1 0 0 16 8 8 0 0 0 0-16M16 16l6 6"
    "plus" => "M12 3v18M3 12h18"
    "trash" => "M3 6h18M8 6V3h8v3M5 6l1 15h12l1-15M10 10v7m4-7v7"
    _ => "M4 4h16v16H4zM8 8h8M8 12h8M8 16h5"
  }
  span(class="town-ui-icon", attrs=@html.Attrs::build().aria_hidden("true"), [
    @svg.svg(width=20, height=20, view_box="0 0 24 24", [
      @svg.path(
        d=path,
        fill="none",
        stroke="currentColor",
        attrs=@svg.Attrs::build()
          .stroke_width("1.7")
          .stroke_linecap("round")
          .stroke_linejoin("round"),
      ),
    ]),
  ])
}

///|
fn town_ui_label(icon : String, label : String) -> @rabbita.Html {
  span(class="town-ui-label", [town_ui_icon(icon), span(label)])
}

///|
fn town_tool_icon(icon : String) -> @rabbita.Html {
  town_ui_icon(
    match icon {
      "巡" => "inspect"
      "路" => "road"
      "绿" => "tree"
      "拆" => "trash"
      _ => "building"
    },
  )
}
