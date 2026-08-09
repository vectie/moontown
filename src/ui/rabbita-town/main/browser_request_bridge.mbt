///|
extern "js" fn submit_operator_request_json(
  title : String,
  prompt : String,
  target_book_id : String,
  cadence_ticks : String,
  quality_threshold : String,
) -> @js.Promise =
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
) -> @js.Promise =
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

///|
extern "js" fn browser_moonclaw_guide_session_id() -> String =
  #| () => {
  #|   const key = "moontown.moonclaw-guide.session.v1";
  #|   try {
  #|     const existing = globalThis.localStorage?.getItem(key) || "";
  #|     if (/^[A-Za-z0-9_-]{1,80}$/.test(existing)) return existing;
  #|     const random = globalThis.crypto?.randomUUID?.().replaceAll("-", "") ||
  #|       `${Date.now()}${Math.random().toString(16).slice(2)}`;
  #|     const value = `browser-${random}`.slice(0, 80);
  #|     globalThis.localStorage?.setItem(key, value);
  #|     return value;
  #|   } catch (_) {
  #|     return "browser";
  #|   }
  #| }

///|
extern "js" fn submit_moonclaw_guide_json(
  message : String,
  context : String,
  session_id : String,
) -> @js.Promise =
  #| async (message, context, sessionId) => {
  #|   try {
  #|     const response = await fetch("./api/agent/chat", {
  #|       method: "POST",
  #|       headers: { "Content-Type": "application/json" },
  #|       body: JSON.stringify({ message, context, session_id: sessionId }),
  #|     });
  #|     const text = await response.text();
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
  #|     return JSON.stringify({
  #|       ok: false,
  #|       error: `Moonclaw is unavailable: ${String(error)}`,
  #|     });
  #|   }
  #| }

///|
async fn wait_request_response_json(promise : @js.Promise) -> String noraise {
  promise.wait().cast() catch {
    _ =>
      "{\"ok\":false,\"error\":\"Request failed before a response was available.\"}"
  }
}
