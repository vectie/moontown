///|
struct MaterialWatchTestScheduler {}

///|
impl @cmd.Scheduler for MaterialWatchTestScheduler with fn run_effect(
  self,
  _kind,
  effect,
) {
  effect(self)
}

///|
impl @cmd.Scheduler for MaterialWatchTestScheduler with fn queue_message(
  _self,
  _path,
  _message,
) {

}

///|
impl @cmd.Scheduler for MaterialWatchTestScheduler with fn drain_message(_self) {

}

///|
impl @cmd.Scheduler for MaterialWatchTestScheduler with fn hooks(_self) {
  { url_request: None, url_changed: None, }
}

///|
// Local fetch stub around the real update -> command -> mode bridge, not a
// reconstruction of its payload. No server is contacted.
extern "js" fn capture_material_watch_command(
  start : ((String) -> Unit) -> Unit,
  local_material : Bool,
) -> @js.Promise =
  #| async (start, localMaterial) => {
  #|   const names = ["fetch", "__moontownRefreshRuntimeSnapshots"];
  #|   const originals = new Map(names.map(name => [name, Object.getOwnPropertyDescriptor(globalThis, name)]));
  #|   const install = (name, value) => Object.defineProperty(globalThis, name, { configurable: true, writable: true, value });
  #|   const check = (ok, message) => { if (!ok) throw new Error(message); };
  #|   let timer;
  #|   try {
  #|     let bodyText = "";
  #|     let count = 0;
  #|     install("fetch", async (url, options) => {
  #|       count++;
  #|       check(url === "./api/operator-requests" && options.method === "POST", "existing operator endpoint required");
  #|       check(options.headers["Content-Type"] === "application/json", "content type missing");
  #|       bodyText = options.body;
  #|       const body = JSON.parse(bodyText);
  #|       check(body.title === "Customer assumption", "form title lost");
  #|       check(body.prompt === "Keep the customer launch assumption current", "form intent lost");
  #|       check(body.target_book_id === "research-material" && body.cadence_ticks === "10" && body.quality_threshold === "85", "form fields lost");
  #|       if (localMaterial) {
  #|         check(body.watch_mode === "local-material", "local opt-in lost");
  #|         check(body.material_sources === "sources/customer.txt\nsources/market.txt", "explicit source paths lost");
  #|         check(body.material_acceptance === "Show exact changed source and retain review pending", "acceptance lost");
  #|         check(body.material_next_action === "Founder: review whether the launch date should change", "next action lost");
  #|       } else {
  #|         check(!("watch_mode" in body) && !("material_sources" in body) && !("material_acceptance" in body) && !("material_next_action" in body), "legacy request gained local material fields");
  #|       }
  #|       return { ok: true, text: async () => JSON.stringify({ ok: true, request_id: "request-material", standing_goal_id: "goal-material" }) };
  #|     });
  #|     install("__moontownRefreshRuntimeSnapshots", () => new Promise(() => {}));
  #|     const response = new Promise(resolve => start(resolve));
  #|     const timeout = new Promise((_, reject) => { timer = setTimeout(() => reject(new Error("command did not dispatch its received result")), 1000); });
  #|     const result = JSON.parse(await Promise.race([response, timeout]));
  #|     check(result.ok && result.request_id === "request-material", "command result lost");
  #|     check(count === 1, "repeat submit issued duplicate POST");
  #|     return bodyText;
  #|   } finally {
  #|     clearTimeout(timer);
  #|     for (const [name, descriptor] of originals) {
  #|       if (descriptor) Object.defineProperty(globalThis, name, descriptor);
  #|       else delete globalThis[name];
  #|     }
  #|   }
  #| }

///|
fn run_material_watch_test_command(
  model : Model,
  done : (String) -> Unit,
) -> Unit {
  let dispatch : Dispatch[Msg] = Emit(msg => {
    match msg {
      OperatorRequestSubmitted(_id, raw) => done(raw)
      _ => ()
    }
    @rabbita.none
  })
  let scheduler = MaterialWatchTestScheduler::{ }
  let (command, pending) = submit_operator_request_update(dispatch, model)
  let (repeated, _) = submit_operator_request_update(dispatch, pending)
  @cmd.Scheduler::add(scheduler, command)
  @cmd.Scheduler::add(scheduler, repeated)
}

///|
test "material watch actual filled form command emits integration fixture body" {
  @js.async_test(() => {
    let captured : String = serial_watch_bridge_fixture(() => {
        capture_material_watch_command(
          done => {
            run_material_watch_test_command(material_watch_form_fixture(), done)
          },
          true,
        )
      })
      .wait()
      .cast()
    println("MATERIAL_WATCH_FORM_BODY:" + captured)
  })
}

///|
test "material watch toggled back to cadence command retains legacy FFI body" {
  @js.async_test(() => {
    let model = update_operator_request_form(
      material_watch_form_fixture(),
      OperatorRequestWatchMode(CadenceWatch),
    )
    let captured : String = serial_watch_bridge_fixture(() => {
        capture_material_watch_command(
          done => run_material_watch_test_command(model, done),
          false,
        )
      })
      .wait()
      .cast()
    assert_false(captured.contains("material_sources"))
  })
}
