///|
// Keep the legacy five-argument bridge untouched for cadence watches.
extern "js" fn submit_local_material_request_json(
  title : String,
  prompt : String,
  target_book_id : String,
  cadence_ticks : String,
  quality_threshold : String,
  material_sources : String,
  material_acceptance : String,
  material_next_action : String,
) -> @js.Promise =
  #| async (title, prompt, targetBookId, cadenceTicks, qualityThreshold, sources, acceptance, nextAction) => {
  #|   try {
  #|     const response = await fetch("./api/operator-requests", {
  #|       method: "POST",
  #|       headers: { "Content-Type": "application/json" },
  #|       body: JSON.stringify({
  #|         title, prompt, target_book_id: targetBookId,
  #|         cadence_ticks: cadenceTicks, quality_threshold: qualityThreshold,
  #|         watch_mode: "local-material", material_sources: sources,
  #|         material_acceptance: acceptance, material_next_action: nextAction,
  #|       }),
  #|     });
  #|     const text = await response.text();
  #|     if (globalThis.__moontownRefreshRuntimeSnapshots) {
  #|       Promise.resolve().then(() => globalThis.__moontownRefreshRuntimeSnapshots()).catch(() => {});
  #|     }
  #|     if (!response.ok) {
  #|       try {
  #|         const parsed = JSON.parse(text);
  #|         return JSON.stringify({ ok: false, error: parsed.error || text });
  #|       } catch (_) {
  #|         return JSON.stringify({ ok: false, error: text || response.statusText });
  #|       }
  #|     }
  #|     return text;
  #|   } catch (error) {
  #|     return JSON.stringify({ ok: false, error: String(error) });
  #|   }
  #| }
