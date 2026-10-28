///|
fn neighborhood_manage_replace(
  model : Model,
  state : NeighborhoodManageState,
) -> (Cmd, Model) {
  (@rabbita.none, { ..model, neighborhood_manage: state, })
}

///|
fn neighborhood_manage_notice(model : Model, notice : String) -> (Cmd, Model) {
  neighborhood_manage_replace(model, { ..model.neighborhood_manage, notice, })
}

///|
fn neighborhood_manage_send(
  dispatch : Dispatch[Msg],
  model : Model,
  action : String,
  payload : Json,
) -> (Cmd, Model) {
  update_neighborhood(
    dispatch,
    {
      ..model,
      neighborhood_manage: {
        ..model.neighborhood_manage,
        confirmation: None,
        notice: "",
      },
    },
    Action(action, payload),
  )
}

///|
fn neighborhood_manage_story_from(story : Json) -> NeighborhoodStoryForm {
  {
    id: neighborhood_text(story, "id"),
    title: neighborhood_text(story, "title"),
    author_name: neighborhood_text(story, "author_name"),
    body: neighborhood_text(story, "body"),
    consent: false,
    consent_revision: 0,
  }
}

///|
fn neighborhood_manage_event_from(event : Json) -> NeighborhoodEventForm {
  {
    id: neighborhood_text(event, "id"),
    title: neighborhood_text(event, "title"),
    description: neighborhood_text(event, "description"),
    location: neighborhood_text(event, "location"),
    starts: neighborhood_manage_local_time(
      neighborhood_manage_number(event, "starts_ms"),
    ),
    ends: neighborhood_manage_local_time(
      neighborhood_manage_number(event, "ends_ms"),
    ),
    capacity: neighborhood_manage_number(event, "capacity").to_int().to_string(),
  }
}

