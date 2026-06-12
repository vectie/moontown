///|
extern "js" fn submit_operator_request_json(
  title : String,
  prompt : String,
  target_book_id : String,
  cadence_ticks : String,
  quality_threshold : String,
) -> String =
  #| async (title, prompt, targetBookId, cadenceTicks, qualityThreshold) => {
  #|   try {
  #|     const response = await fetch("./api/operator-requests", {
  #|       method: "POST",
  #|       headers: { "Content-Type": "application/json" },
  #|       body: JSON.stringify({
  #|         title,
  #|         prompt,
  #|         target_book_id: targetBookId,
  #|         cadence_ticks: cadenceTicks,
  #|         quality_threshold: qualityThreshold,
  #|       }),
  #|     });
  #|     const text = await response.text();
  #|     if (globalThis.__moontownRefreshRuntimeSnapshots) {
  #|       await globalThis.__moontownRefreshRuntimeSnapshots();
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

///|
extern "js" fn submit_book_template_request_json(
  title : String,
  book_id : String,
  purpose : String,
  websites : String,
  cadence_ticks : String,
  analysis_method : String,
) -> String =
  #| async (title, bookId, purpose, websites, cadenceTicks, analysisMethod) => {
  #|   try {
  #|     const response = await fetch("./api/book-template-requests", {
  #|       method: "POST",
  #|       headers: { "Content-Type": "application/json" },
  #|       body: JSON.stringify({
  #|         template_id: "pdf-evidence-watch",
  #|         title,
  #|         book_id: bookId,
  #|         purpose,
  #|         websites,
  #|         cadence_ticks: cadenceTicks,
  #|         analysis_method: analysisMethod,
  #|       }),
  #|     });
  #|     const text = await response.text();
  #|     if (globalThis.__moontownRefreshRuntimeSnapshots) {
  #|       await globalThis.__moontownRefreshRuntimeSnapshots();
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
