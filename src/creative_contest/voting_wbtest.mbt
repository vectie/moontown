///|
fn builtin_config() -> Config {
  { ..fixture_config(), voting_mode: Some("builtin"), }
}

///|
fn voting_works() -> State raise {
  let config = builtin_config()
  let mut state = empty(config)
  for creator in ["creator-a", "creator-b", "creator-c"] {
    state = completed(
      transition(
        state,
        config,
        "generate",
        { "prompt": "private-prompt-" + creator, "intent": "one" },
        500UL,
        creator,
        false,
      ),
    )
    let job = state.generations
      .iter()
      .find_first(job => job.actor == creator)
      .unwrap()
    state = transition(
      state,
      config,
      "submit",
      {
        "generation_id": job.id,
        "title": "art-" + creator,
        "display_name": "name-" + creator,
        "consent": true,
      },
      500UL,
      creator,
      false,
    )
    let entry = state.entries
      .iter()
      .find_first(entry => entry.actor == creator)
      .unwrap()
    state = transition(
      state,
      config,
      "approve",
      { "entry_id": entry.id },
      500UL,
      "host",
      true,
    )
  }
  state
}

///|
fn work_id(state : State, actor : String) -> String {
  state.entries.iter().find_first(entry => entry.actor == actor).unwrap().id
}

///|
fn vote_for(
  state : State,
  actor : String,
  id : String,
  intent : String,
) -> State raise {
  transition(
    state,
    builtin_config(),
    "vote",
    { "entry_id": id, "intent": intent },
    1110UL,
    actor,
    false,
  )
}

