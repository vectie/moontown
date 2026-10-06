///|
// Exercise the actual product FFI with local promises; never contact a server.
extern "js" fn watch_bridge_deferred_regression(
  submit : (String, String, String, String, String) -> @js.Promise,
) -> @js.Promise =
  #| async submit => {
  #|   const names = ["fetch", "__moontownRefreshRuntimeSnapshots"];
  #|   const originals = new Map(names.map(name => [name, Object.getOwnPropertyDescriptor(globalThis, name)]));
  #|   const install = (name, value) => Object.defineProperty(globalThis, name, { configurable: true, writable: true, value });
  #|   const check = (value, message) => { if (!value) throw new Error(message); };
  #|   let timer;
  #|   try {
  #|     let resolveHttp;
  #|     let requests = 0;
  #|     let refreshes = 0;
  #|     const accepted = JSON.stringify({ ok: true, request_id: "request-deferred", standing_goal_id: "goal-deferred" });
  #|     install("fetch", (url, options) => {
  #|       requests += 1;
  #|       check(url === "./api/operator-requests", "endpoint changed");
  #|       check(options.method === "POST", "expected one POST");
  #|       const body = JSON.parse(options.body);
  #|       check(body.title === "Original" && body.cadence_ticks === "60", "submitted draft changed");
  #|       return new Promise(resolve => { resolveHttp = resolve; });
  #|     });
  #|     install("__moontownRefreshRuntimeSnapshots", () => {
  #|       refreshes += 1;
  #|       return new Promise(() => {}); // Intentionally unresolved secondary work.
  #|     });
  #|     let settled = false;
  #|     const response = submit("Original", "Prompt", "book", "60", "85");
  #|     response.then(() => { settled = true; });
  #|     await Promise.resolve();
  #|     await Promise.resolve();
  #|     check(!settled, "save settled before HTTP response");
  #|     check(requests === 1, "unexpected duplicate POST");
  #|     resolveHttp({ ok: true, text: async () => accepted });
  #|     const timeout = new Promise((_, reject) => {
  #|       timer = setTimeout(() => reject(new Error("received save response remained blocked on snapshot refresh")), 1000);
  #|     });
  #|     check(await Promise.race([response, timeout]) === accepted, "accepted response lost");
  #|     clearTimeout(timer);
  #|     check(refreshes === 1 && requests === 1, "refresh caused a duplicate save");
  #|     install("fetch", async () => ({ ok: true, text: async () => accepted }));
  #|     install("__moontownRefreshRuntimeSnapshots", async () => { throw new Error("refresh unavailable"); });
  #|     check(await submit("Original", "Prompt", "book", "60", "85") === accepted, "refresh rejection hid acceptance");
  #|     install("fetch", async () => { throw new Error("response lost"); });
  #|     const uncertain = JSON.parse(await submit("Original", "Prompt", "book", "60", "85"));
  #|     check(uncertain.ok === false && uncertain.error.includes("response lost"), "transport uncertainty was hidden");
  #|     return "passed";
  #|   } finally {
  #|     clearTimeout(timer);
  #|     for (const [name, descriptor] of originals) {
  #|       if (descriptor) Object.defineProperty(globalThis, name, descriptor);
  #|       else delete globalThis[name];
  #|     }
  #|   }
  #| }

///|
test "watch bridge waits for HTTP but never waits for secondary snapshot refresh" {
  @js.async_test(() => {
    let result : String = serial_watch_bridge_fixture(() => {
        watch_bridge_deferred_regression(submit_operator_request_json)
      })
      .wait()
      .cast()
    assert_eq(result, "passed")
  })
}