///|
fn update_neighborhood_manage(
  dispatch : Dispatch[Msg],
  model : Model,
  message : NeighborhoodManageMsg,
) -> (Cmd, Model) {
  guard neighborhood_mine(model) is Some(mine) else {
    return neighborhood_manage_notice(
      model, "请先登录并读取自己的街区记录。",
    )
  }
  if neighborhood_busy(model) {
    return (@rabbita.none, model)
  }
  let state = model.neighborhood_manage
  let clean = { ..state, notice: "", }
  match message {
    Section(section) =>
      neighborhood_manage_replace(model, {
        ..clean,
        section,
        confirmation: None,
      })
    NewStory | EditStory(_) => {
      if state.story is Some(form) &&
        neighborhood_manage_story_dirty(form, mine) {
        return neighborhood_manage_notice(
          model, "先保存当前故事，或选择放弃修改，再打开另一份。",
        )
      }
      let form = match message {
        EditStory(id) => {
          guard neighborhood_manage_find(mine, "stories", id) is Some(story) else {
            return neighborhood_manage_notice(
              model, "故事不在你的记录中，请刷新后重试。",
            )
          }
          neighborhood_manage_story_from(story)
        }
        _ =>
          {
            id: neighborhood_manage_new_id("story"),
            title: "",
            author_name: "",
            body: "",
            consent: false,
            consent_revision: 0,
          }
      }
      neighborhood_manage_replace(model, {
        ..clean,
        section: ManageStories,
        story: Some(form),
        confirmation: None,
      })
    }
    StoryField(key, value) => {
      guard state.story is Some(form) else { return (@rabbita.none, model) }
      let next = match key {
        "title" => { ..form, title: value, consent: false, }
        "author_name" => { ..form, author_name: value, consent: false, }
        "body" => { ..form, body: value, consent: false, }
        _ => form
      }
      neighborhood_manage_replace(model, { ..clean, story: Some(next), })
    }
    StoryConsent(consent) => {
      guard state.story is Some(form) else { return (@rabbita.none, model) }
      let revision = neighborhood_manage_find(mine, "stories", form.id)
        .map(story => neighborhood_number(story, "content_revision"))
        .unwrap_or(0)
      if consent &&
        (revision <= 0 || !neighborhood_manage_story_saved(form, mine)) {
        return neighborhood_manage_notice(
          model, "请先保存并刷新这份内容，再确认公开。",
        )
      }
      neighborhood_manage_replace(model, {
        ..clean,
        story: Some({
          ..form,
          consent,
          consent_revision: if consent {
            revision
          } else {
            0
          },
        }),
      })
    }
    SaveStory => {
      guard state.story is Some(form) else { return (@rabbita.none, model) }
      let error = neighborhood_manage_story_error(form)
      if !error.is_empty() {
        return neighborhood_manage_notice(model, error)
      }
      if neighborhood_manage_find(mine, "stories", form.id) is Some(story) &&
        neighborhood_text(story, "state") == "published" {
        return neighborhood_manage_notice(
          model, "先撤下公开故事，再编辑内容。",
        )
      }
      neighborhood_manage_send(dispatch, model, "save-story", {
        "id": form.id,
        "title": form.title,
        "author_name": form.author_name,
        "body": form.body,
      })
    }
    PublishStory => {
      guard state.story is Some(form) else { return (@rabbita.none, model) }
      if !form.consent || !neighborhood_manage_story_saved(form, mine) {
        return neighborhood_manage_notice(
          model, "先保存这份内容，再确认同意公开。",
        )
      }
      let revision = neighborhood_manage_find(mine, "stories", form.id)
        .map(story => neighborhood_number(story, "content_revision"))
        .unwrap_or(0)
      if revision <= 0 || form.consent_revision != revision {
        return neighborhood_manage_replace(model, {
          ..neighborhood_manage_revoke_consent(state),
          notice: "故事版本已变化，请刷新核对内容后重新确认公开。",
        })
      }
      neighborhood_manage_send(dispatch, model, "publish-story", {
        "story_id": form.id,
        "consent": true,
        "expected_content_revision": form.consent_revision,
      })
    }
    NewEvent | EditEvent(_) => {
      if state.event is Some(form) &&
        neighborhood_manage_event_dirty(form, mine) {
        return neighborhood_manage_notice(
          model, "先保存当前活动，或选择放弃修改，再打开另一项。",
        )
      }
      let form = match message {
        EditEvent(id) => {
          guard neighborhood_manage_find(mine, "events", id) is Some(event) else {
            return neighborhood_manage_notice(
              model, "活动不在你的主办记录中，请刷新后重试。",
            )
          }
          neighborhood_manage_event_from(event)
        }
        _ => {
          if !neighborhood_can_host(model) {
            return neighborhood_manage_notice(
              model, "当前账户没有创建活动的权限。",
            )
          }
          {
            id: neighborhood_manage_new_id("event"),
            title: "",
            description: "",
            location: "",
            starts: "",
            ends: "",
            capacity: "20",
          }
        }
      }
      neighborhood_manage_replace(model, {
        ..clean,
        section: ManageEvents,
        event: Some(form),
        confirmation: None,
        roster_page: 0,
      })
    }
    EventField(key, value) => {
      guard state.event is Some(form) else { return (@rabbita.none, model) }
      let next = match key {
        "title" => { ..form, title: value, }
        "description" => { ..form, description: value, }
        "location" => { ..form, location: value, }
        "starts" => { ..form, starts: value, }
        "ends" => { ..form, ends: value, }
        "capacity" => { ..form, capacity: value, }
        _ => form
      }
      neighborhood_manage_replace(model, { ..clean, event: Some(next), })
    }
    SaveEvent => {
      guard state.event is Some(form) else { return (@rabbita.none, model) }
      let error = neighborhood_manage_event_error(form, browser_now_ms())
      if !error.is_empty() {
        return neighborhood_manage_notice(model, error)
      }
      match neighborhood_manage_find(mine, "events", form.id) {
        Some(event) if neighborhood_text(event, "state") != "draft" =>
          return neighborhood_manage_notice(
            model, "只有未发布的活动草稿可以修改。",
          )
        None if !neighborhood_can_host(model) =>
          return neighborhood_manage_notice(
            model, "当前账户没有创建活动的权限。",
          )
        _ => ()
      }
      let capacity = @string.parse_int(form.capacity.trim().to_owned()) catch {
        _ => 0
      }
      neighborhood_manage_send(dispatch, model, "save-event", {
        "id": form.id,
        "title": form.title,
        "description": form.description,
        "location": form.location,
        "starts_ms": browser_timestamp_ms(form.starts).to_json(),
        "ends_ms": browser_timestamp_ms(form.ends).to_json(),
        "capacity": capacity,
      })
    }
    PublishEvent => {
      guard state.event is Some(form) else { return (@rabbita.none, model) }
      if !neighborhood_manage_event_saved(form, mine) {
        return neighborhood_manage_notice(
          model, "先保存这份活动安排，再发布活动。",
        )
      }
      let revision = neighborhood_manage_find(mine, "events", form.id)
        .map(event => neighborhood_number(event, "content_revision"))
        .unwrap_or(0)
      if revision <= 0 {
        return neighborhood_manage_notice(
          model, "请刷新活动安排，再确认发布。",
        )
      }
      neighborhood_manage_send(dispatch, model, "publish-event", {
        "event_id": form.id,
        "consent": true,
        "expected_content_revision": revision,
      })
    }
    Confirm(action, id) =>
      neighborhood_manage_replace(model, {
        ..clean,
        confirmation: Some((action, id)),
      })
    CancelConfirmation =>
      neighborhood_manage_replace(model, { ..clean, confirmation: None, })
    CommitConfirmation => {
      guard state.confirmation is Some((action, id)) else {
        return (@rabbita.none, model)
      }
      match action {
        "discard-story" =>
          neighborhood_manage_replace(model, {
            ..clean,
            story: None,
            confirmation: None,
          })
        "discard-event" =>
          neighborhood_manage_replace(model, {
            ..clean,
            event: None,
            confirmation: None,
          })
        "withdraw-story" => {
          guard neighborhood_manage_find(mine, "stories", id) is Some(_) else {
            return neighborhood_manage_notice(
              model, "请刷新自己的故事记录。",
            )
          }
          let model = {
            ..model,
            neighborhood_manage: {
              ..state,
              story: state.story.map(form => { ..form, consent: false, }),
            },
          }
          neighborhood_manage_send(dispatch, model, action, { "story_id": id })
        }
        "cancel-event" | "end-event" => {
          guard neighborhood_manage_find(mine, "events", id) is Some(_) else {
            return neighborhood_manage_notice(
              model, "请刷新自己的主办记录。",
            )
          }
          neighborhood_manage_send(dispatch, model, action, { "event_id": id })
        }
        _ =>
          neighborhood_manage_notice(
            model, "这项操作不可用，请返回原记录重试。",
          )
      }
    }
    CheckIn(id) => {
      let allowed = neighborhood_items(mine, "events").any(event => {
        neighborhood_items(event, "registrations").any(registration => {
          neighborhood_text(registration, "id") == id &&
          neighborhood_manage_can_check_in(
            event,
            registration,
            browser_now_ms(),
          )
        })
      })
      if !allowed {
        return neighborhood_manage_notice(
          model, "仅活动进行期间，可为已确认的报名者签到。",
        )
      }
      neighborhood_manage_send(dispatch, model, "check-in", {
        "registration_id": id,
      })
    }
    RosterPage(page) =>
      neighborhood_manage_replace(model, { ..clean, roster_page: page.max(0), })
    FollowupField(id, key, value) => {
      if !["next_step", "outcome"].contains(key) {
        return (@rabbita.none, model)
      }
      let fields = state.followup_fields.copy()
      fields[id + ":" + key] = value
      neighborhood_manage_replace(model, { ..clean, followup_fields: fields, })
    }
    ResolveFollowup(id) => {
      guard neighborhood_manage_followup(mine, id) is Some(_) else {
        return neighborhood_manage_notice(
          model, "这不是你的主办跟进记录。",
        )
      }
      let next_step = state.followup_fields.get(id + ":next_step").unwrap_or("")
      let outcome = state.followup_fields.get(id + ":outcome").unwrap_or("")
      if next_step.is_blank() {
        return neighborhood_manage_notice(
          model, "请写明准备如何回应这项自愿跟进。",
        )
      }
      if next_step.length() > 5000 || outcome.length() > 5000 {
        return neighborhood_manage_notice(
          model, "下一步和回应各不超过 5000 字，请精简后再保存。",
        )
      }
      neighborhood_manage_send(dispatch, model, "resolve-follow-up", {
        "followup_id": id,
        "next_step": next_step,
        "outcome": outcome,
      })
    }
    ContinueWork(id) => {
      guard neighborhood_manage_followup(mine, id) is Some((event, followup)) else {
        return neighborhood_manage_notice(
          model, "请从自己的主办跟进记录打开工作说明。",
        )
      }
      let context = "活动：" +
        neighborhood_text(event, "title") +
        "\n自愿跟进：" +
        neighborhood_text(followup, "message") +
        "\n已记录的下一步：" +
        neighborhood_text(followup, "next_step") +
        "\n已有回应：" +
        neighborhood_text(followup, "outcome")
      let next = {
        ..model,
        neighborhood_manage: { ..clean, work_context: context, },
      }
      if public_platform_enabled() {
        neighborhood_manage_replace(next, {
          ..next.neighborhood_manage,
          notice: "工作说明已备好，尚未创建任务。请复制说明并进入自己的工作区。",
        })
      } else {
        open_work_workspace(dispatch, next, StandingWatchComposer)
      }
    }
    ClearWorkContext =>
      neighborhood_manage_replace(model, { ..clean, work_context: "", })
  }
}
