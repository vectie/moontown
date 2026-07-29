///|
async test "miniapp projection keeps useful work and hides local internals" {
  let root = "/tmp/moontown-town-projection-\{@env.now()}"
  let snapshot : Json = {
    "event_count": 1,
    "town": {
      "books": [
        {
          "id": "research-energy",
          "name": "Energy Research",
          "purpose": "Track energy evidence",
          "memory_scope": "book",
          "tags": ["energy", "research"],
          "workspace_root": "/Users/operator/secret/books/research-energy",
        },
      ],
      "workers": [
        {
          "id": "worker-1",
          "name": "Scout",
          "role": "researcher",
          "status": "running",
          "book_id": "research-energy",
          "capabilities": ["web-search"],
          "skill_paths": ["/Users/operator/secret/skills/search"],
        },
      ],
      "tasks": [
        {
          "id": "task-1",
          "title": "Research grid storage",
          "status": "assigned",
          "book_id": "research-energy",
          "domain": "energy",
          "required_role": "researcher",
          "prompt": "Private operator prompt",
        },
      ],
      "executions": [
        {
          "task_id": "task-1",
          "status": "running",
          "summary": "Command \"/Users/operator/secret/bin/moon\" failed.\nstderr: private",
          "requires_review": true,
          "result_decision": "",
          "packet_path": "/Users/operator/secret/packets/task-1.json",
        },
      ],
    },
  }
  @support.write_text_file(root + "/town.json", snapshot.stringify())
  let goals : Json = [{ "id": "watch-energy" }]
  @support.write_text_file(root + "/standing-goals.json", goals.stringify())
  let result = @town_projection.town_projection(root).miniapp_snapshot()
  let encoded = result.stringify()
  assert_true(encoded.contains("\"mode\":\"live\""))
  assert_true(encoded.contains("\"name\":\"Energy Research\""))
  assert_true(
    encoded.contains("\"id\":\"placement-energy-valley-research-energy\""),
  )
  assert_true(encoded.contains("\"layoutSource\":\"procedural\""))
  assert_true(encoded.contains("\"name\":\"Scout\""))
  assert_true(encoded.contains("\"title\":\"Research grid storage\""))
  assert_true(encoded.contains("\"summary\":\"Work is running.\""))
  assert_true(encoded.contains("\"standingGoalCount\":1"))
  assert_true(!encoded.contains("workspace_root"))
  assert_true(!encoded.contains("Private operator prompt"))
  assert_true(!encoded.contains("packet_path"))
  assert_true(!encoded.contains("/Users/operator/secret"))
}

///|
async test "missing town state produces an empty unavailable projection" {
  let root = "/tmp/moontown-town-projection-missing-\{@env.now()}"
  let result = @town_projection.town_projection(root).miniapp_snapshot()
  let encoded = result.stringify()
  assert_true(encoded.contains("\"mode\":\"unavailable\""))
  assert_true(encoded.contains("\"buildings\":[]"))
  assert_true(encoded.contains("\"agents\":[]"))
}
