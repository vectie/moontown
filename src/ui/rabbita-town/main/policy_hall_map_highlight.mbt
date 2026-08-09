///|
/// Policy Hall is carrying the current Changping youth-entrepreneurship
/// publication. Keep this identity separate from transient runtime work and
/// selection state so the landmark remains discoverable on an idle map.
fn golden_policy_hall_publication_highlight(module_key : String?) -> Bool {
  match module_key {
    Some(value) => normalize_module_binding_key(value) == "policy-hall"
    None => false
  }
}

///|
fn golden_policy_hall_publication_badge() -> String {
  "昌平青创政策"
}

///|
/// Draw a persistent, non-color-only publication marker after the building.
/// The halo is deliberately quieter than selection and runtime-alert rings;
/// reduced-motion users receive the same shape and text without pulsing.
extern "js" fn golden_draw_policy_hall_publication_highlight(
  context : @dom.CanvasRenderingContext2D,
  ground_x : Double,
  ground_y : Double,
  top_y : Double,
  width : Double,
  depth : Double,
  zoom : Double,
  label : String,
  selected : Bool,
  reduced_motion : Bool,
  seconds : Double,
) -> Unit =
  #| (
  #|   context, groundX, groundY, topY, width, depth, zoom, label, selected,
  #|   reducedMotion, seconds,
  #| ) => {
  #|   if (!context || zoom < 0.09 || !label) return;
  #|   const z = Math.max(0.32, zoom);
  #|   const pulse = reducedMotion ? 0.5 : (Math.sin(seconds * 1.8) + 1) / 2;
  #|   const ringWidth = Math.max(22, (width + depth) * 10.5 * z);
  #|   const ringHeight = Math.max(8, (width + depth) * 3.8 * z);
  #|   const badgeFont = Math.max(10, Math.min(13, 11 * z));
  #|   const badgeY = topY - Math.max(30, 50 * z);
  #|   context.save();
  #|   context.lineCap = "round";
  #|   context.lineJoin = "round";
  #|
  #|   // A dashed mint footprint makes the landmark discoverable even when
  #|   // color perception, map scale, or the authored sprite varies.
  #|   context.strokeStyle = selected
  #|     ? "rgba(255,246,174,.94)"
  #|     : "rgba(94,234,212,.86)";
  #|   context.lineWidth = Math.max(1.4, 2 * z);
  #|   context.setLineDash([Math.max(3, 5 * z), Math.max(2, 3 * z)]);
  #|   context.globalAlpha = selected ? .94 : .72 + pulse * .18;
  #|   context.beginPath();
  #|   context.ellipse(
  #|     groundX, groundY + Math.max(1, 2 * z),
  #|     ringWidth * (1 + pulse * .035),
  #|     ringHeight * (1 + pulse * .035),
  #|     0, 0, Math.PI * 2,
  #|   );
  #|   context.stroke();
  #|   context.setLineDash([]);
  #|   context.globalAlpha = 1;
  #|
  #|   context.font =
  #|     `800 ${badgeFont}px "PingFang SC", "Microsoft YaHei", sans-serif`;
  #|   context.textAlign = "center";
  #|   context.textBaseline = "middle";
  #|   const textWidth = context.measureText(label).width;
  #|   const dotSize = Math.max(3, 3.6 * z);
  #|   const gap = Math.max(5, 6 * z);
  #|   const paddingX = Math.max(8, 9 * z);
  #|   const badgeWidth = textWidth + dotSize * 2 + gap + paddingX * 2;
  #|   const badgeHeight = Math.max(21, badgeFont * 1.75);
  #|   const badgeLeft = groundX - badgeWidth / 2;
  #|   const badgeTop = badgeY - badgeHeight / 2;
  #|
  #|   context.shadowColor = "rgba(7,40,43,.25)";
  #|   context.shadowBlur = Math.max(4, 8 * z);
  #|   context.shadowOffsetY = Math.max(2, 3 * z);
  #|   context.fillStyle = "rgba(240,253,250,.97)";
  #|   context.beginPath();
  #|   context.roundRect(
  #|     badgeLeft, badgeTop, badgeWidth, badgeHeight, badgeHeight / 2,
  #|   );
  #|   context.fill();
  #|   context.shadowColor = "transparent";
  #|   context.shadowBlur = 0;
  #|   context.shadowOffsetY = 0;
  #|   context.strokeStyle = "rgba(13,148,136,.88)";
  #|   context.lineWidth = Math.max(1, 1.25 * z);
  #|   context.stroke();
  #|
  #|   const contentLeft = groundX - (textWidth + dotSize * 2 + gap) / 2;
  #|   context.fillStyle = selected ? "#d97706" : "#0d9488";
  #|   context.beginPath();
  #|   context.arc(contentLeft + dotSize, badgeY, dotSize, 0, Math.PI * 2);
  #|   context.fill();
  #|   context.fillStyle = "#134e4a";
  #|   context.fillText(
  #|     label,
  #|     contentLeft + dotSize * 2 + gap + textWidth / 2,
  #|     badgeY + .25,
  #|   );
  #|
  #|   // A short pointer connects the status chip to its building and avoids
  #|   // looking like an unrelated toast floating over the town.
  #|   context.fillStyle = "rgba(240,253,250,.97)";
  #|   context.strokeStyle = "rgba(13,148,136,.88)";
  #|   context.lineWidth = Math.max(1, 1.2 * z);
  #|   context.beginPath();
  #|   context.moveTo(groundX - 4, badgeTop + badgeHeight - .5);
  #|   context.lineTo(groundX + 4, badgeTop + badgeHeight - .5);
  #|   context.lineTo(groundX, badgeTop + badgeHeight + 5);
  #|   context.closePath();
  #|   context.fill();
  #|   context.stroke();
  #|   context.restore();
  #| }
