///|
test "moongate daemon startup messages describe town bridge and standalone fallback" {
  assert_eq(
    moongate_daemon_ready_message("http://127.0.0.1:15721"),
    "MoonGate available at http://127.0.0.1:15721; town usage/statistics bridge enabled",
  )
  assert_eq(
    moongate_daemon_unavailable_message(
      "http://127.0.0.1:15721", "request error: connection refused",
    ),
    "MoonGate unavailable at http://127.0.0.1:15721; continuing as standalone MoonTown: request error: connection refused",
  )
}
