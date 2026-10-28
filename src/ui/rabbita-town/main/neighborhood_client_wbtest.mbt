///|
fn neighborhood_test_snapshot(
  actor~ : String = "",
  revision~ : Int32 = 1,
) -> Json {
  let mine : Json = if actor.is_empty() {
    Json::null()
  } else {
    {
      "actor_id": actor,
      "can_host": false,
      "stories": [],
      "events": [],
      "registrations": [],
      "followups": [],
    }
  }
  {
    "schema": "moontown.neighborhood.v1",
    "revision": revision,
    "stories": [],
    "events": [],
    "mine": mine,
  }
}

///|
fn neighborhood_test_reply(snapshot : Json, status~ : Int32 = 200) -> String {
  let body : Json = { "ok": true, "operation": "mine", "payload": snapshot }
  let wire : Json = { "status": status, "body": body.stringify() }
  wire.stringify()
}

///|
fn neighborhood_test_error(status : Int32, code : String) -> String {
  let body : Json = { "ok": false, "error": code }
  let wire : Json = { "status": status, "body": body.stringify() }
  wire.stringify()
}

///|
fn neighborhood_test_ready(actor~ : String = "alice") -> NeighborhoodState {
  let state = neighborhood_transition(initial_neighborhood_state(), Open).0
  neighborhood_transition(
    state,
    Loaded(
      state.generation,
      "mine",
      neighborhood_test_reply(neighborhood_test_snapshot(actor~)),
    ),
  ).0
}

///|
test "neighborhood personal replies precede registration history and explanations stay advanced" {
  let mine : Json = {
    "actor_id": "alice",
    "can_host": false,
    "stories": [],
    "events": [],
    "registrations": [],
    "followups": [
      {
        "id": "followup-a",
        "event_id": "event-a",
        "state": "resolved",
        "message": "希望继续交流",
        "next_step": "确认分享时间",
        "outcome": "已记录",
      },
    ],
  }
  let model = {
    ..init_model(),
    neighborhood: { ..neighborhood_test_ready(), mine: Some(mine), },
  }
  let html = disclosure_test_html(
    render_neighborhood_mine(_ => @rabbita.none, model),
  )
  let before_registration = html.split_once("我的报名").unwrap().0.to_string()
  assert_true(before_registration.contains("确认分享时间"))
  assert_true(before_registration.contains("高级 · 回复说明"))
  assert_true(before_registration.contains("<details"))
  assert_false(before_registration.contains(" open"))
}

///|
test "neighborhood uses one shared API from public and private town mounts" {
  assert_eq(
    neighborhood_api_path("/index.html", "public"),
    "/api/neighborhood/public",
  )
  assert_eq(
    neighborhood_api_path("/moontown/", "mine"),
    "/moontown/api/neighborhood/mine",
  )
  assert_eq(
    neighborhood_api_path("/moontown/workspace/index.html", "actions"),
    "/moontown/api/neighborhood/actions",
  )
  assert_eq(
    neighborhood_api_path("/moontown-other/index.html", "public"),
    "/api/neighborhood/public",
  )
}

///|
test "neighborhood starts empty and anonymous reads do not invent content or privilege" {
  let initial = initial_neighborhood_state()
  assert_true(initial.snapshot is None)
  assert_true(initial.mine is None)
  let (opened, request) = neighborhood_transition(initial, Open)
  assert_true(opened.open && opened.loading && opened.mine_loading)
  assert_true(request is Some(Load(1)))
  let public = neighborhood_transition(
      opened,
      Loaded(1, "public", neighborhood_test_reply(neighborhood_test_snapshot())),
    ).0
  let anonymous = neighborhood_transition(
      public,
      Loaded(1, "mine", neighborhood_test_error(401, "unauthenticated")),
    ).0
  assert_false(anonymous.mine_loading)
  assert_true(anonymous.mine is None)
  assert_eq(anonymous.mine_error, "")
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_neighborhood_feed(dispatch, anonymous)),
  )
  assert_true(html.contains("还没有公开活动"))
  assert_false(html.contains("demo"))
}

///|
test "neighborhood refresh removes private projections and rejects stale responses" {
  let ready = { ..neighborhood_test_ready(), contact: "private-contact", }
  let refreshing = neighborhood_transition(ready, Refresh).0
  assert_true(refreshing.mine is None)
  assert_eq(refreshing.actor_id, "alice")
  assert_eq(refreshing.contact, "private-contact")
  let stale = neighborhood_transition(
      refreshing,
      Loaded(
        ready.generation,
        "mine",
        neighborhood_test_reply(neighborhood_test_snapshot(actor="bob")),
      ),
    ).0
  assert_eq(stale.actor_id, "alice")
  assert_true(stale.mine is None)
  let next = neighborhood_transition(
      refreshing,
      Loaded(
        refreshing.generation,
        "mine",
        neighborhood_test_reply(neighborhood_test_snapshot(actor="bob")),
      ),
    ).0
  assert_eq(next.actor_id, "bob")
  assert_eq(next.contact, "")
}

