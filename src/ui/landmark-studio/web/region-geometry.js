// East and south in metres. The canvas and landmark bake share the same camera.
export const camera = { east: [0.965926, -0.194114], south: [0.258819, 0.724444], up: 0.661438 }
export const project = ([e, s]) => [
  e * camera.east[0] + s * camera.south[0],
  e * camera.east[1] + s * camera.south[1],
]
export const geo = ([lon, lat]) => [(lon - 116.2) * 85130, (40.2 - lat) * 111045]
export function register(block, anchors) {
  const [lon, lat, sx, sy] = block.base
  if (lon) {
    const [e, s] = geo([lon, lat])
    return ([x, y]) => [e + x * sx, s + y * sy]
  }
  const frame = anchors.registration[block.key]
  if (!frame) throw Error('Missing project registration: ' + block.key)
  const [a, b, e, s] = frame.matrix
  return ([x, y]) => [e + a * x - b * y, s + b * x + a * y]
}
export function bounds(points) {
  let left = Infinity,
    top = Infinity,
    right = -Infinity,
    bottom = -Infinity
  for (const [x, y] of points) {
    left = Math.min(left, x)
    right = Math.max(right, x)
    top = Math.min(top, y)
    bottom = Math.max(bottom, y)
  }
  return { left, top, right, bottom, x: (left + right) / 2, y: (top + bottom) / 2 }
}
export const centre = (r) => {
  const b = bounds(r)
  return [b.x, b.y]
}
export function bakeAxes(east, south) {
  function tileAxis(axis) {
    const [u, v] = project(axis)
    return [(v / 16 + u / 32) / 2, (v / 16 - u / 32) / 2]
  }
  return { east: tileAxis(east), south: tileAxis(south), elevation: camera.up }
}
