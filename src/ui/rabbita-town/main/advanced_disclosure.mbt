///|
/// Technical context is available on demand, not part of the happy path.
/// Native details preserves keyboard access without a global expert-mode flag.
fn render_advanced_details(
  label : String,
  children : Array[@rabbita.Html],
  needs_attention~ : Bool = false,
  compact_label~ : String = "高级",
) -> @rabbita.Html {
  @html.details(class="town-advanced", open=needs_attention, [
    @html.summary(
      title=label,
      attrs=@html.Attrs::build().aria_label("Advanced · \{label}"),
      town_ui_label("sliders", compact_label),
    ),
    div(
      class="town-advanced-body",
      [p(class="town-advanced-heading", label), ..children],
    ),
  ])
}

///|
/// Reveal invalid advanced input instead of hiding the way to fix it.
fn advanced_integer_needs_attention(value : String, max~ : Int32) -> Bool {
  let parsed = @string.parse_int(value.trim()) catch { _ => return true }
  parsed < 1 || parsed > max
}

///|
/// Optional Pack tools remain reachable before deferred bootstrap finishes.
extern "js" fn open_advanced_pack_tools() -> Unit =
  #| () => {
  #|   import('./pack_bridge_panel.js').then(module => {
  #|     module.installPackBridgePanel();
  #|     document.querySelector('[data-pack-bridge-panel="launch"]')?.click();
  #|   }).catch(() => {
  #|     const button = document.getElementById('town-pack-tools-open');
  #|     if (button) button.textContent = '扩展工具未载入 · 点击重试';
  #|   });
  #| }
