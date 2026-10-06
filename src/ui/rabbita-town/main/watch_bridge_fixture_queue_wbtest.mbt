///|
// Rabbita's async_test launches detached work. Serialize every harness that
// mutates global fetch/refresh so aggregate runs cannot borrow another test's
// stub or restore its globals early. Each harness keeps its original assertions
// and finally cleanup; this queue also releases after a rejected harness.
extern "js" fn serial_watch_bridge_fixture(
  run : () -> @js.Promise,
) -> @js.Promise =
  #| run => {
  #|   const key = "__moontownWatchBridgeFixtureQueue";
  #|   const previous = globalThis[key] || Promise.resolve();
  #|   const result = previous.then(run, run);
  #|   const tail = result.then(() => undefined, () => undefined);
  #|   globalThis[key] = tail;
  #|   return result.finally(() => {
  #|     if (globalThis[key] === tail) delete globalThis[key];
  #|   });
  #| }
