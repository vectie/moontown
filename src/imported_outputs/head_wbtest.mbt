///|
async test "HEAD omits Content-Length for all representations while GET retains exact length" {
  let (home, _, selection) = fixture(b"payload")
  defer @fs.rmdir(home, recursive=true)
  for
    target in [
      "/api/imported-outputs",
      @contract.content_path(selection, mode="text"),
      @contract.content_path(selection, mode="download"),
      @contract.content_path(
        { ..selection, digest: hash(b"changed"), },
        mode="text",
      ),
      "/api/imported-outputs/content?invalid=query",
      "/api/imported-outputs/unknown",
    ] {
    let get = respond("GET", target, home + "/missing.json", home)
    let head = respond("HEAD", target, home + "/missing.json", home)
    assert_eq(head.status, get.status)
    assert_eq(head.body, b"")
    assert_eq(head.headers.get("Content-Length"), None)
    assert_eq(
      get.headers.get("Content-Length"),
      Some(get.body.length().to_string()),
    )
    for key, value in get.headers {
      if key != "Content-Length" {
        assert_eq(head.headers.get(key), Some(value))
      }
    }
  }
}
