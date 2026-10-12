///|
fn header() -> String {
  "claim_id,book_id,topic,context,value,source_path,quote\n"
}

///|
fn row(
  id : String,
  book : String,
  topic : String,
  context : String,
  value : String,
  path : String,
  quote : String,
) -> String {
  [id, book, topic, context, value, path, quote]
  .map(v => "\"" + v.replace_all(old="\"", new="\"\"") + "\"")
  .join(",") +
  "\n"
}

///|
fn output(
  rows : String,
  sources : Map[String, Bytes],
  format? : String = "json",
) -> String raise {
  match
    @claim_comparison.report(
      @utf8.encode(header() + rows),
      ',',
      sources,
      format~,
    ) {
    Ok(value) => value
    Err(error) => fail(error)
  }
}

///|
fn field(value : Json, key : String) -> Json raise {
  guard value is Object(fields) && fields.get(key) is Some(found) else {
    fail("Missing field " + key)
  }
  found
}

///|
fn item(value : Json, index : Int) -> Json raise {
  guard value is Array(items) && items.get(index) is Some(found) else {
    fail("Missing item")
  }
  found
}

///|
test "exact-context groups preserve cross-book differences agreement and single-book evidence" {
  let rows = row(
      "a", "sales", "launch", "2026-10", "November", "a.txt", "Launch: November",
    ) +
    row(
      "b", "engineering", "launch", "2026-10", "December", "b.txt", "Launch: December",
    ) +
    row(
      "c", "sales", "launch", "2026-09", "November", "a.txt", "Launch: November",
    ) +
    row("d", "sales", "region", "current", "水", "a.txt", "水") +
    row("e", "engineering", "region", "current", "水", "b.txt", "水")
  let report = @json.parse(
    output(rows, {
      "a.txt": @utf8.encode("Launch: November\n水"),
      "b.txt": @utf8.encode("Launch: December\n水"),
    }),
  )
  assert_eq(field(report, "state"), "pending_review".to_json())
  let groups = field(report, "groups")
  assert_eq(field(item(groups, 0), "state"), "different_values".to_json())
  assert_eq(field(item(groups, 1), "state"), "single_book".to_json())
  assert_eq(field(item(groups, 2), "state"), "same_value".to_json())
  assert_eq(
    field(item(field(item(groups, 0), "claims"), 1), "quote"),
    "Launch: December".to_json(),
  )
  assert_eq(
    field(item(field(report, "sources"), 0), "size_bytes"),
    (20).to_json(),
  )
}

///|
test "literal whitespace case and context identities are never normalized" {
  let rows = row("a", "A", "t", "ctx", "Yes", "a", "yes") +
    row("b", "B", "t", "ctx", "yes", "a", "yes") +
    row("c", "A", "t ", "ctx", "Yes", "a", "yes") +
    row("d", "B", "t", "ctx ", "Yes", "a", "yes")
  let groups = field(@json.parse(output(rows, { "a": b"yes" })), "groups")
  guard groups is Array(groups) else { fail("groups") }
  assert_eq(groups.length(), 3)
  assert_eq(field(groups[0], "state"), "different_values".to_json())
}

///|
test "source and table digests bind exact bytes even with unchanged quotes" {
  let rows = row("a", "A", "t", "ctx", "yes", "a", "yes")
  let first = @json.parse(output(rows, { "a": b"yes" }))
  let second = @json.parse(output(rows, { "a": b"yes\n" }))
  assert_true(
    field(item(field(first, "sources"), 0), "digest") !=
    field(item(field(second, "sources"), 0), "digest"),
  )
  assert_eq(
    field(item(field(first, "sources"), 0), "digest"),
    ("sha256:" + @crypto.bytes_to_hex_string(@crypto.sha256(b"yes"))).to_json(),
  )
  let changed = @json.parse(
    output(rows + row("b", "B", "t", "ctx", "yes", "a", "yes"), { "a": b"yes" }),
  )
  assert_true(field(first, "table_digest") != field(changed, "table_digest"))
}

///|
test "CSV multiline quotes TSV BOM and repeated source selection" {
  let rows = row("a", "A", "t", "ctx", "x,\"水\"\ny", "a", "x,\"水\"\ny") +
    row("b", "B", "t", "ctx", "same", "a", "y")
  let table = @utf8.encode(header() + rows)
  assert_eq(@claim_comparison.source_paths(table, ','), Ok(["a"]))
  let report = @json.parse(output(rows, { "a": @utf8.encode("x,\"水\"\ny") }))
  assert_eq(
    field(item(field(item(field(report, "groups"), 0), "claims"), 0), "value"),
    "x,\"水\"\ny".to_json(),
  )
  let tsv = @utf8.encode(
    "\uFEFFclaim_id\tbook_id\ttopic\tcontext\tvalue\tsource_path\tquote\r\na\tA\tt\tctx\ty\ta\ty\r\n",
  )
  assert_eq(@claim_comparison.source_paths(tsv, '\t'), Ok(["a"]))
  assert_true(
    @claim_comparison.report(tsv, '\t', { "a": b"y" }, format="json") is Ok(_),
  )
}

