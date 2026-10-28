///|
fn neighborhood_manage_fixture() -> Model {
  let story : Json = {
    "id": "story-a",
    "title": "河边的故事",
    "author_name": "邻居",
    "body": "保留树荫 <script>",
    "state": "draft",
    "content_revision": 1,
  }
  let event : Json = {
    "id": "event-a",
    "title": "邻里散步",
    "description": "观察街区",
    "location": "河边广场",
    "starts_ms": browser_timestamp_ms("2099-01-01T10:00:00").to_json(),
    "ends_ms": browser_timestamp_ms("2099-01-01T12:00:00").to_json(),
    "capacity": 20,
    "state": "draft",
    "content_revision": 2,
    "registrations": [
      {
        "id": "registration-a",
        "event_id": "event-a",
        "participant_id": "member-a",
        "display_name": "报名者 A",
        "contact": "PRIVATE-ROSTER-CONTACT",
        "state": "confirmed",
      },
    ],
    "followups": [
      {
        "id": "followup-a",
        "event_id": "event-a",
        "participant_id": "member-a",
        "message": "希望继续观察树木",
        "contact": "PRIVATE-FOLLOWUP-CONTACT",
        "state": "open",
        "next_step": "",
        "outcome": "",
      },
    ],
  }
  let mine : Json = {
    "actor_id": "host-a",
    "can_host": true,
    "stories": [story],
    "events": [event],
    "registrations": [],
    "followups": [],
  }
  {
    ..init_model(),
    neighborhood: {
      ..initial_neighborhood_state(),
      open: true,
      actor_id: "host-a",
      mine: Some(mine),
    },
  }
}

///|
test "story publishing requires exact saved content and explicit public consent" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let (_, editing) = update_neighborhood_manage(
    dispatch,
    neighborhood_manage_fixture(),
    EditStory("story-a"),
  )
  let form = editing.neighborhood_manage.story.unwrap()
  assert_false(form.consent)
  assert_true(
    neighborhood_manage_story_saved(form, neighborhood_mine(editing).unwrap()),
  )
  let (_, blocked) = update_neighborhood_manage(dispatch, editing, PublishStory)
  assert_false(blocked.neighborhood.busy)
  assert_true(blocked.neighborhood_manage.notice.contains("同意公开"))
  let (_, agreed) = update_neighborhood_manage(
    dispatch,
    editing,
    StoryConsent(true),
  )
  let (_, publishing) = update_neighborhood_manage(
    dispatch,
    agreed,
    PublishStory,
  )
  assert_true(publishing.neighborhood.busy)
  assert_false(publishing.neighborhood_manage.notice.contains("已发布"))
  let (_, changed) = update_neighborhood_manage(
    dispatch,
    agreed,
    StoryField("author_name", "另一个署名"),
  )
  assert_false(changed.neighborhood_manage.story.unwrap().consent)
  let (_, changed_blocked) = update_neighborhood_manage(
    dispatch,
    changed,
    PublishStory,
  )
  assert_false(changed_blocked.neighborhood.busy)
  let html = disclosure_test_html(render_neighborhood_manage(dispatch, agreed))
  assert_true(html.contains("我有权公开此署名、标题和正文"))
  assert_true(html.contains("任何访客都能查看"))
  assert_true(html.contains("&lt;script&gt;"))
  assert_false(html.contains("<script>"))
}

///|
test "story edits survive switching records and withdrawal requires a separate confirmation" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let (_, editing) = update_neighborhood_manage(
    dispatch,
    neighborhood_manage_fixture(),
    EditStory("story-a"),
  )
  let (_, changed) = update_neighborhood_manage(
    dispatch,
    editing,
    StoryField("body", "尚未保存的内容"),
  )
  let (_, blocked) = update_neighborhood_manage(dispatch, changed, NewStory)
  assert_eq(
    blocked.neighborhood_manage.story.unwrap().body,
    "尚未保存的内容",
  )
  assert_false(blocked.neighborhood.busy)
  let (_, confirmation) = update_neighborhood_manage(
    dispatch,
    editing,
    Confirm("withdraw-story", "story-a"),
  )
  assert_false(confirmation.neighborhood.busy)
  assert_true(confirmation.neighborhood_manage.confirmation is Some(_))
  let (_, cancelled) = update_neighborhood_manage(
    dispatch,
    confirmation,
    CancelConfirmation,
  )
  assert_false(cancelled.neighborhood.busy)
  assert_true(cancelled.neighborhood_manage.confirmation is None)
}

