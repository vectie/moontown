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
fn prepare_street_living_room_camera(
  arriving : Bool,
  overview~ : Bool = false,
) -> Unit {
  town_landmarks_init()
  match town_landmark_find("center") {
    Some(center) => {
      // The south forecourt, not the roof mass, is the arrival focal point.
      let forecourt = town_landmark_at(center, -15.0, 125.0)
      street_living_room_camera(arriving, overview, forecourt.x, forecourt.y)
    }
    None => ()
  }
  frontier_camera_limits(arriving && frontier_requested())
}

///|
/// Browser viewport transport only. World projection, bearing and model stay
/// unchanged. The overview retains its original fit/pan/zoom behavior.
extern "js" fn street_living_room_camera(
  arriving : Bool,
  overview : Bool,
  world_x : Double,
  world_y : Double,
) -> Unit =
  #| (arriving, overview, worldX, worldY) => {
  #|   const canvas = globalThis.document?.getElementById('energy-valley-canvas');
  #|   if (!canvas) return;
  #|   const camera = globalThis.__moontownGoldenValleyCamera ||= {x:1792, y:3200, z:0.42};
  #|   if (!arriving) {
  #|     if (camera.livingRoom) {
  #|       camera.x = 1792; camera.y = 3200;
  #|       camera.gentleTrialFramed = false;
  #|       camera.livingRoom = false;
  #|       delete camera.livingRoomSize;
  #|       delete camera.streetTransition;
  #|       delete camera.streetClose;
  #|     }
  #|     canvas.dataset.townView = 'overview';
  #|     return;
  #|   }
  #|   const w = canvas.clientWidth || 1280, h = canvas.clientHeight || 720;
  #|   const stamp = `${w}:${h}`;
  #|   camera.streetMinZoom = w < 700 ? 1.8 : 2.1;
  #|   if (!camera.livingRoom) {
  #|     const mobile = w < 700;
  #|     camera.z = mobile ? 2.6 : Math.min(3.6, Math.max(2.8, w / 340));
  #|     camera.x = (worldX-worldY)*32;
  #|     camera.y = (worldX+worldY)*16 - h*0.08/camera.z;
  #|     camera.livingRoom = true;
  #|     camera.streetOverview = false;
  #|     camera.streetFollow = true;
  #|   }
  #|   if (overview !== camera.streetOverview) {
  #|     const from = {x:camera.x,y:camera.y,z:camera.z};
  #|     let to;
  #|     if (overview) {
  #|       camera.streetClose = camera.streetTransition?.to || from;
  #|       to = {x:1792,y:3200,z:Math.max(.03,Math.min((w-48)/12800,(h-160)/6400))};
  #|     } else if (camera.streetClose) {
  #|       to = {...camera.streetClose,z:Math.max(camera.streetMinZoom,camera.streetClose.z)};
  #|     }
  #|     camera.streetOverview = overview;
  #|     if (to) camera.streetTransition = {from,to,start:performance.now()};
  #|   }
  #|   if (camera.streetTransition) {
  #|     const t=camera.streetTransition;
  #|     const progress=globalThis.matchMedia?.('(prefers-reduced-motion: reduce)').matches ? 1 : Math.min(1,(performance.now()-t.start)/320);
  #|     const mix=1-Math.pow(1-progress,3);
  #|     camera.x=t.from.x+(t.to.x-t.from.x)*mix;
  #|     camera.y=t.from.y+(t.to.y-t.from.y)*mix;
  #|     camera.z=Math.exp(Math.log(t.from.z)+(Math.log(t.to.z)-Math.log(t.from.z))*mix);
  #|     if(progress===1) { Object.assign(camera,t.to); delete camera.streetTransition; }
  #|   }
  #|   if(!overview && !camera.streetTransition) camera.z=Math.max(camera.streetMinZoom,Math.min(3.6,camera.z));
  #|   camera.livingRoomSize = stamp;
  #|   camera.gentleTrialFramed = true;
  #|   canvas.dataset.townView = overview ? 'street-overview' : 'living-room';
  #|   canvas.dataset.streetZoom=String(camera.z);
  #| }

