///|
test "customer machine binding uses stable lease identity without leaking access details" {
  let source : Json = [
    {
      "machine_ref": "assigned-machine:lease-a",
      "lease_ref": "lease-a",
      "state": "Active",
      "reachability": "Online",
      "username": "private-user",
      "credential_handoff": { "private_key": "do-not-copy" },
      "node_id": "operator-only-node",
      "inventory": { "memory_total_mib": 128000 },
    },
  ]
  let machines = account_compute_machines(source).unwrap()
  assert_eq(machines.length(), 1)
  assert_true(
    machines[0]
    is {
      "id": String("assigned-machine:lease-a"),
      "state": String("ready"),
      "metrics_reported": False,
      ..
    },
  )
  let text = machines.to_json().stringify()
  for secret in ["private-user", "do-not-copy", "operator-only-node", "128000"] {
    assert_false(text.contains(secret))
  }
}

///|
test "operator inventory and duplicate resource identities are not customer machines" {
  assert_true(
    account_compute_machines([{ "node_id": "n", "inventory": {} }]) is None,
  )
  let row : Json = {
    "machine_ref": "m",
    "lease_ref": "l",
    "state": "Active",
    "reachability": "Unknown",
  }
  assert_true(account_compute_machines([row, row]) is None)
  assert_true(
    account_compute_machines([row]).unwrap()[0]
    is { "state": String("unknown"), "healthy": False, .. },
  )
  assert_eq(account_compute_machines([]).unwrap().length(), 0)
}

///|
test "unbound account never receives local inventory or host-wide model routes" {
  let result = account_compute_snapshot("sign-in-required", [], Json::null(), [])
  assert_true(
    result
    is {
      "local_cluster": { "machines": Array([]), .. },
      "remote_routes": Array([]),
      "gateway": {
        "active_targets": Array([]),
        "model_count": Number(0, ..),
        ..
      },
      ..
    },
  )
  assert_false(valid_compute_organization("org\r\nAuthorization: forged"))
  assert_false(valid_compute_organization("../../other-account"))
  assert_true(valid_compute_organization("org-1"))
}
