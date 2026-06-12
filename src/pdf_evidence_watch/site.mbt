///|
fn pdf_evidence_watch_generated_site_html(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  purpose : String,
  websites : Array[String],
) -> String {
  let site_list = if websites.is_empty() {
    "<li>No websites configured yet.</li>"
  } else {
    websites.map(fn(site) { "<li>\{site}</li>" }).join("")
  }
  [
    "<!doctype html>",
    "<html lang=\"en\">",
    "<head>",
    "  <meta charset=\"utf-8\">",
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
    "  <title>\{title}</title>",
    "  <style>",
    "    body { margin: 0; font-family: ui-serif, Georgia, serif; background: #f7f4ec; color: #172018; }",
    "    main { max-width: 960px; margin: 0 auto; padding: 56px 24px; }",
    "    .card { background: #fffaf0; border: 1px solid #d7c8a4; border-radius: 24px; padding: 28px; box-shadow: 0 18px 60px rgba(30, 44, 20, .12); }",
    "    h1 { font-size: clamp(2.2rem, 5vw, 4rem); line-height: .95; margin: 0 0 18px; }",
    "    h2 { margin-top: 34px; }",
    "    code { background: #ece3ce; border-radius: 8px; padding: 2px 6px; }",
    "    li { margin: 8px 0; }",
    "  </style>",
    "</head>",
    "<body>",
    "  <main>",
    "    <section class=\"card\">",
    "      <p><code>\{entry.id}</code> · PDF Evidence Watch</p>",
    "      <h1>\{title}</h1>",
    "      <p>\{purpose}</p>",
    "      <h2>Watch Sites</h2>",
    "      <ul>\{site_list}</ul>",
    "      <h2>Workflow</h2>",
    "      <ol>",
    "        <li>Discover changed PDFs from configured websites.</li>",
    "        <li>Download PDFs and extract text/tables with provenance.</li>",
    "        <li>Analyze with the book-local method and skills.</li>",
    "        <li>Promote accepted findings into the wiki and notify only on new knowledge.</li>",
    "      </ol>",
    "    </section>",
    "  </main>",
    "</body>",
    "</html>",
  ].join("\n")
}
