///|
/// A presentation preset, never a second world or a new road registration.
fn street_living_room_requested(view : String, review : Bool) -> Bool {
  view == "living-room" || (view != "town" && view != "overview" && !review)
}

///|
fn initial_street_living_room() -> Bool {
  street_living_room_requested(
    current_browser_query_param("view"),
    [
      "road-trial", "scene", "landmarks", "building-bearing", "layer", "area", "panel",
    ].any(key => !current_browser_query_param(key).is_empty()) ||
    town_design_registration_review_requested() ||
    browser_handoff_requested(),
  )
}

///|
/// Frame the registered landmark, not an independently positioned illustration.
fn prepare_street_living_room_camera(arriving : Bool) -> Unit {
  town_landmarks_init()
  match town_landmark_find("center") {
    Some(center) =>
      street_living_room_camera(arriving, center.origin.x, center.origin.y)
    None => ()
  }
}

///|
/// Browser viewport transport only. World projection, bearing and model stay
/// unchanged. The overview retains its original fit/pan/zoom behavior.
extern "js" fn street_living_room_camera(
  arriving : Bool,
  world_x : Double,
  world_y : Double,
) -> Unit =
  #| (arriving, worldX, worldY) => {
  #|   const canvas = globalThis.document?.getElementById('energy-valley-canvas');
  #|   if (!canvas) return;
  #|   const camera = globalThis.__moontownGoldenValleyCamera ||= {x:1792, y:3200, z:0.42};
  #|   if (!arriving) {
  #|     if (camera.livingRoom) {
  #|       camera.x = 1792; camera.y = 3200;
  #|       camera.gentleTrialFramed = false;
  #|       camera.livingRoom = false;
  #|       delete camera.livingRoomSize;
  #|     }
  #|     canvas.dataset.townView = 'overview';
  #|     return;
  #|   }
  #|   const w = canvas.clientWidth || 1280, h = canvas.clientHeight || 720;
  #|   const stamp = `${w}:${h}`;
  #|   if (!camera.livingRoom || camera.livingRoomSize !== stamp) {
  #|     const mobile = w < 700;
  #|     camera.z = mobile ? 1.22 : Math.min(2.4, Math.max(1.5, w / 640));
  #|     camera.x = (worldX-worldY)*32 - (mobile ? 0 : w*0.12)/camera.z;
  #|     camera.y = (worldX+worldY)*16 - (mobile ? h*0.14 : h*0.15)/camera.z;
  #|     camera.livingRoom = true;
  #|     camera.livingRoomSize = stamp;
  #|   }
  #|   camera.gentleTrialFramed = true;
  #|   canvas.dataset.townView = 'living-room';
  #| }

///|
/// Public-only cards. Never use `mine`, drafts, attendee counts, or local demo
/// posts as public content. Prefer an upcoming/current event over the archive.
fn street_featured_item(
  state : NeighborhoodState,
  stories : Bool,
  now : Double,
) -> Json? {
  guard state.snapshot is Some(snapshot) else { return None }
  let items = neighborhood_items(
    snapshot,
    if stories {
      "stories"
    } else {
      "events"
    },
  )
  let published = items.filter(item => {
    neighborhood_text(item, "state") == "published"
  })
  if stories {
    return published.get(0)
  }
  let upcoming = published.filter(item => {
    neighborhood_field(item, "ends_ms") is Some(Number(ends)) && ends > now
  })
  if !upcoming.is_empty() {
    upcoming.sort_by((a, b) => {
      let start = fn(item) {
        match neighborhood_field(item, "starts_ms") {
          Some(Number(n)) => n
          _ => 1.0e30
        }
      }
      start(a).compare(start(b))
    })
    upcoming.get(0)
  } else {
    items
    .filter(item => {
      ["published", "ended"].contains(neighborhood_text(item, "state"))
    })
    .get(0)
  }
}

