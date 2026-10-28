///|
fn field(value : Json, key : String) -> Json {
  match value {
    Object(fields) => fields.get(key).unwrap_or(Json::null())
    _ => Json::null()
  }
}

///|
fn items(value : Json, key : String) -> Array[Json] raise {
  @json.from_json(field(value, key))
}

///|
async fn call(
  path : String,
  operation : String,
  payload : Json,
  actor : String?,
  now~ : UInt64 = 10UL,
  host~ : Bool = false,
) -> Json {
  let response = @neighborhood.execute(
    operation,
    payload,
    now,
    actor,
    path~,
    can_host=host,
  )
  assert_true(response is { "ok": True, .. })
  field(response, "payload")
}

///|
async fn reject(
  path : String,
  operation : String,
  payload : Json,
  actor : String?,
  expected : String,
  now~ : UInt64 = 10UL,
  host~ : Bool = false,
) -> Unit {
  let actual = try {
    ignore(call(path, operation, payload, actor, now~, host~))
    "success"
  } catch {
    @neighborhood.NeighborhoodError::Unauthenticated => "unauthenticated"
    @neighborhood.NeighborhoodError::Forbidden => "forbidden"
    @neighborhood.NeighborhoodError::NotFound => "not-found"
    @neighborhood.NeighborhoodError::InvalidRequest(_) => "invalid"
    @neighborhood.NeighborhoodError::Conflict(_) => "conflict"
    error => raise error
  }
  assert_eq(actual, expected)
}

///|
fn event_draft(id~ : String = "walk", capacity~ : Int32 = 1) -> Json {
  {
    "id": id,
    "title": "River walk",
    "description": "Compare public riverbank observations.",
    "location": "North gate",
    "starts_ms": 1000,
    "ends_ms": 2000,
    "capacity": capacity,
  }
}

///|
async fn published_event(path : String, capacity~ : Int32 = 1) -> Unit {
  let saved = call(
    path,
    "save-event",
    event_draft(capacity~),
    Some("host"),
    host=true,
  )
  let version = field(
    items(field(saved, "mine"), "events")[0],
    "content_revision",
  )
  ignore(
    call(
      path,
      "publish-event",
      {
        "event_id": "walk",
        "consent": true,
        "expected_content_revision": version,
      },
      Some("host"),
      now=20UL,
    ),
  )
}