///|
test "event creation uses server capability and publishing has one explicit action" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let ordinary = {
    ..neighborhood_manage_fixture(),
    neighborhood: {
      ..initial_neighborhood_state(),
      open: true,
      actor_id: "member",
      mine: Some({
        "actor_id": "member",
        "can_host": false,
        "stories": [],
        "events": [],
        "registrations": [],
        "followups": [],
      }),
    },
  }
  let (_, denied) = update_neighborhood_manage(dispatch, ordinary, NewEvent)
  assert_true(denied.neighborhood_manage.event is None)
  assert_false(denied.neighborhood.busy)
  let html = disclosure_test_html(
    render_neighborhood_manage(dispatch, ordinary),
  )
  assert_false(html.contains("主办活动"))
  assert_false(html.contains("会后跟进"))
  assert_true(html.contains("写故事"))
  let (_, editing) = update_neighborhood_manage(
    dispatch,
    neighborhood_manage_fixture(),
    EditEvent("event-a"),
  )
  assert_true(
    neighborhood_manage_event_saved(
      editing.neighborhood_manage.event.unwrap(),
      neighborhood_mine(editing).unwrap(),
    ),
  )
  let event_html = disclosure_test_html(
    render_neighborhood_manage(dispatch, editing),
  )
  assert_true(event_html.contains("发布活动"))
  assert_false(event_html.contains("type=\"checkbox\""))
  assert_true(event_html.contains("名单和联系方式仅你可见"))
  let (_, publishing) = update_neighborhood_manage(
    dispatch,
    editing,
    PublishEvent,
  )
  assert_true(publishing.neighborhood.busy)
}

///|
test "event validation and checkin distinguish real time state and confirmed attendance" {
  let event : Json = {
    "state": "published",
    "starts_ms": 1000,
    "ends_ms": 2000,
  }
  let confirmed : Json = { "state": "confirmed" }
  assert_false(neighborhood_manage_can_check_in(event, confirmed, 999.0))
  assert_true(neighborhood_manage_can_check_in(event, confirmed, 1000.0))
  assert_true(neighborhood_manage_can_check_in(event, confirmed, 2000.0))
  assert_false(neighborhood_manage_can_check_in(event, confirmed, 2001.0))
  assert_false(
    neighborhood_manage_can_check_in(event, { "state": "waitlisted" }, 1500.0),
  )
  assert_false(
    neighborhood_manage_can_check_in(
      { "state": "ended", "starts_ms": 1000, "ends_ms": 2000 },
      confirmed,
      1500.0,
    ),
  )
  let form : NeighborhoodEventForm = {
    id: "event",
    title: "活动",
    description: "说明",
    location: "广场",
    starts: "2099-01-01T10:00:00",
    ends: "2099-01-01T11:00:00",
    capacity: "20",
  }
  assert_eq(neighborhood_manage_event_error(form, 0.0), "")
  assert_true(
    neighborhood_manage_event_error({ ..form, capacity: "0", }, 0.0).contains(
      "人数",
    ),
  )
  assert_true(
    neighborhood_manage_event_error({ ..form, ends: form.starts, }, 0.0).contains(
      "结束时间",
    ),
  )
}

///|
test "private forms contacts and work context never render without current mine identity" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let (_, host) = update_neighborhood_manage(
    dispatch,
    neighborhood_manage_fixture(),
    EditEvent("event-a"),
  )
  let private_html = disclosure_test_html(
    render_neighborhood_manage(dispatch, host),
  )
  assert_true(private_html.contains("PRIVATE-ROSTER-CONTACT"))
  let no_identity = {
    ..host,
    neighborhood: { ..host.neighborhood, mine: None, actor_id: "", },
    neighborhood_manage: {
      ..host.neighborhood_manage,
      work_context: "PRIVATE-CONTEXT",
    },
  }
  assert_eq(
    disclosure_test_html(render_neighborhood_manage(dispatch, no_identity)),
    "",
  )
  assert_eq(
    disclosure_test_html(
      render_neighborhood_work_context(dispatch, no_identity),
    ),
    "",
  )
  assert_eq(
    disclosure_test_html(
      render_neighborhood_manage_attention(dispatch, no_identity),
    ),
    "",
  )
  let (_, blocked) = update_neighborhood_manage(
    dispatch,
    no_identity,
    PublishEvent,
  )
  assert_false(blocked.neighborhood.busy)
}

