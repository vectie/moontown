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
    Some(center) =>
      street_living_room_camera(
        arriving,
        overview,
        center.origin.x,
        center.origin.y,
      )
    None => ()
  }
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
  #|   if (!camera.livingRoom) {
  #|     const mobile = w < 700;
  #|     camera.z = mobile ? 1.8 : Math.min(3.0, Math.max(2.2, w / 460));
  #|     camera.x = (worldX-worldY)*32;
  #|     camera.y = (worldX+worldY)*16 + h*0.04/camera.z;
  #|     camera.livingRoom = true;
  #|     camera.streetOverview = false;
  #|   }
  #|   if (overview !== camera.streetOverview) {
  #|     const from = {x:camera.x,y:camera.y,z:camera.z};
  #|     let to;
  #|     if (overview) {
  #|       camera.streetClose = camera.streetTransition?.to || from;
  #|       to = {x:1792,y:3200,z:Math.max(.03,Math.min((w-48)/12800,(h-160)/6400))};
  #|     } else if (camera.streetClose) {
  #|       to = camera.streetClose;
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
  #|   camera.livingRoomSize = stamp;
  #|   camera.gentleTrialFramed = true;
  #|   canvas.dataset.townView = overview ? 'street-overview' : 'living-room';
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
    on_click=dispatch(OpenStreetContent(section, "")),
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
        class="street-location",
        town_ui_label(
          "pin",
          if model.street_overview {
            "全镇"
          } else {
            "未来中心 · 街区客厅"
          },
        ),
      ),
      div(class="street-header-actions", [
        render_public_platform_account(),
        button(
          class="street-button street-overview",
          on_click=dispatch(StreetOverview),
          attrs=@html.Attrs::build().aria_pressed(
            if model.street_overview {
              "true"
            } else {
              "false"
            },
          ),
          town_ui_label(
            if model.street_overview {
              "back"
            } else {
              "menu"
            },
            if model.street_overview {
              "回到街区"
            } else {
              "总览"
            },
          ),
        ),
      ]),
    ]),
    @html.nav(
      class="street-destinations",
      attrs=@html.Attrs::build().aria_label("街区去处"),
      [
        button(
          id="street-interior",
          class="street-world-entry street-door-button",
          on_click=dispatch(OpenReferenceInterior),
          attrs=@html.Attrs::build().aria_label("进入室内"),
          town_ui_label("forward", "室内"),
        ),
        render_street_notice(dispatch, model.neighborhood, false),
        render_street_notice(dispatch, model.neighborhood, true),
      ],
    ),
    div(class="street-walk-hud", [
      button(
        class="street-button street-recenter",
        title="找到我",
        attrs=@html.Attrs::build().aria_label("找到我"),
        on_click=dispatch(StreetRecenter),
        town_ui_icon("pin"),
      ),
      span(
        id="street-walk-status",
        attrs=@html.Attrs::build().role("status").aria_live("polite"),
        "点击道路走走",
      ),
      @html.details(class="street-controls", [
        @html.summary(
          title="操作",
          attrs=@html.Attrs::build().aria_label("行走操作"),
          town_ui_icon("sliders"),
        ),
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
      ]),
    ]),
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

///|
fn street_project_entries(width : Int32, height : Int32) -> Unit {
  guard town_landmark_find("center") is Some(center) else { return }
  let points = [
    center.door,
    town_landmark_at(center, -100.0, 90.0),
    town_landmark_at(center, 110.0, 90.0),
  ]
  street_place_entries(
    points
    .map(p => {
      [golden_screen_x(p.x, p.y, width), golden_screen_y(p.x, p.y, height)]
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
  #|   const ps=JSON.parse(points), ids=['street-interior','street-events','street-stories'];
  #|   const dock=globalThis.__moontownGoldenValleyCamera?.streetOverview ||
  #|     ps.some(([x,y])=>x<60 || x>w-60 || y<140 || y>h-100) ||
  #|     ps.some(([x,y],i)=>ps.some(([a,b],j)=>i!==j && Math.abs(x-a)<100 && Math.abs(y-b)<70));
  #|   for(let i=0;i<ids.length;i++) {
  #|     const el=document.getElementById(ids[i]); if(!el) continue;
  #|     const x=dock?w/2+(i-1)*92:ps[i][0], y=dock?h-110:ps[i][1]-28;
  #|     const transform=`translate(${x}px,${y}px) translate(-50%,-50%)`;
  #|     if(el.style.transform!==transform) el.style.transform=transform;
  #|     el.style.visibility='visible';
  #|     el.dataset.anchored=dock?'false':'true';
  #|   }
  #| }
