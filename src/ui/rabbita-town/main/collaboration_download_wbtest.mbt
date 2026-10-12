///|
extern "js" fn collaboration_download_fixture(
  mode : String,
  run : () -> @js.Promise,
) -> @js.Promise =
  #| async (mode, run) => {
  #|   const prior = {fetch: globalThis.fetch, document: globalThis.document, generation: globalThis.__townCollaborationGeneration, create: URL.createObjectURL, revoke: URL.revokeObjectURL, timeout: globalThis.setTimeout};
  #|   let clicks = 0;
  #|   let downloaded = null;
  #|   globalThis.__townCollaborationGeneration = 7;
  #|   globalThis.fetch = async () => ({
  #|     ok: mode !== "http-error", status: 409,
  #|     headers: new Map([["Content-Length", "3"], ["X-Artifact-Digest", "sha256:ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"]]),
  #|     json: async () => ({error: "Captured source changed"}),
  #|     arrayBuffer: async () => {
  #|       if (mode === "stale") globalThis.__townCollaborationGeneration = 8;
  #|       return new TextEncoder().encode(mode === "tamper" ? "xyz" : "abc").buffer;
  #|     }
  #|   });
  #|   globalThis.document = {body: {appendChild() {}}, createElement() { return {click() { clicks++; }, remove() {}}; }};
  #|   URL.createObjectURL = blob => { downloaded = blob; return "blob:fixture"; };
  #|   URL.revokeObjectURL = () => {};
  #|   globalThis.setTimeout = callback => { callback(); return 0; };
  #|   try { const result = await run(); return `${result}|clicks=${clicks}|bytes=${downloaded ? await downloaded.text() : ""}`; }
  #|   finally {
  #|     globalThis.fetch = prior.fetch; globalThis.document = prior.document; globalThis.__townCollaborationGeneration = prior.generation;
  #|     URL.createObjectURL = prior.create; URL.revokeObjectURL = prior.revoke; globalThis.setTimeout = prior.timeout;
  #|   }
  #| }

///|
async test "collaboration actual download bridge verifies bytes and fences stale callbacks" {
  let expected = "sha256:ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
  for mode in ["ready", "tamper", "stale", "http-error"] {
    let result = collaboration_wait(
      collaboration_download_fixture(mode, fn() {
        collaboration_fetch_download(
          "/api/collaboration", "{}", 7, "source.bin", expected, 3,
        )
      }),
    )
    if mode == "ready" {
      assert_true(result.contains("clicks=1|bytes=abc"), msg=result)
    } else {
      assert_true(result.contains("clicks=0|bytes="), msg=result)
      if mode == "tamper" {
        assert_true(result.contains("digest"), msg=result)
      }
      if mode == "stale" {
        assert_true(result.contains("selection changed"), msg=result)
      }
      if mode == "http-error" {
        assert_true(result.contains("Captured source changed"), msg=result)
      }
    }
  }
}
