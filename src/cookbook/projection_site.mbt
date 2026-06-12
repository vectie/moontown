///|
pub fn generated_site_html(
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
    "<p>The cookbook is the Moontown codebase describer: it explains algorithms, data structures, data flow, core feature implementation, AI boundaries, and stable evidence files.</p>",
    "<p>Workspace <code>\{html_escape(entry.workspace_root)}</code>; manifest <code>\{html_escape(manifest.manifest_path)}</code>.</p>",
    "<section>",
    "<h2>Codebase Describer Pages</h2>",
    "<div class=\"grid\">",
    cookbook_describer_card_html(
      "Overview", "../../describer/overview.html?v=codebase-rendered", "wiki/describer/overview.md",
      "Engineer-facing mental model and reading order for Moontown as a typed, file-backed control plane.",
    ),
    cookbook_describer_card_html(
      "Algorithms", "../../describer/algorithms.html?v=codebase-rendered", "wiki/describer/algorithms.md",
      "Daemon phases, standing-watch dispatch, civic map/reduce, scenario materialization, request processing, live autonomy, and visual projection.",
    ),
    cookbook_describer_card_html(
      "Data Structures", "../../describer/data-structures.html?v=codebase-rendered",
      "wiki/describer/data-structures.md", "TownState, execution records, standing goals, civic protocol packets, reductions, review gates, snapshots, and cookbook manifests.",
    ),
    cookbook_describer_card_html(
      "Data Flow", "../../describer/data-flow.html?v=codebase-rendered", "wiki/describer/data-flow.md",
      "How operator inputs, schedules, Mayor routing, MoonBook packets, MoonClaw runs, ledgers, and projections move through the system.",
    ),
    cookbook_describer_card_html(
      "Core Features", "../../describer/core-features.html?v=codebase-rendered",
      "wiki/describer/core-features.md", "Implementation guide for the saved town runtime, Mayor, MoonBook/MoonClaw bridge, civic protocols, live autonomy, UI projection, PlanBook, and cookbook.",
    ),
    cookbook_describer_card_html(
      "Content Rules", "../../describer/content-rules.html?v=codebase-rendered",
      "wiki/describer/content-rules.md", "How docs, definitions, runtime state, civic protocols, AI work, and procedures should be described differently.",
    ),
    cookbook_describer_card_html(
      "Cookbook Skill", "../../skills/cookbook-generation.html?v=codebase-rendered",
      "skills/cookbook-generation/SKILL.md", "Instructions future AI maintainers must follow so the cookbook stays a codebase describer.",
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
  href : String,
  path : String,
  summary : String,
) -> String {
  [
    "<article class=\"card describer\">",
    "<h3><a href=\"\{html_escape(href)}\">\{html_escape(title)}</a></h3>",
    "<p>\{html_escape(summary)}</p>",
    "<p><code>\{html_escape(path)}</code></p>",
    "<p><a class=\"open-link\" href=\"\{html_escape(href)}\">Open rendered page</a></p>",
    "</article>",
  ].join("")
}

///|
pub fn cookbook_artifact_card_html(artifact : CookbookArtifact) -> String {
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
pub fn cookbook_site_style_html() -> String {
  [
    "<style>", "body{font-family:Georgia,serif;background:#f7ecd0;color:#2c2114;margin:0;padding:32px}",
    "main{max-width:1120px;margin:auto}", "section{margin-top:28px}", ".grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:16px}",
    ".card{background:#fff8df;border:2px solid #5b4428;padding:16px;box-shadow:4px 4px 0 #c5a86b}",
    ".describer{background:#fffdf2;border-color:#2f5f5b}", "code{background:#ead7a1;padding:2px 5px}",
    "a{color:#174d48}.open-link{font-weight:700}", "</style>",
  ].join("")
}

///|
pub fn cookbook_rendered_markdown_html(
  title : String,
  source_path : String,
  markdown : String,
) -> String {
  [
    "<!doctype html>",
    "<html><head><meta charset=\"utf-8\"><title>\{html_escape(title)}</title>",
    cookbook_rendered_page_style_html(),
    "</head><body><main>",
    "<nav><a href=\"../site/generated/index.html?v=codebase-rendered\">Cookbook Home</a> <span>/</span> <code>\{html_escape(source_path)}</code></nav>",
    markdown_to_html(markdown),
    "</main></body></html>",
  ].join("\n")
}

///|
pub fn cookbook_rendered_skill_html(
  title : String,
  source_path : String,
  markdown : String,
) -> String {
  [
    "<!doctype html>",
    "<html><head><meta charset=\"utf-8\"><title>\{html_escape(title)}</title>",
    cookbook_rendered_page_style_html(),
    "</head><body><main>",
    "<nav><a href=\"../site/generated/index.html?v=codebase-rendered\">Cookbook Home</a> <span>/</span> <code>\{html_escape(source_path)}</code></nav>",
    markdown_to_html(markdown),
    "</main></body></html>",
  ].join("\n")
}

///|
fn cookbook_rendered_page_style_html() -> String {
  [
    "<style>", "body{font-family:Georgia,serif;background:#fffaf0;color:#21190f;margin:0;padding:32px;line-height:1.55}",
    "main{max-width:920px;margin:auto}", "nav{font-family:ui-sans-serif,system-ui,sans-serif;margin-bottom:28px;color:#5b4428}",
    "h1,h2,h3{line-height:1.18}", "h1{font-size:34px;margin-bottom:18px}", "h2{border-top:1px solid #d7c6a0;padding-top:24px;margin-top:32px}",
    "a{color:#174d48}", "code{background:#ead7a1;padding:2px 5px;border-radius:3px}",
    "pre{background:#21190f;color:#fff8df;padding:16px;overflow:auto;border-radius:6px}",
    "pre code{background:transparent;color:inherit;padding:0}", "table{border-collapse:collapse;width:100%;margin:18px 0;font-size:14px}",
    "th,td{border:1px solid #c5a86b;padding:8px;vertical-align:top}", "th{background:#f1dfad;text-align:left}",
    "li{margin:6px 0}", "</style>",
  ].join("")
}

///|
fn markdown_to_html(markdown : String) -> String {
  let builder = StringBuilder::new()
  let mut in_code = false
  let mut in_list = false
  let mut in_table = false
  for raw in markdown.split("\n") {
    let line = raw.to_owned()
    let trimmed = line.trim().to_owned()
    if trimmed.has_prefix("```") {
      if in_table {
        builder.write_string("</tbody></table>\n")
        in_table = false
      }
      if in_list {
        builder.write_string("</ul>\n")
        in_list = false
      }
      if in_code {
        builder.write_string("</code></pre>\n")
        in_code = false
      } else {
        builder.write_string("<pre><code>")
        in_code = true
      }
      continue
    }
    if in_code {
      builder.write_string(html_escape(line))
      builder.write_char('\n')
      continue
    }
    if trimmed.is_empty() {
      if in_list {
        builder.write_string("</ul>\n")
        in_list = false
      }
      if in_table {
        builder.write_string("</tbody></table>\n")
        in_table = false
      }
      continue
    }
    if markdown_table_separator(trimmed) {
      continue
    }
    if trimmed.has_prefix("|") {
      if in_list {
        builder.write_string("</ul>\n")
        in_list = false
      }
      if !in_table {
        builder.write_string("<table><tbody>\n")
        in_table = true
      }
      builder.write_string(markdown_table_row_html(trimmed))
      builder.write_char('\n')
      continue
    }
    if in_table {
      builder.write_string("</tbody></table>\n")
      in_table = false
    }
    if trimmed.has_prefix("- ") {
      if !in_list {
        builder.write_string("<ul>\n")
        in_list = true
      }
      builder.write_string("<li>")
      builder.write_string(markdown_inline_html(trimmed[2:].to_owned()))
      builder.write_string("</li>\n")
      continue
    }
    if in_list {
      builder.write_string("</ul>\n")
      in_list = false
    }
    if trimmed.has_prefix("### ") {
      builder.write_string(
        "<h3>\{markdown_inline_html(trimmed[4:].to_owned())}</h3>\n",
      )
    } else if trimmed.has_prefix("## ") {
      builder.write_string(
        "<h2>\{markdown_inline_html(trimmed[3:].to_owned())}</h2>\n",
      )
    } else if trimmed.has_prefix("# ") {
      builder.write_string(
        "<h1>\{markdown_inline_html(trimmed[2:].to_owned())}</h1>\n",
      )
    } else if trimmed == "---" {
      builder.write_string("<hr>\n")
    } else {
      builder.write_string("<p>\{markdown_inline_html(trimmed)}</p>\n")
    }
  }
  if in_code {
    builder.write_string("</code></pre>\n")
  }
  if in_list {
    builder.write_string("</ul>\n")
  }
  if in_table {
    builder.write_string("</tbody></table>\n")
  }
  builder.to_string()
}

///|
fn markdown_inline_html(text : String) -> String {
  let builder = StringBuilder::new()
  let mut code = false
  for part in text.split("`") {
    let owned = part.to_owned()
    if code {
      builder.write_string("<code>\{html_escape(owned)}</code>")
    } else {
      builder.write_string(html_escape(owned))
    }
    code = !code
  }
  builder.to_string()
}

///|
fn markdown_table_separator(line : String) -> Bool {
  if !line.has_prefix("|") {
    return false
  }
  let mut has_dash = false
  for char in line {
    match char {
      '|' | ':' | ' ' | '\t' => ()
      '-' => has_dash = true
      _ => return false
    }
  }
  has_dash
}

///|
fn markdown_table_row_html(line : String) -> String {
  let cells : Array[String] = []
  for cell in line.split("|") {
    cells.push(cell.trim().to_owned())
  }
  let builder = StringBuilder::new()
  builder.write_string("<tr>")
  for index in 0..<cells.length() {
    let cell = cells[index]
    if index == 0 || index == cells.length() - 1 {
      continue
    }
    builder.write_string("<td>")
    builder.write_string(markdown_inline_html(cell))
    builder.write_string("</td>")
  }
  builder.write_string("</tr>")
  builder.to_string()
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
