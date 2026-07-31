///|
extern "js" fn inspect_moonflow_receiver_json(
  run_id : String,
  handoff_token : String,
) -> @js.Promise =
  #| async (runId, token) => {
  #|   const run = String(runId || "");
  #|   const handoff = String(token || "");
  #|   const reply = (ok, intake, status, error) =>
  #|     JSON.stringify({
  #|       contract_version: "moontown.moonflow-receiver-inspection.reply.v1",
  #|       ok,
  #|       requested_run_id: run,
  #|       requested_handoff_token: handoff,
  #|       intake,
  #|       status,
  #|       error,
  #|     });
  #|   if (!/^[A-Za-z0-9_.-]+$/.test(run) ||
  #|       !/^[0-9a-f]{64}$/.test(handoff)) {
  #|     return reply(false, null, null, "The MoonFlow run or handoff token is unsafe.");
  #|   }
  #|   const base = `/api/moonflow/runs/${run}/handoffs/${handoff}`;
  #|   try {
  #|     const [intakeResponse, statusResponse] = await Promise.all([
  #|       fetch(base, { headers: { Accept: "application/json" } }),
  #|       fetch(`${base}/status`, { headers: { Accept: "application/json" } }),
  #|     ]);
  #|     const [intakeText, statusText] = await Promise.all([
  #|       intakeResponse.text(),
  #|       statusResponse.text(),
  #|     ]);
  #|     if (!intakeResponse.ok || !statusResponse.ok) {
  #|       return reply(
  #|         false,
  #|         null,
  #|         null,
  #|         `MoonFlow receiver intake/status returned HTTP ${intakeResponse.status}/${statusResponse.status}.`,
  #|       );
  #|     }
  #|     return reply(true, JSON.parse(intakeText), JSON.parse(statusText), "");
  #|   } catch (error) {
  #|     return reply(false, null, null, `MoonTown could not inspect MoonFlow: ${String(error)}`);
  #|   }
  #| }

///|
async fn wait_moonflow_receiver_inspection(
  promise : @js.Promise,
) -> String noraise {
  promise.wait().cast() catch {
    _ =>
      "{\"contract_version\":\"moontown.moonflow-receiver-inspection.reply.v1\",\"ok\":false,\"requested_run_id\":\"\",\"requested_handoff_token\":\"\",\"intake\":null,\"status\":null,\"error\":\"MoonFlow receiver inspection ended before a response was available.\"}"
  }
}

///|
extern "js" fn execute_moonflow_receiver_json(
  product_endpoint : String,
  action : String,
  run_id : String,
  handoff_token : String,
  intake_json : String,
) -> @js.Promise =
  #| async (productEndpoint, action, runId, token, intakeJson) => {
  #|   const requestedAction = action === "reconcile" ? "reconcile" : "start";
  #|   const run = String(runId || "");
  #|   const handoff = String(token || "");
  #|   const reply = (ok, product, status, error) =>
  #|     JSON.stringify({
  #|       contract_version: "moontown.moonflow-receiver-settlement.reply.v1",
  #|       ok,
  #|       action: requestedAction,
  #|       product_execution: product,
  #|       receiver_status: status,
  #|       error,
  #|     });
  #|   try {
  #|     const intake = JSON.parse(String(intakeJson || ""));
  #|     const expectedBase = `/api/moonflow/runs/${run}/handoffs/${handoff}`;
  #|     if (intake?.binding?.handoff_token !== handoff ||
  #|         intake?.payload?.run?.run_id !== run ||
  #|         intake?.binding?.receipt_path !== `${expectedBase}/receipt`) {
  #|       return reply(false, null, null, "MoonFlow receipt path or launch identity drifted.");
  #|     }
  #|     const productResponse = await fetch(String(productEndpoint || ""), {
  #|       method: "POST",
  #|       headers: { "Content-Type": "application/json" },
  #|       body: JSON.stringify({
  #|         contract_version: `moontown.moonflow-research-${requestedAction}.request.v1`,
  #|         intake,
  #|       }),
  #|     });
  #|     const productText = await productResponse.text();
  #|     const product = productText ? JSON.parse(productText) : null;
  #|     if (!productResponse.ok || !product?.ok ||
  #|         product?.callback_status !== "delivered" ||
  #|         !product?.receiver_receipt) {
  #|       return reply(
  #|         false,
  #|         product,
  #|         null,
  #|         product?.error || `MoonTown product execution returned HTTP ${productResponse.status}.`,
  #|       );
  #|     }
  #|     const receiptResponse = await fetch(`${expectedBase}/receipt`, {
  #|       method: "POST",
  #|       headers: { "Content-Type": "application/json" },
  #|       body: JSON.stringify(product.receiver_receipt),
  #|     });
  #|     const receiptText = await receiptResponse.text();
  #|     const status = receiptText ? JSON.parse(receiptText) : null;
  #|     if (!receiptResponse.ok || status?.contract_id !== "moonflow.receiver-status.v1" ||
  #|         status?.run_id !== run || status?.handoff_token !== handoff ||
  #|         status?.status !== "accepted") {
  #|       return reply(
  #|         false,
  #|         product,
  #|         status,
  #|         `MoonFlow did not accept the correlated receiver receipt (HTTP ${receiptResponse.status}).`,
  #|       );
  #|     }
  #|     return reply(true, product, status, "");
  #|   } catch (error) {
  #|     return reply(false, null, null, `MoonTown could not settle MoonFlow: ${String(error)}`);
  #|   }
  #| }

///|
async fn wait_moonflow_receiver_settlement(
  promise : @js.Promise,
) -> String noraise {
  promise.wait().cast() catch {
    _ =>
      "{\"contract_version\":\"moontown.moonflow-receiver-settlement.reply.v1\",\"ok\":false,\"action\":\"start\",\"product_execution\":null,\"receiver_status\":null,\"error\":\"MoonFlow receiver settlement ended before a response was available.\"}"
  }
}
