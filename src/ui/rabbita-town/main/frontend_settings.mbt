///| Read a setting from the public system-settings snapshot loaded before the

///| Rabbita application starts. Tests and static builds retain the explicit

///|
/// fallback when no runtime snapshot exists.
extern "js" fn frontend_setting_int(key : String, fallback : Int) -> Int =
  #| (key, fallback) => {
  #|   try {
  #|     const parsed = JSON.parse(globalThis.__moontownSystemSettingsJson || "{}");
  #|     const value = parsed?.settings?.[key];
  #|     return Number.isSafeInteger(value) ? value : fallback;
  #|   } catch (_) {
  #|     return fallback;
  #|   }
  #| }
