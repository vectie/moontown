///|
test "public demo contains only two trial catalog entries and never fake live metrics" {
  let value = public_demo()
  assert_true(
    value
    is {
      "mode": String("demo"),
      "observed_at": String(""),
      "scope": {
        "audience": String("public"),
        "state": String("public-demo"),
        ..
      },
      "local_cluster": { "machines": Array(machines), .. },
      ..
    } &&
    machines.length() == 2 &&
    machines.all(m => {
      m is { "state": String("not-observed"), "metrics_reported": False, .. }
    }),
  )
  for hidden in ["spark-", "192.168.", "dedicated-", "lease_ref", "lnxs_"] {
    assert_false(value.stringify().contains(hidden))
  }
}

///|
fn heartbeat_fixture(id : String, time : Int64) -> Json {
  {
    "node_id": id,
    "state": "Ready",
    "timestamp_unix_ms": time,
    "inventory": {
      "accelerators": [
        {
          "architecture": "test-gpu",
          "memory_total_mib": 1000,
          "memory_free_mib": 400,
          "healthy": true,
        },
      ],
    },
    "running_deployments": ["private-workload"],
    "signature": "private-signature",
    "runtime_endpoints": [{ "url": "http://private-network" }],
  }
}

///|
test "admin projection contains exactly approved four nodes and redacts topology" {
  let now = 1000000L
  let rows = [
    heartbeat_fixture(town_fleet()[0].0, now),
    heartbeat_fixture("outside-approved-fleet", now),
  ]
  let machines = fleet_machines(rows.to_json(), now).unwrap()
  assert_eq(machines.length(), 4)
  assert_true(
    machines[0]
    is { "metrics_reported": True, "running_workloads": Number(1, ..), .. },
  )
  assert_true(machines[3] is { "metrics_reported": False, .. })
  for hidden in ["outside-approved", "private-", "spark-"] {
    assert_false(machines.to_json().stringify().contains(hidden))
  }
  assert_true(fleet_machines([rows[0], rows[0]], now) is None)
  let stale = fleet_machines(
      [heartbeat_fixture(town_fleet()[0].0, now - 90001L)],
      now,
    ).unwrap()[0]
  assert_true(
    stale
    is {
      "state": String("delayed"),
      "metrics_reported": False,
      "healthy": False,
      ..
    },
  )
}