///|
async test "empty store exposes no invented activity and no private actor" {
  let root = @fs.tmpdir(prefix="neighborhood-empty-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  let public = call(path, "public", {}, Some("logged-in"), host=true)
  assert_eq(items(public, "stories").length(), 0)
  assert_eq(items(public, "events").length(), 0)
  assert_true(field(public, "mine") is Null)
  assert_true(field(public, "revision") is Number(0))
  assert_false(@fs.exists(path))
  reject(path, "mine", {}, None, "unauthenticated")
  let mine = field(call(path, "mine", {}, Some("alice")), "mine")
  assert_true(field(mine, "actor_id") is String("alice"))
  assert_true(field(mine, "can_host") is False)
}

///|
async test "story lifecycle binds owner and publication to explicit consent" {
  let root = @fs.tmpdir(prefix="neighborhood-story-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  reject(
    path,
    "save-story",
    { "title": "Private", "body": "Secret" },
    None,
    "unauthenticated",
  )
  let saved = call(
    path,
    "save-story",
    {
      "id": "note",
      "title": "Private draft",
      "body": "Owner secret draft",
      "author_name": "河畔观察员",
      "owner_id": "bob",
      "state": "published",
    },
    Some("alice"),
  )
  assert_eq(items(saved, "stories").length(), 0)
  assert_eq(items(field(saved, "mine"), "stories").length(), 1)
  let bob = call(path, "mine", {}, Some("bob"))
  assert_false(bob.stringify().contains("Owner secret draft"))
  reject(
    path,
    "publish-story",
    { "story_id": "note", "consent": true },
    Some("bob"),
    "forbidden",
    host=true,
  )
  reject(
    path,
    "publish-story",
    { "story_id": "note" },
    Some("alice"),
    "invalid",
  )
  let published = call(
    path,
    "publish-story",
    { "story_id": "note", "consent": true, "expected_content_revision": 1 },
    Some("alice"),
    now=20UL,
  )
  assert_eq(items(published, "stories").length(), 1)
  assert_true(
    field(items(published, "stories")[0], "author_name")
    is String("河畔观察员"),
  )
  let public = call(path, "public", {}, None)
  assert_false(public.stringify().contains("owner_id"))
  assert_false(public.stringify().contains("alice"))
  reject(
    path,
    "save-story",
    { "id": "note", "title": "Changed", "body": "Changed" },
    Some("alice"),
    "conflict",
  )
  reject(
    path,
    "withdraw-story",
    { "story_id": "note" },
    Some("bob"),
    "forbidden",
  )
  ignore(
    call(
      path,
      "withdraw-story",
      { "story_id": "note" },
      Some("alice"),
      now=30UL,
    ),
  )
  assert_eq(items(call(path, "public", {}, None), "stories").length(), 0)
  let revised = call(
    path,
    "save-story",
    { "id": "note", "title": "Revised", "body": "Needs fresh consent" },
    Some("alice"),
    now=40UL,
  )
  assert_true(
    field(items(field(revised, "mine"), "stories")[0], "state")
    is String("draft"),
  )
  assert_eq(items(revised, "stories").length(), 0)
}

///|
async test "event creation uses trusted hosting capability and exact existing owner" {
  let root = @fs.tmpdir(prefix="neighborhood-owner-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  reject(path, "save-event", event_draft(), Some("alice"), "forbidden")
  let forged = event_draft()
  guard forged is Object(fields) else { fail("fixture") }
  fields["can_host"] = true.to_json()
  fields["owner_id"] = "host".to_json()
  reject(path, "save-event", forged, Some("alice"), "forbidden")
  ignore(call(path, "save-event", event_draft(), Some("host"), host=true))
  reject(
    path,
    "save-event",
    event_draft(),
    Some("other-host"),
    "forbidden",
    host=true,
  )
  reject(
    path,
    "publish-event",
    { "event_id": "walk", "consent": true },
    Some("other-host"),
    "forbidden",
    host=true,
  )
  reject(path, "publish-event", { "event_id": "walk" }, Some("host"), "invalid")
  ignore(call(path, "cancel-event", { "event_id": "walk" }, Some("host")))
  assert_eq(items(call(path, "public", {}, None), "events").length(), 0)
  assert_false(
    call(path, "mine", {}, Some("alice")).stringify().contains("River walk"),
  )
}

///|
async test "invalid event fields and failed mutations leave durable state unchanged" {
  let root = @fs.tmpdir(prefix="neighborhood-invalid-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  published_event(path)
  let original = @fs.read_file(path).text()
  reject(
    path,
    "save-event",
    event_draft(id="bad", capacity=0),
    Some("host"),
    "invalid",
    host=true,
  )
  reject(
    path,
    "save-event",
    event_draft(id="../escape"),
    Some("host"),
    "invalid",
    host=true,
  )
  reject(
    path,
    "save-event",
    event_draft(id="late"),
    Some("host"),
    "invalid",
    now=1001UL,
    host=true,
  )
  reject(
    path,
    "end-event",
    { "event_id": "walk" },
    Some("host"),
    "conflict",
    now=999UL,
  )
  reject(
    path,
    "register",
    { "event_id": "walk", "display_name": "A" },
    Some("alice"),
    "conflict",
    now=2000UL,
  )
  reject(path, "unknown", {}, Some("host"), "invalid")
  assert_eq(@fs.read_file(path).text(), original)
}

///|
async test "capacity waitlist cancellation and re-registration preserve FIFO" {
  let root = @fs.tmpdir(prefix="neighborhood-capacity-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  published_event(path)
  for actor in ["alice", "bob", "cara"] {
    ignore(
      call(
        path,
        "register",
        {
          "event_id": "walk",
          "display_name": actor,
          "contact": actor + "-private",
        },
        Some(actor),
        now=30UL,
      ),
    )
  }
  let a = items(
      field(call(path, "mine", {}, Some("alice")), "mine"),
      "registrations",
    )[0]
  assert_true(field(a, "state") is String("confirmed"))
  let b = items(
      field(call(path, "mine", {}, Some("bob")), "mine"),
      "registrations",
    )[0]
  assert_true(field(b, "state") is String("waitlisted"))
  reject(
    path,
    "cancel-registration",
    { "registration_id": field(a, "id") },
    Some("bob"),
    "forbidden",
  )
  reject(
    path,
    "register",
    { "event_id": "walk", "display_name": "Alice again" },
    Some("alice"),
    "conflict",
  )
  ignore(
    call(
      path,
      "cancel-registration",
      { "registration_id": field(a, "id") },
      Some("alice"),
      now=40UL,
    ),
  )
  assert_true(
    field(
      items(field(call(path, "mine", {}, Some("bob")), "mine"), "registrations")[0],
      "state",
    )
    is String("confirmed"),
  )
  ignore(
    call(
      path,
      "register",
      { "event_id": "walk", "display_name": "Alice returns" },
      Some("alice"),
      now=50UL,
    ),
  )
  ignore(
    call(
      path,
      "cancel-registration",
      { "registration_id": field(b, "id") },
      Some("bob"),
      now=60UL,
    ),
  )
  assert_true(
    field(
      items(
        field(call(path, "mine", {}, Some("cara")), "mine"),
        "registrations",
      )[0],
      "state",
    )
    is String("confirmed"),
  )
  let public = call(path, "public", {}, None)
  assert_true(field(items(public, "events")[0], "confirmed_count") is Number(1))
  assert_true(
    field(items(public, "events")[0], "waitlisted_count") is Number(1),
  )
  assert_false(public.stringify().contains("contact"))
  assert_false(public.stringify().contains("participant_id"))
  assert_false(public.stringify().contains("alice-private"))
  let alice = call(path, "mine", {}, Some("alice"))
  assert_false(alice.stringify().contains("bob-private"))
  assert_false(alice.stringify().contains("cara-private"))
}

///|
async test "organizer check-in and voluntary post-event follow-up form a private lifecycle" {
  let root = @fs.tmpdir(prefix="neighborhood-followup-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  published_event(path)
  let joined = call(
    path,
    "register",
    { "event_id": "walk", "display_name": "Alice", "participant_id": "bob" },
    Some("alice"),
    now=30UL,
  )
  let registration = items(field(joined, "mine"), "registrations")[0]
  assert_true(field(registration, "participant_id") is String("alice"))
  ignore(
    call(
      path,
      "register",
      { "event_id": "walk", "display_name": "Bob" },
      Some("bob"),
      now=31UL,
    ),
  )
  reject(
    path,
    "check-in",
    { "registration_id": field(registration, "id") },
    Some("alice"),
    "forbidden",
    now=1000UL,
  )
  reject(
    path,
    "check-in",
    { "registration_id": field(registration, "id") },
    Some("host"),
    "conflict",
    now=999UL,
  )
  ignore(
    call(
      path,
      "check-in",
      { "registration_id": field(registration, "id") },
      Some("host"),
      now=1000UL,
    ),
  )
  reject(
    path,
    "check-in",
    { "registration_id": field(registration, "id") },
    Some("host"),
    "conflict",
    now=1001UL,
  )
  reject(
    path,
    "cancel-registration",
    { "registration_id": field(registration, "id") },
    Some("alice"),
    "conflict",
    now=1001UL,
  )
  reject(
    path,
    "request-follow-up",
    { "event_id": "walk", "message": "Please contact me", "consent": true },
    Some("alice"),
    "conflict",
    now=1100UL,
  )
  ignore(
    call(path, "end-event", { "event_id": "walk" }, Some("host"), now=1500UL),
  )
  reject(
    path,
    "request-follow-up",
    { "event_id": "walk", "message": "Help", "consent": true },
    Some("bob"),
    "forbidden",
    now=1501UL,
  )
  reject(
    path,
    "request-follow-up",
    {
      "event_id": "walk",
      "message": "Help",
      "consent": true,
      "participant_id": "alice",
    },
    Some("host"),
    "forbidden",
    now=1501UL,
  )
  reject(
    path,
    "request-follow-up",
    { "event_id": "walk", "message": "Help" },
    Some("alice"),
    "invalid",
    now=1501UL,
  )
  let requested = call(
    path,
    "request-follow-up",
    {
      "event_id": "walk",
      "message": "Private follow-up",
      "contact": "private-contact",
      "consent": true,
    },
    Some("alice"),
    now=1501UL,
  )
  let followup = items(field(requested, "mine"), "followups")[0]
  reject(
    path,
    "request-follow-up",
    { "event_id": "walk", "message": "Duplicate", "consent": true },
    Some("alice"),
    "conflict",
    now=1502UL,
  )
  let followup_id = field(followup, "id")
  assert_true(field(followup, "state") is String("open"))
  assert_false(
    call(path, "mine", {}, Some("bob"))
    .stringify()
    .contains("Private follow-up"),
  )
  assert_false(
    call(path, "public", {}, None).stringify().contains("private-contact"),
  )
  reject(
    path,
    "resolve-follow-up",
    { "followup_id": followup_id, "next_step": "Forged" },
    Some("bob"),
    "forbidden",
    now=1600UL,
    host=true,
  )
  reject(
    path,
    "resolve-follow-up",
    { "followup_id": followup_id, "next_step": "" },
    Some("host"),
    "invalid",
    now=1600UL,
  )
  ignore(
    call(
      path,
      "resolve-follow-up",
      {
        "followup_id": followup_id,
        "next_step": "Meet to review observations",
        "outcome": "Organizer acknowledged the request",
      },
      Some("host"),
      now=1600UL,
    ),
  )
  // A fresh execute reloads the durable file; no session cache supplies data.
  let reloaded = call(path, "mine", {}, Some("alice"), now=1700UL)
  let completed = items(field(reloaded, "mine"), "followups")[0]
  assert_true(field(completed, "state") is String("resolved"))
  assert_true(
    field(completed, "next_step") is String("Meet to review observations"),
  )
  assert_true(field(completed, "resolved_ms") is Number(1600))
  let host = field(call(path, "mine", {}, Some("host")), "mine")
  assert_eq(items(items(host, "events")[0], "registrations").length(), 2)
  assert_eq(items(items(host, "events")[0], "followups").length(), 1)
  assert_true(
    field(items(call(path, "public", {}, None), "events")[0], "state")
    is String("ended"),
  )
}

///|
async test "published cancellation is visible but closes all registrations without promotion" {
  let root = @fs.tmpdir(prefix="neighborhood-cancel-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  published_event(path)
  for actor in ["alice", "bob"] {
    ignore(
      call(
        path,
        "register",
        { "event_id": "walk", "display_name": actor },
        Some(actor),
      ),
    )
  }
  ignore(call(path, "cancel-event", { "event_id": "walk" }, Some("host")))
  for actor in ["alice", "bob"] {
    assert_true(
      field(
        items(
          field(call(path, "mine", {}, Some(actor)), "mine"),
          "registrations",
        )[0],
        "state",
      )
      is String("event_cancelled"),
    )
  }
  let notice = items(call(path, "public", {}, None), "events")[0]
  assert_true(field(notice, "state") is String("cancelled"))
  assert_true(field(notice, "confirmed_count") is Number(0))
  reject(
    path,
    "register",
    { "event_id": "walk", "display_name": "C" },
    Some("cara"),
    "conflict",
  )
}

///|
async test "concurrent applications cannot overbook or lose registrations" {
  let root = @fs.tmpdir(prefix="neighborhood-concurrent-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  published_event(path, capacity=2)
  @async.with_task_group(group => {
    for index in 0..<8 {
      let actor = "participant-\{index}"
      group.spawn_bg(() => {
        ignore(
          call(
            path,
            "register",
            { "event_id": "walk", "display_name": actor },
            Some(actor),
            now=30UL,
          ),
        )
      })
    }
  })
  let public = call(path, "public", {}, None)
  let event = items(public, "events")[0]
  assert_true(field(event, "confirmed_count") is Number(2))
  assert_true(field(event, "waitlisted_count") is Number(6))
  assert_true(field(public, "revision") is Number(10))
  let host = field(call(path, "mine", {}, Some("host")), "mine")
  assert_eq(items(items(host, "events")[0], "registrations").length(), 8)
}

///|
async test "corrupt persistence fails closed instead of replacing data with an empty town" {
  let root = @fs.tmpdir(prefix="neighborhood-corrupt-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  @fs.write_file(path, "{broken", create_mode=CreateNew)
  let denied = try {
    ignore(
      call(
        path,
        "save-story",
        { "title": "New", "body": "Content" },
        Some("alice"),
      ),
    )
    false
  } catch {
    _ => true
  }
  assert_true(denied)
  assert_eq(@fs.read_file(path).text(), "{broken")
}

///|
async test "story publication consent is bound to saved content not global store activity" {
  let root = @fs.tmpdir(prefix="neighborhood-story-version-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  let first = call(
    path,
    "save-story",
    { "id": "note", "title": "Version one", "body": "Approved draft" },
    Some("alice"),
  )
  let first_version = field(
    items(field(first, "mine"), "stories")[0],
    "content_revision",
  )
  let changed = call(
    path,
    "save-story",
    {
      "id": "note",
      "title": "Version two",
      "body": "Different unapproved content",
    },
    Some("alice"),
  )
  let changed_version = field(
    items(field(changed, "mine"), "stories")[0],
    "content_revision",
  )
  assert_false(first_version == changed_version)
  let before_rejection = @fs.read_file(path).text()
  reject(
    path,
    "publish-story",
    {
      "story_id": "note",
      "consent": true,
      "expected_content_revision": first_version,
    },
    Some("alice"),
    "conflict",
  )
  assert_eq(@fs.read_file(path).text(), before_rejection)
  assert_eq(items(call(path, "public", {}, None), "stories").length(), 0)
  reject(
    path,
    "publish-story",
    { "story_id": "note", "consent": true },
    Some("alice"),
    "invalid",
  )
  // Unrelated real event activity must not invalidate this story's consent.
  published_event(path)
  ignore(
    call(
      path,
      "register",
      { "event_id": "walk", "display_name": "Bob" },
      Some("bob"),
      now=30UL,
    ),
  )
  let published = call(
    path,
    "publish-story",
    {
      "story_id": "note",
      "consent": true,
      "expected_content_revision": changed_version,
    },
    Some("alice"),
    now=40UL,
  )
  assert_true(
    field(items(published, "stories")[0], "body")
    is String("Different unapproved content"),
  )
  assert_eq(
    field(items(published, "stories")[0], "content_revision"),
    changed_version,
  )
}

///|
async test "event publication rejects stale consent even when two saves have the same timestamp" {
  let root = @fs.tmpdir(prefix="neighborhood-event-version-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  ignore(
    call(path, "save-event", event_draft(capacity=1), Some("host"), host=true),
  )
  ignore(call(path, "save-event", event_draft(capacity=2), Some("host")))
  let before_rejection = @fs.read_file(path).text()
  reject(
    path,
    "publish-event",
    { "event_id": "walk", "consent": true, "expected_content_revision": 1 },
    Some("host"),
    "conflict",
  )
  assert_eq(@fs.read_file(path).text(), before_rejection)
  assert_eq(items(call(path, "public", {}, None), "events").length(), 0)
  let published = call(
    path,
    "publish-event",
    { "event_id": "walk", "consent": true, "expected_content_revision": 2 },
    Some("host"),
  )
  assert_true(field(items(published, "events")[0], "capacity") is Number(2))
  assert_true(
    field(items(published, "events")[0], "content_revision") is Number(2),
  )
}
