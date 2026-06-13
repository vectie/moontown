///|
async fn planbook_moonbook_provider_criterion() -> PlanbookCriterionStatus {
  let ready = @fs.exists("../moonbook/seed/wiki/skills/code-plan/SKILL.md") ||
    @fs.exists("../moonbook/seed/wiki/skills/planbook/SKILL.md")
  planbook_criterion(
    "moonbook-native-planbook-provider",
    "2026-05-29-book-quality-upgrade",
    "MoonBook has a native planbook provider/profile",
    "moonbook",
    ready,
    if ready {
      "MoonBook exposes a native planbook/code-plan seed skill"
    } else {
      "MoonBook still needs the native planbook provider/profile"
    },
    "implement this in MoonBook, not by copying MoonBook projection internals into Moontown",
  )
}

///|
async fn planbook_app_tool_book_template_criterion() -> PlanbookCriterionStatus {
  let registry_ready = text_file_contains(
    @book_templates.default_registry_path(),
    "\"template_id\": \"app-tool-book\"",
  )
  let installer_ready = text_file_contains(
      "src/book_templates/installers.mbt", "\"app-tool-book\"",
    ) &&
    text_file_contains(
      "src/book_templates/installers.mbt", "install_app_tool_book_config",
    )
  let template_ready = @fs.exists(
      "assets/templates/books/app-tool-book/book.json",
    ) &&
    @fs.exists("assets/templates/books/app-tool-book/tool-spec.example.md") &&
    @fs.exists(
      "assets/templates/books/app-tool-book/skills/tool-build/SKILL.md",
    ) &&
    @fs.exists(
      "assets/templates/books/app-tool-book/schemas/tool-manifest.schema.md",
    )
  let runtime_ready = @fs.exists("src/app_tool_book/runtime.mbt") &&
    text_file_contains("src/app_tool_book/contracts.mbt", "tool-manifest.json") &&
    text_file_contains(
      "src/app_tool_book/contracts.mbt", "book/site/generated/tool.html",
    ) &&
    text_file_contains(
      "src/app_tool_book/workspace_runtime.mbt", "book/site/generated/tool.html",
    ) &&
    text_file_contains("src/app_tool_book/runtime.mbt", "civic_building_id")
  let ready = registry_ready &&
    installer_ready &&
    template_ready &&
    runtime_ready
  planbook_criterion(
    "app-tool-book-template",
    "2026-06-02-app-tool-book-roadmap",
    "Moontown can generate durable App ToolBooks through the template request pipeline",
    "moontown+moonbook+moondesk+moonclaw",
    ready,
    if ready {
      "App ToolBook registry, installer, template files, tool manifest, generated tool route, and civic building binding are present"
    } else {
      "App ToolBook support is incomplete; ToolBooks would still require Codex/manual workspace creation"
    },
    "add an `app-tool-book` template with manifest, generated tool route, Moondesk-editable spec, MoonClaw skills, and generic template-request installer support",
  )
}
