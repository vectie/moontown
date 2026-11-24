// Keep UI and hit coordinates at CSS resolution. Only the 3D drawing buffer
// follows the GPU budget. Orbit controls still use the original camera aspect.
export const compactGraphics = (navigator.deviceMemory > 0 && navigator.deviceMemory <= 4) ||
  /RK3588|Rockchip/i.test(navigator.userAgent)

export function resizeScene(renderer,width,height,maxRatio=1.75) {
  const ratio = compactGraphics
    ? Math.min(devicePixelRatio || 1, Math.sqrt(400000 / Math.max(1,width*height)))
    : Math.min(devicePixelRatio || 1,maxRatio)
  renderer.setDrawingBufferSize(Math.max(1,width), Math.max(1,height), ratio)
}

export function shadowSize(desktopSize) {
  return compactGraphics ? Math.min(1024,desktopSize) : desktopSize
}
