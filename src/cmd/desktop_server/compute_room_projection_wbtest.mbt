///|
test "LunaNexa node projection is redacted and capacity-bearing" {
  let text =
    #|[{"node_id":"dgx-secret-01","state":"Active","timestamp_unix_ms":"1000","signature":"never-expose-this","inventory":{"node_id":"dgx-secret-01","accelerators":[{"device_id":"gpu-secret","architecture":"nvidia-gb10","memory_total_mib":128000,"memory_free_mib":64000,"healthy":true}]},"running_deployments":["deployment-secret"]}]
  let source = @json.parse(text)
  let projection = redacted_lunanexa_machines(Some(source))
  assert_eq(projection.length(), 1)
  let text = projection[0].stringify()
  assert_true(text.contains("local-node-1"))
  assert_true(text.contains("nvidia-gb10"))
  assert_true(text.contains("128000"))
  assert_false(text.contains("dgx-secret-01"))
  assert_false(text.contains("gpu-secret"))
  assert_false(text.contains("never-expose-this"))
  assert_false(text.contains("deployment-secret"))
}

///|
test "LunaNexa projection endpoint rejects arbitrary plain HTTP origins" {
  assert_true(lunanexa_projection_endpoint_allowed("https://cluster.example"))
  assert_true(lunanexa_projection_endpoint_allowed("http://127.0.0.1:18443"))
  assert_true(lunanexa_projection_endpoint_allowed("http://localhost:18443"))
  assert_false(lunanexa_projection_endpoint_allowed("http://cluster.example"))
  assert_false(lunanexa_projection_endpoint_allowed("file:///tmp/nodes.json"))
}

///|
test "remote route evidence never turns unobserved providers green" {
  let routes = compute_room_remote_routes(false, None, [])
  assert_eq(routes.length(), 4)
  for route in routes {
    assert_true(route.stringify().contains("not-observed"))
  }
}
