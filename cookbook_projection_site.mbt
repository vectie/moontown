///|
fn cookbook_generated_site_html(
  entry : @moonbook.BookCatalogEntry,
  manifest : MoontownCookbookManifest,
) -> String {
  let cards : Array[String] = []
  for artifact in manifest.artifacts {
    cards.push(cookbook_artifact_card_html(artifact))
  }
  [
    "<!doctype html>",
    "<html><head><meta charset=\"utf-8\"><title>Moontown Cookbook</title>",
    cookbook_site_style_html(),
    "</head><body><main>",
    "<p>MoonBook generated / Moondesk managed / Moontown consumed</p>",
    "<h1>Moontown Stable-State Cookbook</h1>",
    "<p>The cookbook is now the Moontown describer: it explains each feature by product role, internal protocol, AI behavior, durable owner, and evidence flow.</p>",
    "<p>Workspace <code>\{html_escape(entry.workspace_root)}</code>; manifest <code>\{html_escape(manifest.manifest_path)}</code>.</p>",
    "<section>",
    "<h2>Describer Pages</h2>",
    "<div class=\"grid\">",
    cookbook_describer_card_html(
      "Overview", "wiki/describer/overview.md", "The cookbook contract for explaining Moontown as a live document/protocol machine.",
    ),
    cookbook_describer_card_html(
      "Feature Guide", "wiki/describer/feature-guide.md", "Feature-by-feature internals for the Mayor, books, workers, civic buildings, live autonomy, PlanBook, and cookbook.",
    ),
    cookbook_describer_card_html(
      "Content Rules", "wiki/describer/content-rules.md", "How docs, definitions, runtime state, civic protocols, AI work, and procedures should be described differently.",
    ),
    "</div>",
    "</section>",
    "<section>",
    "<h2>Stable-State Artifacts</h2>",
    "<section class=\"grid\">",
    cards.join("\n"),
    "</section>",
    "</section></main></body></html>",
  ].join("\n")
}

///|
fn cookbook_describer_card_html(
  title : String,
  path : String,
  summary : String,
) -> String {
  [
    "<article class=\"card describer\">",
    "<h3>\{html_escape(title)}</h3>",
    "<p>\{html_escape(summary)}</p>",
    "<p><code>\{html_escape(path)}</code></p>",
    "</article>",
  ].join("")
}

///|
fn cookbook_artifact_card_html(artifact : CookbookArtifact) -> String {
  [
    "<article class=\"card\">",
    "<h3>\{html_escape(artifact.path)}</h3>",
    "<p><strong>\{html_escape(artifact.kind)}</strong> / \{html_escape(artifact.owner)}</p>",
    "<p>\{html_escape(artifact.stable_role)}</p>",
    "<p>required=\{artifact.required}; exists=\{artifact.exists}</p>",
    "</article>",
  ].join("")
}

///|
fn cookbook_site_style_html() -> String {
  [
    "<style>", "body{font-family:Georgia,serif;background:#f7ecd0;color:#2c2114;margin:0;padding:32px}",
    "main{max-width:1120px;margin:auto}", "section{margin-top:28px}", ".grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:16px}",
    ".card{background:#fff8df;border:2px solid #5b4428;padding:16px;box-shadow:4px 4px 0 #c5a86b}",
    ".describer{background:#fffdf2;border-color:#2f5f5b}", "code{background:#ead7a1;padding:2px 5px}",
    "</style>",
  ].join("")
}

///|
fn html_escape(text : String) -> String {
  let builder = StringBuilder::new()
  for char in text {
    match char {
      '&' => builder.write_string("&amp;")
      '<' => builder.write_string("&lt;")
      '>' => builder.write_string("&gt;")
      '"' => builder.write_string("&quot;")
      _ => builder.write_char(char)
    }
  }
  builder.to_string()
}