///|
/// Public-only notices. Never use `mine`, drafts, attendee counts, or local demo
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
  walk~ : Bool = true,
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
  button(
    id=if stories { "street-stories" } else { "street-events" },
    class="street-world-entry",
    title~,
    attrs=@html.Attrs::build().aria_label(
      if stories {
        "邻里故事"
      } else {
        "街区活动"
      },
    ),
    on_click=dispatch(
      if walk {
        StreetVisit(section)
      } else {
        OpenStreetContent(section, "")
      },
    ),
    [
      town_ui_label(
        if stories {
          "book"
        } else {
          "clock"
        },
        if stories {
          "故事"
        } else {
          "活动"
        },
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
  street_courtyard_state(
    model.street_seated,
    model.street_visit,
    model.street_memories.join(","),
  )
  div(class="energy-valley-golden street-living-room", [
    div(class="street-scene", [
      render_golden_valley_canvas(
        dispatch,
        snapshot,
        view,
        living_room=true,
        street_overview=model.street_overview,
      ),
    ]),
    header(class="street-header", [
      h1(
        class=if model.street_overview {
          "street-location street-sr-only"
        } else {
          "street-location"
        },
        town_ui_label(
          "pin",
          if model.street_overview {
            "全镇"
          } else {
            "未来中心"
          },
        ),
      ),
      div(class="street-header-actions", [render_public_platform_account()]),
    ]),
    @html.nav(
      class="street-destinations",
      attrs=@html.Attrs::build().aria_label("街区去处"),
      [
        button(
          id="street-interior",
          class="street-world-entry street-door-button",
          on_click=dispatch(
            if model.street_overview {
              OpenReferenceInterior
            } else {
              StreetVisit("interior")
            },
          ),
          attrs=@html.Attrs::build().aria_label("进入室内"),
          town_ui_label("forward", "室内"),
        ),
        render_street_notice(
          dispatch,
          model.neighborhood,
          false,
          walk=!model.street_overview,
        ),
        render_street_notice(
          dispatch,
          model.neighborhood,
          true,
          walk=!model.street_overview,
        ),
        button(
          id="street-seat",
          class="street-world-entry street-prop-entry",
          title=if model.street_seated { "起身" } else { "坐一会" },
          attrs=@html.Attrs::build().aria_label(
            if model.street_seated {
              "起身"
            } else {
              "坐一会"
            },
          ),
          on_click=dispatch(StreetVisit("seat")),
          town_ui_icon(if model.street_seated { "forward" } else { "seat" }),
        ),
        button(
          id="street-cafe",
          class="street-world-entry street-prop-entry",
          title="去咖啡亭看看",
          attrs=@html.Attrs::build().aria_label("去咖啡亭看看"),
          on_click=dispatch(StreetVisit("cafe")),
          town_ui_icon("coffee"),
        ),
      ],
    ),
    render_street_tools(dispatch, model.street_overview, frontier_requested()),
    @html.footer(class="street-footer", [
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

///|
/// Conventional utilities share one compact dock. Explanations appear only
/// inside the control panel; live walking state remains available to readers.
fn render_street_tools(
  dispatch : Dispatch[Msg],
  overview : Bool,
  experiment : Bool,
) -> @rabbita.Html {
  div(
    class="street-walk-hud",
    attrs=@html.Attrs::build().role("group").aria_label("地图操作"),
    [
      button(
        id="street-overview",
        class="street-button street-tool street-overview",
        title=if overview { "返回街区" } else { "总览" },
        attrs=@html.Attrs::build()
          .aria_label(if overview { "返回街区" } else { "总览" })
          .aria_pressed(if overview { "true" } else { "false" }),
        on_click=dispatch(StreetOverview),
        town_ui_icon(if overview { "back" } else { "menu" }),
      ),
      button(
        class="street-button street-tool street-recenter",
        title="找到我",
        attrs=@html.Attrs::build().aria_label("找到我"),
        on_click=dispatch(StreetRecenter),
        town_ui_icon("pin"),
      ),
      span(
        id="street-walk-status",
        class="street-sr-only",
        attrs=@html.Attrs::build().role("status").aria_live("polite"),
        "",
      ),
      @html.details(class="street-controls", [
        @html.summary(
          title="地图设置",
          attrs=@html.Attrs::build().aria_label("地图设置"),
          town_ui_icon("sliders"),
        ),
        div(class="street-controls-panel", [
          div(class="street-dpad", [
            button(
              on_click=dispatch(StreetStep(-1, -1)),
              attrs=@html.Attrs::build().aria_label("向屏幕上走"),
              "↑",
            ),
            button(
              on_click=dispatch(StreetStep(-1, 1)),
              attrs=@html.Attrs::build().aria_label("向屏幕左走"),
              "←",
            ),
            button(
              on_click=dispatch(StreetStep(1, 1)),
              attrs=@html.Attrs::build().aria_label("向屏幕下走"),
              "↓",
            ),
            button(
              on_click=dispatch(StreetStep(1, -1)),
              attrs=@html.Attrs::build().aria_label("向屏幕右走"),
              "→",
            ),
            span("WASD / 方向键 · 拖动环顾"),
          ]),
          if experiment {
            @html.details(class="frontier-diagnostics", [
              @html.summary("高级"),
              div([
                span("外围生成 · 实验"),
                div(id="frontier-diagnostics", ""),
              ]),
            ])
          } else {
            span(class="street-scene-note", "场景示意")
          },
        ]),
      ]),
    ],
  )
}

///|
fn street_project_entries(width : Int32, height : Int32) -> Unit {
  let points = ["interior", "events", "stories", "seat", "cafe"].filter_map(
    street_courtyard_point,
  )
  guard points.length() == 5 else { return }
  street_place_entries(
    points
    .map(p => {
      [golden_screen_x(p.0, p.1, width), golden_screen_y(p.0, p.1, height)]
    })
    .to_json()
    .stringify(),
    width,
    height,
  )
}

///|
/// DOM positioning only; content/actions remain MoonBit. When the destination
/// is offscreen, use a compact dock instead of a misleading floating pin.
extern "js" fn street_place_entries(
  points : String,
  width : Int32,
  height : Int32,
) -> Unit =
  #| (points,w,h) => {
  #|   const nav = document.querySelector('.street-destinations');
  #|   if (nav) nav.style.transform = '';
  #|   const ps=JSON.parse(points), ids=['street-interior','street-events','street-stories','street-seat','street-cafe'];
  #|   const dock=globalThis.__moontownGoldenValleyCamera?.streetOverview;
  #|   const pos=document.getElementById('street-walk-status')?.dataset.position?.split(',').map(Number);
  #|   const camera=globalThis.__moontownGoldenValleyCamera;
  #|   const visitor=pos?[w/2+((pos[0]-pos[1])*32-camera.x)*camera.z,h/2+((pos[0]+pos[1])*16-camera.y)*camera.z]:null;
  #|   for(let i=0;i<ids.length;i++) {
  #|     const el=document.getElementById(ids[i]); if(!el) continue;
  #|     const x=dock?w/2+(i-1)*92:ps[i][0]+(i===3?52:0), y=dock?h-110:ps[i][1]+(i===3?16:-52);
  #|     const transform=`translate(${x}px,${y}px) translate(-50%,-50%)`;
  #|     if(el.style.transform!==transform) el.style.transform=transform;
  #|     const visible=dock?i<3:x>24&&x<w-24&&y>70&&y<h-76;
  #|     el.style.visibility=visible?'visible':'hidden';
  #|     const near=visitor&&Math.hypot(visitor[0]-ps[i][0],visitor[1]-ps[i][1])<150;
  #|     // Keep the icon at its world point; don't let an expanded label clip on phones.
  #|     el.dataset.near=dock||(near&&x>60&&x<w-60)?'true':'false';
  #|     el.dataset.anchored=dock?'false':'true';
  #|   }
  #| }
