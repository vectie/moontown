///|
fn queue_job(
  id : String,
  status : String,
  started~ : UInt64 = 0UL,
  finished~ : UInt64 = 0UL,
) -> Generation {
  {
    id,
    actor: "private-" + id,
    intent: id,
    prompt: "private prompt",
    state: status,
    created_ms: 100UL,
    started_ms: started,
    finished_ms: finished,
    sha256: "",
    reason: "",
    provider_id: "",
  }
}

///|
test "queue projection follows worker FIFO without exposing other identities" {
  let config = {
    ..fixture_config(),
    brief: { ..fixture_config().brief, deadline_ms: 1000000UL, },
  }
  let current = queue_job("current", "running", started=1000UL)
  let a = queue_job("a", "queued")
  let b = queue_job("b", "queued")
  let state = {
    ..empty(config),
    generations: [queue_job("old", "failed"), current, a, b],
  }
  assert_true(
    generation_queue(a, state, config, 2000UL)
    is {
      "ahead": Number(1, ..),
      "position": Number(2, ..),
      "estimated_start_ms": "11000",
      ..
    },
  )
  assert_true(
    generation_queue(b, state, config, 2000UL)
    is {
      "ahead": Number(2, ..),
      "position": Number(3, ..),
      "estimated_start_ms": "21000",
      ..
    },
  )
  let public = snapshot(state, config, 2000UL, Some("private-b"), false).stringify()
  assert_false(public.contains("private-a"))
  assert_false(public.contains("\"id\":\"current\""))
}

///|
test "queue ETA uses bounded recent costs and moves with clock without a revision change" {
  let config = {
    ..fixture_config(),
    brief: { ..fixture_config().brief, deadline_ms: 1000000UL, },
  }
  let job = queue_job("running", "running", started=20000UL)
  let state = {
    ..empty(config),
    generations: [
      queue_job("one", "completed", started=1000UL, finished=9000UL),
      queue_job("two", "completed", started=1000UL, finished=10000UL),
      queue_job("bad", "completed", started=0UL, finished=100000UL),
      job,
    ],
  }
  assert_eq(queue_service_ms(state), 10000UL)
  assert_true(
    generation_queue(job, state, config, 22000UL)
    is {
      "status": "running",
      "estimated_ready_ms": "29000",
      "sample_count": Number(2, ..),
      ..
    },
  )
  assert_true(
    generation_queue(job, state, config, 25000UL)
    is { "estimated_ready_ms": "29000", .. },
  )
  assert_true(
    generation_queue(job, state, config, 35001UL)
    is { "status": "delayed", "estimated_ready_ms": Null, .. },
  )
}

///|
test "uncertain and closed queues do not promise a countdown" {
  let config = fixture_config()
  let queued = queue_job("a", "queued")
  let state = {
    ..empty(config),
    generations: [queue_job("blocked", "needs_reconcile"), queued],
  }
  assert_true(
    generation_queue(queued, state, config, 500UL)
    is {
      "status": "blocked",
      "reason": "reconcile",
      "estimated_start_ms": Null,
      "estimated_ready_ms": Null,
      ..
    },
  )
  let closed = { ..state, generations: [queued], }
  assert_true(
    generation_queue(queued, closed, config, 1000UL)
    is {
      "status": "blocked",
      "reason": "closed",
      "estimated_ready_ms": Null,
      ..
    },
  )
}
