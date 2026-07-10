///|
extern "js" fn real_time_label() -> String =
  #| () => new Date().toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit", second: "2-digit" })

///|
extern "js" fn real_local_hour() -> Int =
  #| () => new Date().getHours()

///|
extern "js" fn current_browser_path() -> String =
  #| () => `${globalThis.location?.pathname || ""}${globalThis.location?.hash || ""}`

///|
extern "js" fn current_viewport_mode_param() -> String =
  #| () => {
  #|   try {
  #|     return new URL(globalThis.location?.href || "http://local/").searchParams.get("mode") || "";
  #|   } catch (_) {
  #|     return "";
  #|   }
  #| }

///|
extern "js" fn current_viewport_module_param() -> String =
  #| () => {
  #|   try {
  #|     return new URL(globalThis.location?.href || "http://local/").searchParams.get("module") || "";
  #|   } catch (_) {
  #|     return "";
  #|   }
  #| }