///|
test "unmatched quotes missing extra invalid or oversized sources fail the entire report" {
  let table = @utf8.encode(
    header() + row("a", "A", "t", "ctx", "x", "a", "needle"),
  )
  for
    sources in [
      {},
      { "other": b"needle" },
      { "a": b"Needle" },
      { "a": b"needle", "extra": b"needle" },
      { "a": Bytes::from_array([0xff]) },
      { "a": @utf8.encode("needle" + "x".repeat(262144)) },
    ] {
    assert_true(
      @claim_comparison.report(table, ',', sources, format="json") is Err(_),
    )
  }
}

///|
test "table schema duplicate identifiers blank cells and unsafe source paths fail" {
  let valid = row("a", "A", "t", "ctx", "x", "a", "x")
  for
    text in [
      header(),
      "wrong\nx\n",
      header() + valid + valid,
      header() + row("a", "A", "t", " ", "x", "a", "x"),
      header() + "\"unclosed",
      header() + row("a", "A", "t", "ctx", "x", "../a", "x"),
      header() + row("a", "A", "t", "ctx", "x", "/a", "x"),
      header() + row("a", "A", "t", "ctx", "x", "a\\b", "x"),
    ] {
    assert_true(
      @claim_comparison.source_paths(@utf8.encode(text), ',') is Err(_),
    )
  }
  assert_true(
    @claim_comparison.source_paths(Bytes::from_array([0xff]), ',') is Err(_),
  )
  assert_true(
    @claim_comparison.source_paths(@utf8.encode(header() + valid), ';')
    is Err(_),
  )
  assert_true(
    @claim_comparison.report(
      @utf8.encode(header() + valid),
      ',',
      { "a": b"x" },
      format="html",
    )
    is Err(_),
  )
}

///|
test "row source input and output limits reject rather than truncate" {
  let rows = Array::makei(201, i => {
    row(i.to_string(), "A", "t", "ctx", "x", "a", "x")
  }).join("")
  assert_true(
    @claim_comparison.source_paths(@utf8.encode(header() + rows), ',') is Err(_),
  )
  let rows = Array::makei(65, i => {
    row(i.to_string(), "A", "t", "ctx", "x", i.to_string(), "x")
  }).join("")
  assert_true(
    @claim_comparison.source_paths(@utf8.encode(header() + rows), ',') is Err(_),
  )
  assert_true(
    @claim_comparison.source_paths(@utf8.encode("x".repeat(1048577)), ',')
    is Err(_),
  )
  let rows = Array::makei(33, i => {
    row(i.to_string(), "A", "t", "ctx", "x", i.to_string(), "x")
  }).join("")
  let sources : Map[String, Bytes] = {}
  for i = 0; i < 33; i = i + 1 {
    sources[i.to_string()] = @utf8.encode("x".repeat(262144))
  }
  assert_true(
    @claim_comparison.report(
      @utf8.encode(header() + rows),
      ',',
      sources,
      format="json",
    )
    is Err(_),
  )
  // JSON escaping expands ASCII controls to six characters each.
  let controls = "\u0001".repeat(15000)
  let rows = Array::makei(30, i => {
    row(i.to_string(), "A", "t", "ctx", "x", "a", controls)
  }).join("")
  guard @claim_comparison.report(
      @utf8.encode(header() + rows),
      ',',
      { "a": @utf8.encode(controls) },
      format="json",
    )
    is Err(error) else {
    fail("Expected output size rejection")
  }
  assert_true(error.contains("Comparison exceeds 2 MiB"))
}

///|
test "Markdown escapes source markup and exposes all evidence" {
  let value = "[click](https://example.test) <script> & #title\n水"
  let result = output(
    row("a", "A", "t", "ctx", value, "a", value),
    { "a": @utf8.encode(value) },
    format="markdown",
  )
  assert_true(
    result.contains(
      "\\[click\\]\\(https://example\\.test\\) \\<script\\> \\& \\#title",
    ),
  )
  assert_true(!result.contains("\n水"))
  assert_true(result.contains("Exact quote:"))
  assert_true(result.contains("sha256:"))
}

///|
test "200 claims and 64 captured sources are admitted without truncation" {
  let rows = Array::makei(200, i => {
    row(
      i.to_string(),
      if i % 2 == 0 {
        "A"
      } else {
        "B"
      },
      "t",
      "ctx",
      "x",
      (i % 64).to_string(),
      "x",
    )
  }).join("")
  let sources : Map[String, Bytes] = {}
  for i = 0; i < 64; i = i + 1 {
    sources[i.to_string()] = b"x"
  }
  let report = @json.parse(output(rows, sources))
  guard field(report, "sources") is Array(saved) else { fail("sources") }
  assert_eq(saved.length(), 64)
  guard field(item(field(report, "groups"), 0), "claims") is Array(claims) else {
    fail("claims")
  }
  assert_eq(claims.length(), 200)
}

///|
test "multiple different values from one Book remain a single-book group" {
  let rows = row("a", "A", "t", "ctx", "yes", "a", "yes") +
    row("b", "A", "t", "ctx", "no", "a", "no")
  let report = @json.parse(output(rows, { "a": b"yes no" }))
  assert_eq(
    field(item(field(report, "groups"), 0), "state"),
    "single_book".to_json(),
  )
}
