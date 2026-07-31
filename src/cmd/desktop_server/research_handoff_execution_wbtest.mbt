///|
test "research handoff callback uses exact bounded UTF-8 payload" {
  let result_package : Json = {
    "contract_id": "moonfind.moontown-result-ingest.v1",
    "summary": "跨论文综合",
  }
  let expected = result_package.stringify()
  let (payload, headers) = research_handoff_callback_payload(result_package)
  assert_eq(@utf8.decode(payload), expected)
  assert_eq(
    headers.get("Content-Length"),
    Some(@utf8.encode(expected).length().to_string()),
  )
  assert_eq(
    headers.get("Content-Type"),
    Some("application/json; charset=utf-8"),
  )
  assert_eq(headers.get("Accept"), Some("application/json"))
  assert_eq(headers.get("Transfer-Encoding"), None)
}
