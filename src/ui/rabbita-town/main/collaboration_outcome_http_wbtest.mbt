///|
/// Actual native HTTP and the production download function; only browser file
/// saving is observed with an in-memory DOM. No replacement fetch responses.
extern "js" fn outcome_http_crossing(
  download : (String, String, Int32, String, String, Int32) -> @js.Promise,
) -> @js.Promise =
  #| async download => {
  #|   const endpoint = globalThis.process?.env?.MOONTOWN_OUTCOME_HTTP_URL;
  #|   if (!endpoint) return "not-configured";
  #|   const request = (action, key = null) => JSON.stringify({contract_version:"moontown.collaboration.request.v1",request_id:"bridge",action,draft_id:key?.draft_id || "",revision:key?.revision || "",new_draft_id:"",artifact_path:"",draft:null,payload:key});
  #|   const send = async (action,key) => {
  #|     const response = await fetch(endpoint,{method:"POST",headers:{"Content-Type":"application/json"},body:request(action,key)});
  #|     if (!response.ok) throw Error("native HTTP " + response.status);
  #|     return await response.json();
  #|   };
  #|   const index = await send("outcome-list");
  #|   const entry = index.outcomes.find(x => x.outcome_status === "partial");
  #|   if (!entry) throw Error("actual partial result missing");
  #|   const key = {draft_id:entry.draft_id,revision:entry.revision,result_digest:entry.result_digest,review_version:entry.review_version,review_digest:entry.review_digest};
  #|   const response = await send("outcome-inspect",key);
  #|   const outcome = Array.isArray(response.outcome) ? response.outcome[0] : response.outcome;
  #|   const prior = {document:globalThis.document,generation:globalThis.__townCollaborationGeneration,create:URL.createObjectURL,revoke:URL.revokeObjectURL,timeout:globalThis.setTimeout};
  #|   let clicks = 0, captured = null;
  #|   globalThis.document = {body:{appendChild(){}},createElement(){return {click(){clicks++},remove(){}}}};
  #|   URL.createObjectURL = blob => {captured=blob;return "blob:native-http"};
  #|   URL.revokeObjectURL = () => {};
  #|   try {
  #|     globalThis.__townCollaborationGeneration = 70;
  #|     const ok = await download(endpoint,request("outcome-export",key),70,"retained.tar",outcome.archive_digest,outcome.archive_size_bytes);
  #|     if (clicks !== 1 || !captured || captured.size !== outcome.archive_size_bytes) throw Error("native download did not save exact archive: " + ok);
  #|     const digest = "sha256:" + [...new Uint8Array(await crypto.subtle.digest("SHA-256",await captured.arrayBuffer()))].map(x=>x.toString(16).padStart(2,"0")).join("");
  #|     if (digest !== outcome.archive_digest) throw Error("saved native archive digest mismatch");
  #|     for (const reason of ["selection","filter","route","cancel"]) {
  #|       const previousClicks = clicks;
  #|       globalThis.__townCollaborationGeneration = 71;
  #|       const stale = await download(endpoint,request("outcome-export",key),70,reason+".tar",outcome.archive_digest,outcome.archive_size_bytes);
  #|       if (clicks !== previousClicks || !stale.includes("cancelled")) throw Error(reason+" did not fence native download");
  #|     }
  #|     const wrong = await download(endpoint,request("outcome-export",key),71,"wrong.tar","sha256:"+"0".repeat(64),outcome.archive_size_bytes);
  #|     if (clicks !== 1 || !wrong.includes("identity")) throw Error("wrong inspected archive identity was accepted");
  #|     const bad = await download(endpoint,request("outcome-export",{...key,review_version:99}),71,"missing.tar",outcome.archive_digest,outcome.archive_size_bytes);
  #|     if (clicks !== 1 || bad.includes("Download prepared")) throw Error("missing native review was downloaded");
  #|     return "native-http-bridge:verified|clicks=1|stale=4|wrong-identity=blocked|missing-review=blocked|digest="+digest;
  #|   } finally {
  #|     globalThis.document=prior.document;globalThis.__townCollaborationGeneration=prior.generation;
  #|     URL.createObjectURL=prior.create;URL.revokeObjectURL=prior.revoke;globalThis.setTimeout=prior.timeout;
  #|   }
  #| }

///|
async test "retained outcome actual native HTTP download bridge preserves bytes and fences stale selections" {
  let result = collaboration_wait(
    outcome_http_crossing(collaboration_fetch_download),
  )
  if result == "not-configured" {
    println(
      "Native HTTP crossing not configured; run verification with MOONTOWN_OUTCOME_HTTP_URL",
    )
  } else {
    assert_true(
      result.has_prefix("native-http-bridge:verified|clicks=1|stale=4"),
      msg=result,
    )
    println(result)
  }
}