///|
test "neighborhood public response cannot grant private state or roll back newer data" {
  let ready = neighborhood_test_ready()
  let newer = neighborhood_transition(
      ready,
      Loaded(
        ready.generation,
        "mine",
        neighborhood_test_reply(
          neighborhood_test_snapshot(actor="alice", revision=7),
        ),
      ),
    ).0
  let public = neighborhood_transition(
      newer,
      Loaded(
        newer.generation,
        "public",
        neighborhood_test_reply(
          neighborhood_test_snapshot(actor="mallory", revision=1),
        ),
      ),
    ).0
  assert_eq(public.actor_id, "alice")
  assert_eq(neighborhood_number(public.snapshot.unwrap(), "revision"), 7)
  assert_true(
    neighborhood_field(public.snapshot.unwrap(), "mine") is Some(Null),
  )
  assert_eq(neighborhood_text(public.mine.unwrap(), "actor_id"), "alice")
}

///|
test "neighborhood submissions capture identity and prevent duplicate pending clicks" {
  let ready = neighborhood_test_ready()
  let payload : Json = { "event_id": "event-one", "display_name": "Alice" }
  let (pending, request) = neighborhood_transition(
    ready,
    Action("register", payload),
  )
  assert_true(pending.busy)
  assert_true(request is Some(Submit(_, "alice", "register", _)))
  assert_true(
    neighborhood_transition(pending, Action("register", payload)).1 is None,
  )
  assert_true(neighborhood_transition(pending, Refresh).1 is None)
  let reopened = neighborhood_transition(
    neighborhood_transition(pending, Close).0,
    Open,
  )
  assert_true(reopened.0.open && reopened.0.busy)
  assert_true(reopened.1 is None)
  let unknown = neighborhood_transition(
      pending,
      Loaded(pending.generation, "action", ""),
    ).0
  assert_false(unknown.busy)
  assert_true(unknown.mine is Some(_))
  assert_true(unknown.needs_refresh)
  assert_true(unknown.mine_error.contains("勿重复提交"))
  assert_true(
    neighborhood_transition(unknown, Action("register", payload)).1 is None,
  )
}

///|
test "neighborhood validation failure keeps editable fields and does not pretend logout" {
  let state = {
    ..neighborhood_test_ready(),
    display_name: "Alice",
    contact: "own contact",
  }
  let failed = neighborhood_transition(
      state,
      Loaded(
        state.generation,
        "action",
        neighborhood_test_error(400, "invalid_request"),
      ),
    ).0
  assert_true(failed.mine is Some(_))
  assert_eq(failed.contact, "own contact")
  assert_false(failed.needs_refresh)
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let model = {
    ..init_model(),
    neighborhood: state,
    neighborhood_manage: {
      ..initial_neighborhood_manage_state(),
      story: Some({
        id: "story",
        title: "A",
        author_name: "",
        body: "Draft",
        consent: true,
        consent_revision: 1,
      }),
    },
  }
  let (_, conflict) = update_neighborhood(
    dispatch,
    model,
    Loaded(state.generation, "action", neighborhood_test_error(409, "conflict")),
  )
  assert_true(conflict.neighborhood.needs_refresh)
  assert_false(conflict.neighborhood_manage.story.unwrap().consent)
}

///|
test "neighborhood account change and expiry clear private input and management drafts" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let model = {
    ..init_model(),
    neighborhood: {
      ..neighborhood_test_ready(),
      contact: "secret",
      followup_consent: true,
    },
    neighborhood_manage: {
      ..initial_neighborhood_manage_state(),
      work_context: "alice private draft",
    },
  }
  let (_, switched) = update_neighborhood(
    dispatch,
    model,
    Loaded(
      model.neighborhood.generation,
      "action",
      neighborhood_test_error(409, "identity_changed"),
    ),
  )
  assert_eq(switched.neighborhood.actor_id, "")
  assert_eq(switched.neighborhood.contact, "")
  assert_false(switched.neighborhood.followup_consent)
  assert_eq(switched.neighborhood_manage.work_context, "")
  assert_true(switched.neighborhood.mine_error.contains("账户已切换"))
  let (_, expired) = update_neighborhood(
    dispatch,
    model,
    Loaded(
      model.neighborhood.generation,
      "mine",
      neighborhood_test_error(401, "unauthenticated"),
    ),
  )
  assert_true(expired.neighborhood.mine is None)
  assert_eq(expired.neighborhood_manage.work_context, "")
}

