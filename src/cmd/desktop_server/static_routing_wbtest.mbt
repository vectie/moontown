///|
test "desktop server serves canonical and legacy town entries from one artifact" {
  assert_eq(static_relative_path("/"), "index.html")
  assert_eq(static_relative_path("/index.html"), "index.html")
  assert_eq(static_relative_path("/viewport.html"), "index.html")
}

///|
test "desktop server leaves non-entry static paths unchanged" {
  assert_eq(static_relative_path("/styles.css"), "styles.css")
  assert_eq(
    static_relative_path("/tilemap/maps/wenyu-valley.json"),
    "tilemap/maps/wenyu-valley.json",
  )
}
