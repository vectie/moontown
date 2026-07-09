///|
extern "js" fn install_viewport_drag_pan() -> Unit =
  #| () => {
  #|   if (!globalThis.__moontownInstallViewportDragPan) {
  #|     return
  #|   }
  #|   globalThis.__moontownInstallViewportDragPan()
  #| }
