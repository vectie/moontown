///|
test "moonstat daemon startup messages describe town bridge and standalone fallback" {
  assert_eq(
    moonstat_daemon_ready_message("http://127.0.0.1:15721"),
    "Moonstat available at http://127.0.0.1:15721; town usage/statistics bridge enabled",
  )
  assert_eq(
    moonstat_daemon_unavailable_message(
      "http://127.0.0.1:15721", "request error: connection refused",
    ),
    "Moonstat unavailable at http://127.0.0.1:15721; continuing as standalone Moontown: request error: connection refused",
  )
}
