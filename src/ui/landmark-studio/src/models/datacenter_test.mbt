///|
test "data center exports five independent scales without altering landmark count" {
  guard @models.data_center_study()
    is { "schema": "moontown.datacenter-study.v1", "views": Array(views), .. } else {
    fail("missing study")
  }
  assert_eq(views.length(), 5)
  let ids = views.map(v => {
    guard v is { "study": { "id": String(id), .. }, .. } else {
      fail("missing ID")
    }
    id
  })
  assert_eq(ids, ["site", "hall", "rack", "server", "board"])
  guard @models.studies() is Array(landmarks) else { fail("missing landmarks") }
  assert_eq(landmarks.length(), 4)
}

///|
test "planning report is deterministic bounded and withholds missing telemetry" {
  let result = @models.data_center_report(60)
  guard result
    is {
      "servers": 144,
      "racks": 12,
      "rack_units_used": 312,
      "rack_units_total": 504,
      "rack_units_free": 192,
      "mode": "illustrative-planning",
      "pue": Null,
      "temperature_c": Null,
      "network_gbps": Null,
      "it_kw": Number(power, ..),
      "headroom_kw": Number(headroom, ..),
      ..
    } else {
    fail("planning contract")
  }
  assert_true((power - 63.648).abs() < 0.00001)
  assert_true((power + headroom - 96).abs() < 0.00001)
  assert_eq(@models.data_center_report(-100), @models.data_center_report(0))
  assert_eq(@models.data_center_report(999), @models.data_center_report(100))
  assert_eq(@models.data_center_report(60), result)
}

///|
test "observations validate and only return approved fields" {
  let input =
    #|{"schema":"moontown.secret-compute-room.v1","mode":"observed","observed_at":"2026-09-08T04:00:00Z","authority":{"agent_boundary":"MoonGate","local_control_plane":"LunaNexa","token":"DO-NOT-RETURN"},"gateway":{"state":"reachable","model_count":2,"address":"DO-NOT-RETURN"},"local_cluster":{"state":"observed","machines":[{"id":"local-node-1","label":"Local node 1","state":"active","architecture":"test-fixture","accelerator_count":1,"memory_total_mib":8192,"memory_free_mib":4096,"healthy":true,"running_workloads":2,"observed_at_unix_ms":"1788840000000","token":"DO-NOT-RETURN"}]},"remote_routes":[{"id":"kimi","label":"Kimi","state":"observed","evidence":"Test fixture only"}],"secret":"DO-NOT-RETURN"}
  let output = @models.data_center_observation(input)
  assert_true(
    output
    is { "ok": True, "physical_mapping": "unassigned", "machines": [_, ..], .. },
  )
  assert_true(!output.stringify().contains("DO-NOT-RETURN"))
  assert_true(!output.stringify().contains("token"))
}

///|
test "malformed snapshots fail closed" {
  for input in ["", "[]", "{", "{\"schema\":\"untrusted\"}"] {
    assert_true(@models.data_center_observation(input) is { "ok": False, .. })
  }
  let wrong =
    #|{"schema":"moontown.secret-compute-room.v1","mode":"observed","observed_at":"","authority":{"agent_boundary":"direct-shell","local_control_plane":"LunaNexa"},"gateway":{"state":"reachable","model_count":1},"local_cluster":{"state":"observed","machines":[]},"remote_routes":[]}
  assert_true(@models.data_center_observation(wrong) is { "ok": False, .. })
  let bad_memory =
    #|{"schema":"moontown.secret-compute-room.v1","mode":"observed","observed_at":"","authority":{"agent_boundary":"MoonGate","local_control_plane":"LunaNexa"},"gateway":{"state":"reachable","model_count":1},"local_cluster":{"state":"observed","machines":[{"id":"x","label":"x","state":"active","architecture":"test","accelerator_count":1,"memory_total_mib":8,"memory_free_mib":9,"healthy":true,"running_workloads":0,"observed_at_unix_ms":""}]},"remote_routes":[]}
  assert_true(
    @models.data_center_observation(bad_memory) is { "ok": False, .. },
  )
}
