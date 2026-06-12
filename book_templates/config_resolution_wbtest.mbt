///|
fn resolve_book_template_config_relative_path(
  base_dir : String,
  path : String,
) -> String {
  if path.has_prefix("/") || base_dir == "." || base_dir == "" {
    path
  } else {
    "\{base_dir}/\{path}"
  }
}

///|
async fn resolve_book_template_config_text_override(
  inline_text : String,
  path : String,
  base_dir : String,
) -> String {
  if !inline_text.trim().is_empty() {
    return inline_text
  }
  if path.trim().is_empty() {
    return ""
  }
  read_text_or_empty(resolve_book_template_config_relative_path(base_dir, path))
}

///|
fn resolve_book_template_config_workspace_root(
  base_dir : String,
  configured_workspace_root : String,
  default_workspace_root : String,
) -> String {
  if configured_workspace_root.trim().is_empty() {
    default_workspace_root
  } else {
    resolve_book_template_config_relative_path(
      base_dir, configured_workspace_root,
    )
  }
}

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