///|
test "builtin votes change cancel and replay one choice without leaking voters" {
  let config = builtin_config()
  let frozen = advance_voting(voting_works(), config, 1100UL)
  let a = work_id(frozen, "creator-a")
  let b = work_id(frozen, "creator-b")
  let first = vote_for(frozen, "private-voter-one", a, "private-intent-one")
  let replay = vote_for(first, "private-voter-one", a, "private-intent-one")
  assert_eq(replay.to_json(), first.to_json())
  let changed = vote_for(replay, "private-voter-one", b, "change")
  assert_true(
    voting_projection(changed, config, 1110UL, Some("private-voter-one"))
    is { "my_entry_id": String(selected), "total_votes": Number(1, ..), .. } &&
    selected == b,
  )
  let cancelled = transition(
    changed,
    config,
    "cancel-vote",
    { "intent": "cancel" },
    1110UL,
    "private-voter-one",
    false,
  )
  assert_true(
    voting_projection(cancelled, config, 1110UL, None)
    is { "total_votes": Number(0, ..), .. },
  )
  assert_eq(
    vote_for(cancelled, "private-voter-one", a, "private-intent-one").to_json(),
    cancelled.to_json(),
  )
  assert_true(
    try {
      ignore(vote_for(changed, "private-voter-one", b, "private-intent-one"))
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  for operator in [true, false] {
    let projection = snapshot(changed, config, 1110UL, None, operator).stringify()
    assert_false(projection.contains("private-voter-one"))
    assert_false(projection.contains("private-intent-one"))
    assert_false(projection.contains("private-prompt-"))
  }
}

///|
test "vote windows self-vote frozen roster and shared tie ranks are enforced" {
  let config = builtin_config()
  let state = voting_works()
  let a = work_id(state, "creator-a")
  let b = work_id(state, "creator-b")
  assert_true(
    try {
      ignore(
        transition(
          state,
          config,
          "vote",
          { "entry_id": a, "intent": "early" },
          1099UL,
          "visitor",
          false,
        ),
      )
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  let frozen = advance_voting(state, config, 1100UL)
  assert_eq(advance_voting(frozen, config, 1101UL).to_json(), frozen.to_json())
  assert_true(
    try {
      ignore(vote_for(frozen, "creator-a", a, "self"))
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  assert_true(
    try {
      ignore(vote_for(frozen, "visitor", hash("absent"), "unknown"))
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  let tied = vote_for(
    vote_for(frozen, "visitor-one", a, "a"),
    "visitor-two",
    b,
    "b",
  )
  let rows = live_counts(tied, tied.voting_rosters[0])
  assert_eq(rows.map(row => row.rank), [1, 1, 3])
  assert_eq(rows.map(row => row.votes), [1, 1, 0])
  assert_true(
    try {
      ignore(
        transition(
          tied,
          config,
          "vote",
          { "entry_id": a, "intent": "late" },
          1200UL,
          "visitor-three",
          false,
        ),
      )
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  assert_true(
    try {
      validate_voting_state(tied, { ..config, voting_closes_ms: 1201UL, })
      false
    } catch {
      Unavailable => true
      _ => false
    },
  )
  assert_true(
    try {
      validate_voting_state(tied, fixture_config())
      false
    } catch {
      Unavailable => true
      _ => false
    },
  )
}

///|
test "withdrawals exclude open votes and later privacy changes do not rewrite settlement" {
  let config = builtin_config()
  let frozen = advance_voting(voting_works(), config, 1100UL)
  let a = work_id(frozen, "creator-a")
  let b = work_id(frozen, "creator-b")
  let voted = vote_for(frozen, "visitor", a, "first")
  let withdrawn = transition(
    voted,
    config,
    "withdraw",
    { "entry_id": a },
    1111UL,
    "creator-a",
    false,
  )
  assert_true(
    voting_projection(withdrawn, config, 1111UL, Some("visitor"))
    is { "my_entry_id": String(""), "total_votes": Number(0, ..), .. },
  )
  let changed = vote_for(withdrawn, "visitor", b, "new")
  let closed = advance_voting(changed, config, 1200UL)
  assert_true(
    try {
      ignore(vote_for(closed, "late-delayed-visitor", b, "stale-receipt"))
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  assert_true(
    voting_projection(closed, config, 1110UL, Some("visitor"))
    is { "phase": String("closed"), "can_vote": False, .. },
  )
  let digest = closed.voting_settlements[0].digest
  let version = closed.voting_settlements[0].version
  assert_eq(closed.voting_settlements[0].total_votes, 1)
  let private = transition(
    closed,
    config,
    "withdraw",
    { "entry_id": b },
    1250UL,
    "creator-b",
    false,
  )
  let after = advance_voting(private, config, 1500UL)
  assert_eq(after.voting_settlements[0].digest, digest)
  assert_eq(after.voting_settlements[0].version, version)
  assert_eq(after.voting_settlements[0].total_votes, 1)
  let exported = settlement_export(after, config).stringify()
  assert_false(exported.contains("art-creator-b"))
  assert_false(exported.contains("name-creator-b"))
  assert_false(exported.contains("visitor"))
  assert_false(exported.contains("private-prompt"))
  assert_true(exported.contains(digest))
  validate_voting_state(after, config)
  let decoded : State = @json.from_json(after.to_json())
  assert_eq(decoded.to_json(), after.to_json())
}

///|
test "a delayed request cannot approve or append a vote after a durable freeze" {
  let config = builtin_config()
  let state = completed(
    transition(
      voting_works(),
      config,
      "generate",
      { "prompt": "last", "intent": "one" },
      500UL,
      "creator-d",
      false,
    ),
  )
  let job = state.generations
    .iter()
    .find_first(job => job.actor == "creator-d")
    .unwrap()
  let submitted = transition(
    state,
    config,
    "submit",
    {
      "generation_id": job.id,
      "title": "late",
      "display_name": "late",
      "consent": true,
    },
    500UL,
    "creator-d",
    false,
  )
  let frozen = advance_voting(submitted, config, 1100UL)
  let id = work_id(frozen, "creator-d")
  assert_eq(frozen.voting_rosters[0].rows.length(), 3)
  assert_true(
    try {
      ignore(
        transition(
          frozen,
          config,
          "approve",
          { "entry_id": id },
          500UL,
          "host",
          true,
        ),
      )
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  assert_true(
    try {
      ignore(
        transition(
          frozen,
          config,
          "generate",
          { "prompt": "stale", "intent": "two" },
          500UL,
          "creator-d",
          false,
        ),
      )
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
}

///|
test "only the host can disqualify approved work and its live votes stop counting" {
  let config = builtin_config()
  let state = advance_voting(voting_works(), config, 1100UL)
  let id = work_id(state, "creator-a")
  let voted = vote_for(state, "visitor", id, "one")
  assert_true(
    try {
      ignore(
        transition(
          voted,
          config,
          "disqualify",
          { "entry_id": id, "reason": "not host" },
          1111UL,
          "visitor",
          false,
        ),
      )
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  assert_true(
    try {
      ignore(
        transition(
          voted,
          config,
          "disqualify",
          { "entry_id": id, "reason": "" },
          1111UL,
          "host",
          true,
        ),
      )
      false
    } catch {
      Invalid(_) => true
      _ => false
    },
  )
  let removed = transition(
    voted,
    config,
    "disqualify",
    { "entry_id": id, "reason": "素材授权未通过核对" },
    1111UL,
    "host",
    true,
  )
  assert_true(
    voting_projection(removed, config, 1111UL, None)
    is { "total_votes": Number(0, ..), .. },
  )
  assert_eq(
    removed.entries.iter().find_first(entry => entry.id == id).unwrap().state,
    "disqualified",
  )
  assert_eq(removed.review_events.length(), voted.review_events.length() + 1)
  let audit = removed.review_events.last().unwrap()
  assert_eq(audit.action, "disqualify")
  assert_eq(audit.previous_state, "approved")
  assert_eq(audit.resulting_state, "disqualified")
  assert_eq(audit.actor, "host")
  assert_eq(audit.reason, "素材授权未通过核对")
  assert_false(
    snapshot(removed, config, 1111UL, None, false)
    .stringify()
    .contains("art-creator-a"),
  )
}

///|
async test "legacy state migration and real concurrent callers retain a single durable tally" {
  let root = @fs.tmpdir(prefix="builtin-votes-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  let config_path = root + "/config.json"
  // Real lock/disk scheduling must not accidentally cross a 90ms fixture window.
  let config = {
    ..builtin_config(),
    voting_closes_ms: 120000UL,
    awards_ms: 130000UL,
  }
  @fs.write_file(
    config_path,
    fixture_config_json(config).stringify(),
    create_mode=CreateOrTruncate,
  )
  let state = voting_works()
  guard state.to_json() is Object(legacy) else { fail("invalid fixture") }
  for
    key in [
      "vote_events", "voting_rosters", "voting_settlements", "review_events",
    ] {
    ignore(legacy.remove(key))
  }
  @fs.write_file(
    path,
    Json::object(legacy).stringify(),
    create_mode=CreateOrTruncate,
  )
  let migrated = read(path, config)
  assert_true(migrated.vote_events.is_empty())
  let id = work_id(state, "creator-a")
  @async.with_task_group(group => {
    let tasks = [
      for i in 0..<24 => {
        let actor = "voter-" + i.to_string()
        group.spawn(() => {
          execute(
            "vote",
            { "entry_id": id, "intent": "one" },
            1110UL,
            Some(actor),
            false,
            path,
            config_path,
          )
        })
      }
    ]
    for task in tasks {
      ignore(task.wait())
    }
  })
  let counted = read(path, config)
  assert_eq(counted.vote_events.length(), 24)
  assert_true(
    execute("snapshot", {}, 1110UL, None, false, path, config_path)
    is { "voting": { "total_votes": Number(24, ..), .. }, .. },
  )
  assert_true(
    try {
      ignore(
        execute(
          "settlement",
          {},
          120000UL,
          Some("visitor"),
          false,
          path,
          config_path,
        ),
      )
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  let exported = execute(
    "settlement",
    {},
    120000UL,
    Some("host"),
    true,
    path,
    config_path,
  )
  assert_true(
    exported is { "settlement": { "total_votes": Number(24, ..), .. }, .. },
  )
  let before = read(path, config)
  assert_eq(
    execute("settlement", {}, 130000UL, Some("host"), true, path, config_path),
    exported,
  )
  assert_eq(read(path, config).to_json(), before.to_json())
}

///|
async test "paused workers seal voting without dispatching a queued image" {
  let root = @fs.tmpdir(prefix="paused-voting-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  let config_path = root + "/config.json"
  let config = builtin_config()
  @fs.write_file(
    config_path,
    fixture_config_json(config).stringify(),
    create_mode=CreateOrTruncate,
  )
  save(path, voting_works())
  assert_false(process_next(path, config_path, allow_generation=false))
  assert_eq(read(path, config).voting_settlements.length(), 1)
  let now = @env.now()
  let future = {
    ..config,
    brief: { ..config.brief, deadline_ms: now + 100000UL, },
    opens_ms: now - 1000UL,
    voting_opens_ms: now + 100001UL,
    voting_closes_ms: now + 100002UL,
    awards_ms: now + 100003UL,
  }
  @fs.write_file(
    config_path,
    fixture_config_json(future).stringify(),
    create_mode=CreateOrTruncate,
  )
  let queued = transition(
    empty(future),
    future,
    "generate",
    { "prompt": "stay queued", "intent": "one" },
    now,
    "alice",
    false,
  )
  save(path, queued)
  assert_false(process_next(path, config_path, allow_generation=false))
  assert_eq(read(path, future).generations[0].state, "queued")
}

///|
async test "a vote blocked across closing seals first without an existing boundary marker" {
  let root = @fs.tmpdir(prefix="blocked-vote-close-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  let config_path = root + "/config.json"
  let config = builtin_config()
  @fs.write_file(
    config_path,
    fixture_config_json(config).stringify(),
    create_mode=CreateOrTruncate,
  )
  let state = voting_works()
  save(path, state)
  let id = work_id(state, "creator-a")
  let file = lock(path)
  defer file.close()
  let started = Ref(false)
  let finished = Ref(false)
  @async.with_task_group(group => {
    let vote = group.spawn(() => {
      started.val = true
      let denied = try {
        ignore(
          execute(
            "vote",
            { "entry_id": id, "intent": "blocked" },
            1150UL,
            Some("visitor"),
            false,
            path,
            config_path,
          ),
        )
        false
      } catch {
        Conflict(_) => true
        _ => false
      }
      finished.val = true
      denied
    })
    while !started.val {
      @async.sleep(1)
    }
    @async.sleep(100)
    assert_false(finished.val)
    let waiting = read(path, config)
    assert_true(waiting.voting_rosters.is_empty())
    assert_true(waiting.voting_settlements.is_empty())
    file.unlock()
    assert_true(vote.wait())
  })
  let sealed = read(path, config)
  assert_true(sealed.vote_events.is_empty())
  assert_eq(sealed.voting_rosters.length(), 1)
  assert_eq(sealed.voting_settlements.length(), 1)
}

///|
async test "a paused worker waiting across close uses time after its file lock" {
  let root = @fs.tmpdir(prefix="blocked-worker-close-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  let config_path = root + "/config.json"
  let state = voting_works()
  save(path, state)
  let file = lock(path)
  defer file.close()
  let now = @env.now()
  let config = {
    ..builtin_config(),
    brief: { ..builtin_config().brief, deadline_ms: now - 2UL, },
    opens_ms: now - 3UL,
    voting_opens_ms: now - 1UL,
    voting_closes_ms: now + 50UL,
    awards_ms: now + 100UL,
    provider_origin: "",
  }
  @fs.write_file(
    config_path,
    fixture_config_json(config).stringify(),
    create_mode=CreateOrTruncate,
  )
  let started = Ref(false)
  let finished = Ref(false)
  @async.with_task_group(group => {
    let worker = group.spawn(() => {
      started.val = true
      let dispatched = process_next(path, config_path, allow_generation=false)
      finished.val = true
      dispatched
    })
    while !started.val {
      @async.sleep(1)
    }
    @async.sleep(100)
    assert_false(finished.val)
    assert_true(read(path, config).voting_settlements.is_empty())
    file.unlock()
    assert_false(worker.wait())
  })
  assert_eq(read(path, config).voting_settlements.length(), 1)
}
