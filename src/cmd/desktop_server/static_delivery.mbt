///|
/// Only packaged public assets receive revalidation/compression. Runtime JSON,
/// book output and account/API responses retain the existing no-store policy.
fn cacheable_product_asset(relative : String) -> Bool {
  if relative.has_suffix(".etag") || relative.has_suffix(".gz") {
    return false
  }
  [".js", ".mjs", ".css", ".png", ".webp", ".svg", ".jpg"].any(ext => {
    relative.has_suffix(ext)
  }) ||
  (relative.has_prefix("landmark-studio/") && relative.has_suffix(".json")) ||
  relative == "knowledge-domain-catalog.json" ||
  (
    relative.has_prefix("tilemap/") &&
    relative.has_suffix(".json") &&
    !relative.has_prefix("tilemap/modules/")
  )
}

///|
fn accepts_gzip(value : String) -> Bool {
  for item in value.to_lower().split(",") {
    let parts = item.split(";").collect()
    if parts[0].trim() != "gzip" {
      continue
    }
    for param in parts[1:] {
      let p = param.trim()
      if p.has_prefix("q=") {
        let q = @string.parse_double(p[2:]) catch { _ => 0.0 }
        return q > 0.0 && q <= 1.0
      }
    }
    return true
  }
  false
}

///|
fn etag_matches(header : String, etag : String) -> Bool {
  header
  .split(",")
  .any(value => {
    let value = value.trim()
    value == "*" || value == etag || value == "W/" + etag
  })
}

///|
async fn serve_product_asset(
  request : @http.Request,
  conn : @http.ServerConnection,
  relative : String,
) -> Bool {
  let path = static_root() + "/" + relative
  guard @fs.exists(path) && @fs.kind(path) is Regular else { return false }
  if !cacheable_product_asset(relative) || !@fs.exists(path + ".etag") {
    return serve_file(conn, path)
  }
  let digest = @fs.read_file(path + ".etag").text().trim().to_owned()
  let gzip = accepts_gzip(request_header(request, "accept-encoding")) &&
    @fs.exists(path + ".gz")
  // Representation-specific tags; a gzip validator must not validate identity.
  let etag = if gzip {
    "\"gzip-" + digest.trim(chars="\"").to_owned() + "\""
  } else {
    digest
  }
  let headers : Map[String, String] = {
    "Content-Type": content_type(path),
    "Cache-Control": "public, no-cache",
    "ETag": etag,
    "Vary": "Accept-Encoding",
  }
  if gzip {
    headers["Content-Encoding"] = "gzip"
  }
  if etag_matches(request_header(request, "if-none-match"), etag) {
    conn.send_response(304, "Not Modified", extra_headers=headers)
    conn.end_response()
    return true
  }
  let file = @fs.open(if gzip { path + ".gz" } else { path }, mode=ReadOnly)
  defer file.close()
  headers["Content-Length"] = file.size().to_string()
  conn.send_response(200, "OK", extra_headers=headers)
  conn.write_reader(file)
  conn.end_response()
  true
}
