///|
/// Spatial pages must not depend on the outdoor canvas's keyboard lifecycle.
extern "js" fn schedule_spatial_dialog_accessibility() -> Unit =
  #| () => {
  #|   const doc = globalThis.document;
  #|   if (!doc || typeof requestAnimationFrame !== "function") return;
  #|   const state = globalThis.__moontownSpatialDialog ||= { dialog: null, opener: null, installed: false, raf: 0 };
  #|   const selector = '.building-interior-layer [role="dialog"][aria-modal="true"],.secret-compute-room [role="dialog"][aria-modal="true"]';
  #|   const controls = dialog => [...dialog.querySelectorAll('button:not([disabled]),a[href],input:not([disabled]),textarea:not([disabled]),select:not([disabled]),[tabindex="0"]')].filter(el => el.getClientRects().length);
  #|   if (!state.installed) {
  #|     state.installed = true;
  #|     doc.addEventListener('keydown', event => {
  #|       const dialog = doc.querySelector(selector);
  #|       if (!dialog) return;
  #|       if (event.key === 'Escape') {
  #|         event.preventDefault(); event.stopImmediatePropagation();
  #|         dialog.querySelector('[aria-label="关闭真实工作请求"]')?.click();
  #|       } else if (event.key === 'Tab') {
  #|         const items = controls(dialog);
  #|         if (!items.length) return;
  #|         const first = items[0], last = items[items.length - 1];
  #|         if (!dialog.contains(doc.activeElement) || (event.shiftKey && doc.activeElement === first) || (!event.shiftKey && doc.activeElement === last)) {
  #|           event.preventDefault(); (event.shiftKey ? last : first).focus();
  #|         }
  #|         event.stopImmediatePropagation();
  #|       }
  #|     }, true);
  #|   }
  #|   if (state.raf) return;
  #|   state.raf = requestAnimationFrame(() => {
  #|     state.raf = 0;
  #|     const dialog = doc.querySelector(selector);
  #|     if (dialog && dialog !== state.dialog) {
  #|       state.opener = doc.activeElement;
  #|       state.dialog = dialog;
  #|       controls(dialog)[0]?.focus();
  #|     } else if (!dialog && state.dialog) {
  #|       state.dialog = null;
  #|       if (state.opener?.isConnected) state.opener.focus();
  #|       state.opener = null;
  #|     }
  #|   });
  #| }
