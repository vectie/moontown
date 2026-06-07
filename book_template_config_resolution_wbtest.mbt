///|
async test "book template config relative path resolver handles absolute and relative paths" {
  assert_eq(
    resolve_book_template_config_relative_path("/tmp/configs", "method.md"),
    "/tmp/configs/method.md",
  )
  assert_eq(
    resolve_book_template_config_relative_path("/tmp/configs", "/var/method.md"),
    "/var/method.md",
  )
  assert_eq(
    resolve_book_template_config_relative_path(".", "method.md"),
    "method.md",
  )
  assert_eq(
    resolve_book_template_config_relative_path("", "method.md"),
    "method.md",
  )
}

///|
async test "book template config text override prefers inline then file then empty" {
  let root = "/tmp/moontown-book-template-config-resolution-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  write_text_file("\{root}/method.md", "# Method From File")
  assert_eq(
    resolve_book_template_config_text_override(
      "# Inline Method", "method.md", root,
    ),
    "# Inline Method",
  )
  assert_eq(
    resolve_book_template_config_text_override("", "method.md", root),
    "# Method From File",
  )
  assert_eq(resolve_book_template_config_text_override("", "", root), "")
}

///|
test "book template config workspace root resolver preserves default and resolves relative override" {
  assert_eq(
    resolve_book_template_config_workspace_root(
      "/tmp/configs", "", "/tmp/default-workspace",
    ),
    "/tmp/default-workspace",
  )
  assert_eq(
    resolve_book_template_config_workspace_root(
      "/tmp/configs", "workspace", "/tmp/default-workspace",
    ),
    "/tmp/configs/workspace",
  )
  assert_eq(
    resolve_book_template_config_workspace_root(
      "/tmp/configs", "/tmp/absolute-workspace", "/tmp/default-workspace",
    ),
    "/tmp/absolute-workspace",
  )
}