///|
test "real followup attention is primary and continuing work neither creates a task nor copies contacts" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let base = neighborhood_manage_fixture()
  let attention = disclosure_test_html(
    render_neighborhood_manage_attention(dispatch, base),
  )
  assert_true(attention.contains("待跟进 1"))
  let (_, followups) = update_neighborhood_manage(
    dispatch,
    base,
    Section(ManageFollowups),
  )
  let html = disclosure_test_html(
    render_neighborhood_manage(dispatch, followups),
  )
  assert_true(html.contains("记录下一步"))
  assert_true(html.contains("报名者 A"))
  assert_false(html.contains("member-a"))
  assert_true(html.contains("不会自动创建任务"))
  let (_, missing) = update_neighborhood_manage(
    dispatch,
    followups,
    ResolveFollowup("followup-a"),
  )
  assert_false(missing.neighborhood.busy)
  let (_, filled) = update_neighborhood_manage(
    dispatch,
    followups,
    FollowupField("followup-a", "next_step", "整理观察问题"),
  )
  let (_, resolving) = update_neighborhood_manage(
    dispatch,
    filled,
    ResolveFollowup("followup-a"),
  )
  assert_true(resolving.neighborhood.busy)
  let authored = {
    ..base,
    collaboration: collaboration_test_state(),
    request_prompt: "已有的工作草稿",
  }
  let (_, continued) = update_neighborhood_manage(
    dispatch,
    authored,
    ContinueWork("followup-a"),
  )
  assert_eq(continued.collaboration.draft, authored.collaboration.draft)
  assert_eq(continued.request_prompt, authored.request_prompt)
  assert_true(
    continued.neighborhood_manage.work_context.contains("邻里散步"),
  )
  assert_true(
    continued.neighborhood_manage.work_context.contains(
      "希望继续观察树木",
    ),
  )
  assert_false(
    continued.neighborhood_manage.work_context.contains(
      "PRIVATE-FOLLOWUP-CONTACT",
    ),
  )
  assert_false(continued.neighborhood.busy)
}

///|
test "publication consent is bound to saved content revision across refreshed snapshots" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let (_, editing) = update_neighborhood_manage(
    dispatch,
    neighborhood_manage_fixture(),
    EditStory("story-a"),
  )
  let (_, agreed) = update_neighborhood_manage(
    dispatch,
    editing,
    StoryConsent(true),
  )
  assert_eq(agreed.neighborhood_manage.story.unwrap().consent_revision, 1)
  let same = neighborhood_manage_reconcile(
    agreed.neighborhood_manage,
    neighborhood_mine(agreed),
  )
  assert_true(same.story.unwrap().consent)
  let changed_mine : Json = {
    "actor_id": "host-a",
    "can_host": true,
    "stories": [
      {
        "id": "story-a",
        "title": "河边的故事",
        "author_name": "邻居",
        "body": "保留树荫 <script>",
        "state": "draft",
        "content_revision": 3,
      },
    ],
    "events": [],
    "registrations": [],
    "followups": [],
  }
  let changed = neighborhood_manage_reconcile(
    agreed.neighborhood_manage,
    Some(changed_mine),
  )
  assert_false(changed.story.unwrap().consent)
  assert_eq(changed.story.unwrap().consent_revision, 0)
  assert_true(changed.notice.contains("重新确认"))
  let stale_model = {
    ..agreed,
    neighborhood: { ..agreed.neighborhood, mine: Some(changed_mine), },
  }
  let (_, blocked) = update_neighborhood_manage(
    dispatch,
    stale_model,
    PublishStory,
  )
  assert_false(blocked.neighborhood.busy)
  assert_false(blocked.neighborhood_manage.story.unwrap().consent)
  let revoked = neighborhood_manage_revoke_consent(agreed.neighborhood_manage)
  assert_false(revoked.story.unwrap().consent)
  assert_eq(
    revoked.story.unwrap().body,
    agreed.neighborhood_manage.story.unwrap().body,
  )
}

///|
test "followup names are joined only to host registration data with no actor id fallback" {
  let event : Json = {
    "registrations": [
      { "participant_id": "private-id-a", "display_name": "甲" },
      { "participant_id": "private-id-b", "display_name": "乙" },
    ],
  }
  assert_eq(
    neighborhood_manage_followup_name(event, {
      "participant_id": "private-id-a",
    }),
    "甲",
  )
  assert_eq(
    neighborhood_manage_followup_name(event, {
      "participant_id": "private-id-b",
    }),
    "乙",
  )
  assert_eq(
    neighborhood_manage_followup_name(event, {
      "participant_id": "private-unmatched-id",
    }),
    "参与者",
  )
  assert_eq(
    neighborhood_manage_followup_name(event, { "participant_id": "" }),
    "参与者",
  )
}
