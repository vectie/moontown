///|
extern "js" fn moontown_product_api_path(route : String) -> String =
  #| (route) => {
  #|   const clean = String(route || "").replace(/^\/+/, "");
  #|   const prefix = "/pack-apps/moontown/";
  #|   const pathname = String(globalThis.location?.pathname || "/");
  #|   return pathname === prefix || pathname.startsWith(prefix)
  #|     ? `${prefix}${clean}`
  #|     : `/${clean}`;
  #| }

///|
extern "js" fn inspect_research_handoff_json(
  endpoint : String,
  handoff_url : String,
  handoff_contract : String,
  handoff_id : String,
) -> @js.Promise =
  #| async (endpoint, handoffUrl, handoffContract, handoffId) => {
  #|   const requestedUrl = String(handoffUrl || "");
  #|   try {
  #|     const response = await fetch(String(endpoint || ""), {
  #|       method: "POST",
  #|       headers: { "Content-Type": "application/json" },
  #|       body: JSON.stringify({
  #|         contract_version: "moontown.research-handoff-inspection.request.v1",
  #|         handoff_url: requestedUrl,
  #|         expected_contract: handoffContract,
  #|         expected_handoff_id: handoffId,
  #|       }),
  #|     });
  #|     const text = await response.text();
  #|     if (text) return text;
  #|     return JSON.stringify({
  #|       contract_version: "moontown.research-handoff-inspection.reply.v1",
  #|       ok: false,
  #|       requested_url: requestedUrl,
  #|       upstream_status: 0,
  #|       handoff: null,
  #|       error: `MoonTown inspection returned an empty HTTP ${response.status} response.`,
  #|     });
  #|   } catch (error) {
  #|     return JSON.stringify({
  #|       contract_version: "moontown.research-handoff-inspection.reply.v1",
  #|       ok: false,
  #|       requested_url: requestedUrl,
  #|       upstream_status: 0,
  #|       handoff: null,
  #|       error: `MoonTown could not inspect the typed handoff: ${String(error)}`,
  #|     });
  #|   }
  #| }

///|
async fn wait_research_handoff_inspection(
  promise : @js.Promise,
) -> String noraise {
  promise.wait().cast() catch {
    _ =>
      "{\"contract_version\":\"moontown.research-handoff-inspection.reply.v1\",\"ok\":false,\"requested_url\":\"\",\"upstream_status\":0,\"handoff\":null,\"error\":\"MoonTown inspection failed before a response was available.\"}"
  }
}

///|
extern "js" fn execute_research_handoff_json(
  endpoint : String,
  action : String,
  handoff_url : String,
  handoff_contract : String,
  handoff_id : String,
) -> @js.Promise =
  #| async (endpoint, action, handoffUrl, handoffContract, handoffId) => {
  #|   const requestedAction = action === "reconcile" ? "reconcile" : "start";
  #|   const requestedUrl = String(handoffUrl || "");
  #|   try {
  #|     const response = await fetch(String(endpoint || ""), {
  #|       method: "POST",
  #|       headers: { "Content-Type": "application/json" },
  #|       body: JSON.stringify({
  #|         contract_version:
  #|           `moontown.research-handoff-${requestedAction}.request.v1`,
  #|         handoff_url: requestedUrl,
  #|         expected_contract: handoffContract,
  #|         expected_handoff_id: handoffId,
  #|       }),
  #|     });
  #|     const text = await response.text();
  #|     if (text) return text;
  #|     return JSON.stringify({
  #|       contract_version: "moontown.research-handoff-execution.reply.v1",
  #|       ok: false,
  #|       action: requestedAction,
  #|       requested_url: requestedUrl,
  #|       handoff_id: String(handoffId || ""),
  #|       execution_status: "blocked",
  #|       review_status: "blocked",
  #|       callback_status: "not-attempted",
  #|       callback_http_status: 0,
  #|       package: null,
  #|       error: `MoonTown execution returned an empty HTTP ${response.status} response.`,
  #|     });
  #|   } catch (error) {
  #|     return JSON.stringify({
  #|       contract_version: "moontown.research-handoff-execution.reply.v1",
  #|       ok: false,
  #|       action: requestedAction,
  #|       requested_url: requestedUrl,
  #|       handoff_id: String(handoffId || ""),
  #|       execution_status: "blocked",
  #|       review_status: "blocked",
  #|       callback_status: "pending-reconcile",
  #|       callback_http_status: 0,
  #|       package: null,
  #|       error: `MoonTown could not settle the durable handoff: ${String(error)}`,
  #|     });
  #|   }
  #| }

///|
async fn wait_research_handoff_execution(
  promise : @js.Promise,
) -> String noraise {
  promise.wait().cast() catch {
    _ =>
      "{\"contract_version\":\"moontown.research-handoff-execution.reply.v1\",\"ok\":false,\"action\":\"start\",\"requested_url\":\"\",\"handoff_id\":\"\",\"execution_status\":\"blocked\",\"review_status\":\"blocked\",\"callback_status\":\"pending-reconcile\",\"callback_http_status\":0,\"package\":null,\"error\":\"MoonTown execution ended before a response was available.\"}"
  }
}
