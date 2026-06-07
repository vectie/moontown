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
    "<p>Workspace <code>\{html_escape(entry.workspace_root)}</code>; manifest <code>\{html_escape(manifest.manifest_path)}</code>.</p>",
    "<section class=\"grid\">",
    cards.join("\n"),
    "</section></main></body></html>",
  ].join("\n")
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
    "main{max-width:1120px;margin:auto}", ".grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:16px}",
    ".card{background:#fff8df;border:2px solid #5b4428;padding:16px;box-shadow:4px 4px 0 #c5a86b}",
    "code{background:#ead7a1;padding:2px 5px}", "</style>",
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