///|
test "neighborhood followup needs current explicit consent and never reuses it" {
  let ready = neighborhood_test_ready()
  let payload : Json = {
    "event_id": "event-one",
    "message": "Need help",
    "consent": true,
  }
  assert_true(
    neighborhood_transition(ready, Action("request-follow-up", payload)).1
    is None,
  )
  let consenting = neighborhood_transition(ready, SetFollowupConsent(true)).0
  let (pending, request) = neighborhood_transition(
    consenting,
    Action("request-follow-up", payload),
  )
  assert_true(request is Some(Submit(_, _, "request-follow-up", _)))
  let completed = neighborhood_transition(
      pending,
      Loaded(
        pending.generation,
        "action",
        neighborhood_test_reply(
          neighborhood_test_snapshot(actor="alice", revision=2),
        ),
      ),
    ).0
  assert_false(completed.followup_consent)
  assert_eq(completed.notice, "已保存")
  assert_false(
    neighborhood_transition(consenting, SelectEvent("event-two")).0.followup_consent,
  )
}

///|
test "neighborhood invalid snapshots stay unavailable instead of reporting successful empty feeds" {
  let opened = neighborhood_transition(initial_neighborhood_state(), Open).0
  let broken = neighborhood_transition(
      opened,
      Loaded(
        opened.generation,
        "public",
        neighborhood_test_reply({ "stories": [], "events": [] }),
      ),
    ).0
  assert_true(broken.snapshot is None)
  assert_false(broken.error.is_empty())
  let unavailable = neighborhood_transition(
      opened,
      Loaded(
        opened.generation,
        "public",
        neighborhood_test_error(404, "not_found"),
      ),
    ).0
  assert_false(unavailable.loading)
  assert_true(unavailable.snapshot is None)
}

///|
test "neighborhood close preserves same account unsaved input while closed actions are blocked" {
  let ready = { ..neighborhood_test_ready(), contact: "keep me", }
  let closed = neighborhood_transition(ready, Close).0
  assert_false(closed.open)
  assert_eq(closed.contact, "keep me")
  assert_true(
    neighborhood_transition(closed, Action("save-story", { "title": "hidden" })).1
    is None,
  )
}

///|
test "neighborhood active re-registration wins over an old cancellation" {
  let state = {
    ..neighborhood_test_ready(),
    mine: Some({
      "actor_id": "alice",
      "registrations": [
        { "id": "old", "event_id": "event", "state": "cancelled" },
        { "id": "new", "event_id": "event", "state": "waitlisted" },
      ],
    }),
  }
  assert_eq(
    neighborhood_text(neighborhood_registration(state, "event").unwrap(), "id"),
    "new",
  )
}

///|
test "neighborhood public event badges distinguish scheduled live closed ended and cancelled" {
  let scheduled : Json = {
    "state": "published",
    "starts_ms": 2000,
    "ends_ms": 3000,
  }
  assert_eq(neighborhood_event_status(scheduled, 1000), "报名中")
  assert_eq(neighborhood_event_status(scheduled, 2500), "进行中")
  assert_eq(neighborhood_event_status(scheduled, 3000), "报名截止")
  assert_eq(neighborhood_event_status({ "state": "ended" }, 4000), "已结束")
  assert_eq(
    neighborhood_event_status({ "state": "cancelled" }, 1000),
    "已取消",
  )
}

///|
test "neighborhood story text is escaped and private projections never enter public cards" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let state = {
    ..neighborhood_test_ready(),
    section: "stories",
    snapshot: Some({
      "stories": [
        {
          "id": "story",
          "title": "<script>bad</script>",
          "body": "<img onerror=bad>",
          "author_name": "Neighbor",
        },
      ],
      "events": [],
    }),
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_neighborhood_feed(dispatch, state)),
  )
  assert_true(html.contains("&lt;script&gt;"))
  assert_true(html.contains("Neighbor"))
  assert_false(html.contains("<script>bad"))
  assert_false(html.contains("alice"))
  assert_false(html.contains("actor_id"))
}

///|
test "neighborhood mine login offers an effective refresh and no private management forms" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let model = {
    ..init_model(),
    neighborhood: {
      ..initial_neighborhood_state(),
      open: true,
      section: "mine",
    },
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_neighborhood_panel(dispatch, model)),
  )
  assert_true(html.contains("已登录，刷新"))
  assert_true(html.contains("https://suanli.kechuangfuwu.com:8443/user/"))
  assert_false(html.contains("故事草稿"))
  assert_false(html.contains("neighborhood-manage"))
}