///|
fn render_street_notice(
  dispatch : Dispatch[Msg],
  state : NeighborhoodState,
  stories : Bool,
) -> @rabbita.Html {
  let section = if stories { "stories" } else { "events" }
  let item = street_featured_item(state, stories, browser_now_ms())
  let title = match item {
    Some(item) => neighborhood_text(item, "title")
    None if state.loading => "正在读取…"
    None if !state.error.is_empty() => "暂未连接"
    None =>
      if stories {
        "等你来写第一篇"
      } else {
        "下一场，敬请期待"
      }
  }
  article(
    class="street-notice " + (if stories { "is-story" } else { "is-event" }),
    [
      div(class="street-notice-heading", [
        h2(
          town_ui_label(
            if stories {
              "book"
            } else {
              "clock"
            },
            if stories {
              "邻里故事"
            } else {
              "街区活动"
            },
          ),
        ),
        button(
          class="town-ui-icon-button",
          title="查看全部",
          attrs=@html.Attrs::build().aria_label(
            if stories {
              "查看全部故事"
            } else {
              "查看全部活动"
            },
          ),
          on_click=dispatch(OpenStreetContent(section, "")),
          town_ui_icon("forward"),
        ),
      ]),
      button(
        class="street-notice-content",
        on_click=dispatch(
          OpenStreetContent(
            section,
            item.map(value => neighborhood_text(value, "id")).unwrap_or(""),
          ),
        ),
        [
          span(class="street-notice-title", title),
          match item {
            Some(item) =>
              span(
                class="street-notice-meta",
                if stories {
                  neighborhood_text(item, "author_name")
                } else {
                  neighborhood_event_status(item, browser_now_ms()) +
                  " · " +
                  neighborhood_date_label(
                    neighborhood_field(item, "starts_ms")
                    .unwrap_or(Json::null())
                    .stringify(),
                  )
                },
              )
            None => @html.nothing
          },
        ],
      ),
    ],
  )
}

///|
fn render_street_living_room(
  dispatch : Dispatch[Msg],
  model : Model,
  snapshot : @energy_valley_contract.TownSnapshot,
  view : TownCanvasViewState,
) -> @rabbita.Html {
  div(class="energy-valley-golden street-living-room", [
    div(class="street-scene", [
      render_golden_valley_canvas(dispatch, snapshot, view, living_room=true),
    ]),
    div(
      class="street-atmosphere",
      attrs=@html.Attrs::build().aria_hidden("true"),
      no_children(),
    ),
    header(class="street-header", [
      div(class="street-title", [p("未来中心"), h1("街区客厅")]),
      div(class="street-header-actions", [
        render_public_platform_account(),
        button(
          class="street-button street-overview",
          on_click=dispatch(SetStreetLivingRoom(false)),
          town_ui_label("menu", "总览"),
        ),
      ]),
    ]),
    div(class="street-door", [
      button(
        class="street-button street-door-button",
        on_click=dispatch(OpenReferenceInterior),
        town_ui_label("forward", "进入室内"),
      ),
    ]),
    section(
      class="street-noticeboard",
      attrs=@html.Attrs::build().aria_label("街区公告栏"),
      [
        render_street_notice(dispatch, model.neighborhood, false),
        render_street_notice(dispatch, model.neighborhood, true),
        if !model.neighborhood.error.is_empty() {
          button(
            class="street-retry",
            disabled=model.neighborhood.loading,
            on_click=dispatch(NeighborhoodEvent(Preview)),
            town_ui_label("refresh", "重新连接"),
          )
        } else {
          @html.nothing
        },
      ],
    ),
    @html.footer(class="street-footer", [
      span("场景示意"),
      a(href="https://www.openstreetmap.org/copyright", "© OpenStreetMap"),
    ]),
    render_neighborhood_panel(dispatch, model),
    if model.energy_request_open {
      div(
        class="town-modal-backdrop pointer-events-auto bg-slate-950/60",
        render_energy_valley_request_dialog(dispatch, model),
      )
    } else {
      @html.nothing
    },
    render_energy_valley_handoff_layer(dispatch, model),
    render_imported_outputs_drawer(dispatch, model.imported_outputs),
    render_energy_valley_toast_stack(dispatch, model),
  ])
}
