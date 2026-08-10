import { ENERGY_VALLEY_TRANSPORT_SNAPSHOT } from './runtime_snapshot_manifest.js'

export const ENERGY_VALLEY_TRANSPORT_SCHEMA = 'moontown.energy-valley.transport.v1'
export const ENERGY_VALLEY_TRANSPORT_MAX_BYTES = 512 * 1024

const GRID_WIDTH = 256
const GRID_HEIGHT = 144
const COORDINATE_SCALE = 1000
const FETCH_TIMEOUT_MS = 1600
const ROAD_CLASSES = new Set(['arterial', 'collector', 'local'])
const ROAD_DETAILS = new Set(['mainline', 'ramp'])
const DIGEST_KEYS = ['grid', 'displayRoads', 'bridges', 'metro']
const FORBIDDEN_MAP_FIELDS = [
  'terrainRows',
  'roadRows',
  'structures',
  'modules',
  'landmarks',
]
const EXPECTED_PRESENTATION_ANCHORS = [
  ['未来科学城北站', [143529, 40259], [125000, 52000]],
  ['未来科学城站', [138320, 80186], [126500, 88000]],
]

function invalid(message) {
  throw new TypeError(`Invalid Energy Valley transport: ${message}`)
}

function requireObject(value, name) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    invalid(`${name} must be an object`)
  }
  return value
}

function requireSafeInteger(value, name, minimum, maximum) {
  if (!Number.isSafeInteger(value) || value < minimum || value > maximum) {
    invalid(`${name} is out of bounds`)
  }
  return value
}

function requireFiniteNumber(value, name, minimum, maximum) {
  if (
    typeof value !== 'number' ||
    !Number.isFinite(value) ||
    value < minimum ||
    value > maximum
  ) {
    invalid(`${name} is out of bounds`)
  }
  return value
}

function requireString(value, name, maximum, pattern = null, allowEmpty = false) {
  if (
    typeof value !== 'string' ||
    (!allowEmpty && value.length === 0) ||
    value.length > maximum ||
    (pattern && !pattern.test(value))
  ) {
    invalid(`${name} is invalid`)
  }
  return value
}

function validateGrid(grid) {
  requireObject(grid, 'grid')
  if (grid.width !== GRID_WIDTH || grid.height !== GRID_HEIGHT) {
    invalid(`grid must be ${GRID_WIDTH}x${GRID_HEIGHT}`)
  }
  if (grid.coordinateScale !== COORDINATE_SCALE) {
    invalid(`grid.coordinateScale must be ${COORDINATE_SCALE}`)
  }
  requireString(grid.sourceCrs, 'grid.sourceCrs', 64)
  const bbox = requireObject(grid.bboxWgs84, 'grid.bboxWgs84')
  const west = requireFiniteNumber(bbox.west, 'grid.bboxWgs84.west', -180, 180)
  const east = requireFiniteNumber(bbox.east, 'grid.bboxWgs84.east', -180, 180)
  const south = requireFiniteNumber(bbox.south, 'grid.bboxWgs84.south', -90, 90)
  const north = requireFiniteNumber(bbox.north, 'grid.bboxWgs84.north', -90, 90)
  if (west >= east || south >= north) {
    invalid('grid.bboxWgs84 must have positive area')
  }
  validatePresentationTransform(grid.presentationTransform, grid)
}

function validatePresentationTransform(transform, grid) {
  requireObject(transform, 'grid.presentationTransform')
  if (
    transform.type !== 'similarity' ||
    transform.sourceProjection !== 'wide-bbox-linear'
  ) {
    invalid('grid.presentationTransform must identify the accepted similarity fit')
  }
  const coefficient = requireObject(
    transform.coefficient,
    'grid.presentationTransform.coefficient',
  )
  const real = requireFiniteNumber(
    coefficient.real,
    'grid.presentationTransform.coefficient.real',
    -2,
    2,
  )
  const imaginary = requireFiniteNumber(
    coefficient.imaginary,
    'grid.presentationTransform.coefficient.imaginary',
    -2,
    2,
  )
  const translation = requireObject(
    transform.translation,
    'grid.presentationTransform.translation',
  )
  const translateX = requireFiniteNumber(
    translation.x,
    'grid.presentationTransform.translation.x',
    -grid.width,
    grid.width,
  )
  const translateY = requireFiniteNumber(
    translation.y,
    'grid.presentationTransform.translation.y',
    -grid.height,
    grid.height,
  )
  const scale = requireFiniteNumber(
    transform.scale,
    'grid.presentationTransform.scale',
    0.5,
    2,
  )
  const rotation = requireFiniteNumber(
    transform.rotationDegrees,
    'grid.presentationTransform.rotationDegrees',
    -180,
    180,
  )
  if (
    Math.abs(Math.hypot(real, imaginary) - scale) > 1e-8 ||
    Math.abs(Math.atan2(imaginary, real) * 180 / Math.PI - rotation) > 1e-5
  ) {
    invalid('grid.presentationTransform coefficients are inconsistent')
  }
  if (!Array.isArray(transform.anchors) || transform.anchors.length !== 2) {
    invalid('grid.presentationTransform.anchors must contain two control points')
  }
  for (let index = 0; index < EXPECTED_PRESENTATION_ANCHORS.length; index += 1) {
    const anchor = requireObject(
      transform.anchors[index],
      `grid.presentationTransform.anchors[${index}]`,
    )
    const [expectedName, expectedSource, expectedTarget] =
      EXPECTED_PRESENTATION_ANCHORS[index]
    if (anchor.name !== expectedName) {
      invalid(`grid.presentationTransform.anchors[${index}].name is invalid`)
    }
    const source = validateMillisPoint(
      anchor.sourceMillis,
      `grid.presentationTransform.anchors[${index}].sourceMillis`,
      grid,
    )
    const target = validateMillisPoint(
      anchor.targetMillis,
      `grid.presentationTransform.anchors[${index}].targetMillis`,
      grid,
    )
    if (
      source[0] !== expectedSource[0] ||
      source[1] !== expectedSource[1] ||
      target[0] !== expectedTarget[0] ||
      target[1] !== expectedTarget[1]
    ) {
      invalid(`grid.presentationTransform.anchors[${index}] is not accepted`)
    }
    const sourceX = source[0] / grid.coordinateScale
    const sourceY = source[1] / grid.coordinateScale
    const transformed = [
      Math.round(
        (real * sourceX - imaginary * sourceY + translateX) *
          grid.coordinateScale,
      ),
      Math.round(
        (imaginary * sourceX + real * sourceY + translateY) *
          grid.coordinateScale,
      ),
    ]
    if (transformed[0] !== target[0] || transformed[1] !== target[1]) {
      invalid(`grid.presentationTransform.anchors[${index}] does not fit`)
    }
  }
}

function validateMillisPoint(point, name, grid) {
  if (!Array.isArray(point) || point.length !== 2) {
    invalid(`${name} must be an [xMillis, yMillis] pair`)
  }
  return [
    requireSafeInteger(
      point[0],
      `${name}[0]`,
      0,
      grid.width * grid.coordinateScale - 1,
    ),
    requireSafeInteger(
      point[1],
      `${name}[1]`,
      0,
      grid.height * grid.coordinateScale - 1,
    ),
  ]
}

function validatePolylineRecords(records, name, minimum, maximum, grid, ids) {
  if (!Array.isArray(records) || records.length < minimum || records.length > maximum) {
    invalid(`${name} must contain between ${minimum} and ${maximum} records`)
  }
  let pointCount = 0
  for (let index = 0; index < records.length; index += 1) {
    const recordName = `${name}[${index}]`
    const record = requireObject(records[index], recordName)
    const id = requireString(
      record.id,
      `${recordName}.id`,
      64,
      /^(road|bridge)-[0-9]{4}$/,
    )
    if (ids.has(id)) {
      invalid(`duplicate transport id ${id}`)
    }
    ids.add(id)
    if (!ROAD_CLASSES.has(record.class)) {
      invalid(`${recordName}.class is unsupported`)
    }
    if (!ROAD_DETAILS.has(record.detail)) {
      invalid(`${recordName}.detail is unsupported`)
    }
    requireString(record.name, `${recordName}.name`, 128, null, true)
    if (!Array.isArray(record.points) || record.points.length < 2 || record.points.length > 2048) {
      invalid(`${recordName}.points must contain between 2 and 2048 points`)
    }
    pointCount += record.points.length
    if (pointCount > 32768) {
      invalid('transport contains too many polyline points')
    }
    let minimumX = Number.MAX_SAFE_INTEGER
    let minimumY = Number.MAX_SAFE_INTEGER
    let maximumX = -1
    let maximumY = -1
    let previous = null
    for (let pointIndex = 0; pointIndex < record.points.length; pointIndex += 1) {
      const point = validateMillisPoint(
        record.points[pointIndex],
        `${recordName}.points[${pointIndex}]`,
        grid,
      )
      if (previous && point[0] === previous[0] && point[1] === previous[1]) {
        invalid(`${recordName}.points contains a duplicate neighbour`)
      }
      previous = point
      minimumX = Math.min(minimumX, point[0])
      minimumY = Math.min(minimumY, point[1])
      maximumX = Math.max(maximumX, point[0])
      maximumY = Math.max(maximumY, point[1])
    }
    if (!Array.isArray(record.bounds) || record.bounds.length !== 4) {
      invalid(`${recordName}.bounds must contain four integers`)
    }
    const expectedBounds = [minimumX, minimumY, maximumX, maximumY]
    for (let boundIndex = 0; boundIndex < 4; boundIndex += 1) {
      const bound = requireSafeInteger(
        record.bounds[boundIndex],
        `${recordName}.bounds[${boundIndex}]`,
        0,
        boundIndex % 2 === 0
          ? grid.width * grid.coordinateScale - 1
          : grid.height * grid.coordinateScale - 1,
      )
      if (bound !== expectedBounds[boundIndex]) {
        invalid(`${recordName}.bounds does not enclose its points exactly`)
      }
    }
  }
}

function validateMetro(metro, grid) {
  requireObject(metro, 'metro')
  if (metro.lineId !== 'beijing-metro-line-17') {
    invalid('metro.lineId must identify Beijing Subway Line 17')
  }
  if (!Array.isArray(metro.path) || metro.path.length < 2 || metro.path.length > 512) {
    invalid('metro.path must contain between 2 and 512 points')
  }
  for (let index = 0; index < metro.path.length; index += 1) {
    validateMillisPoint(metro.path[index], `metro.path[${index}]`, grid)
  }
  if (!Array.isArray(metro.stations) || metro.stations.length !== 2) {
    invalid('metro.stations must contain the two Energy Valley stations')
  }
  const stationNames = new Set()
  const exitNodeIds = new Set()
  for (let index = 0; index < metro.stations.length; index += 1) {
    const station = requireObject(metro.stations[index], `metro.stations[${index}]`)
    const name = requireString(station.name, `metro.stations[${index}].name`, 128)
    if (stationNames.has(name)) {
      invalid(`duplicate metro station name ${name}`)
    }
    stationNames.add(name)
    validateMillisPoint(
      [station.xMillis, station.yMillis],
      `metro.stations[${index}]`,
      grid,
    )
    if (!Array.isArray(station.exits) || station.exits.length < 1 || station.exits.length > 8) {
      invalid(`metro.stations[${index}].exits must contain between 1 and 8 records`)
    }
    const labels = new Set()
    for (let exitIndex = 0; exitIndex < station.exits.length; exitIndex += 1) {
      const exit = requireObject(
        station.exits[exitIndex],
        `metro.stations[${index}].exits[${exitIndex}]`,
      )
      const label = requireString(
        exit.label,
        `metro.stations[${index}].exits[${exitIndex}].label`,
        32,
      )
      if (labels.has(label)) {
        invalid(`duplicate metro exit label ${name}/${label}`)
      }
      labels.add(label)
      const sourceNodeId = requireSafeInteger(
        exit.sourceNodeId,
        `metro.stations[${index}].exits[${exitIndex}].sourceNodeId`,
        1,
        Number.MAX_SAFE_INTEGER,
      )
      if (exitNodeIds.has(sourceNodeId)) {
        invalid(`duplicate metro entrance source node ${sourceNodeId}`)
      }
      exitNodeIds.add(sourceNodeId)
      requireString(
        exit.destination,
        `metro.stations[${index}].exits[${exitIndex}].destination`,
        256,
      )
      const exitPoint = validateMillisPoint(
        [exit.xMillis, exit.yMillis],
        `metro.stations[${index}].exits[${exitIndex}]`,
        grid,
      )
      const distance = Math.hypot(
        exitPoint[0] - station.xMillis,
        exitPoint[1] - station.yMillis,
      )
      if (distance < 100 || distance > 8000) {
        invalid(`metro entrance ${name}/${label} is implausibly placed`)
      }
    }
  }
  for (const expected of ['未来科学城北站', '未来科学城站']) {
    if (!stationNames.has(expected)) {
      invalid(`missing metro station ${expected}`)
    }
  }
}

function stableJson(value) {
  if (value === null || typeof value === 'boolean' || typeof value === 'string') {
    return JSON.stringify(value)
  }
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) {
      invalid('digest payload contains a non-finite number')
    }
    return JSON.stringify(value)
  }
  if (Array.isArray(value)) {
    return `[${value.map(stableJson).join(',')}]`
  }
  if (value && typeof value === 'object') {
    return `{${Object.keys(value)
      .sort()
      .map(key => `${JSON.stringify(key)}:${stableJson(value[key])}`)
      .join(',')}}`
  }
  invalid('digest payload contains an unsupported value')
}

function digestPayload(transport) {
  return Object.fromEntries(DIGEST_KEYS.map(key => [key, transport[key]]))
}

export function validateEnergyValleyTransportStructure(transport) {
  requireObject(transport, 'root')
  if (transport.schema !== ENERGY_VALLEY_TRANSPORT_SCHEMA) {
    invalid(`schema must be ${ENERGY_VALLEY_TRANSPORT_SCHEMA}`)
  }
  validateGrid(transport.grid)
  requireObject(transport.provenance, 'provenance')
  if (!/^sha256:[0-9a-f]{64}$/.test(transport.payloadSha256 || '')) {
    invalid('payloadSha256 must be a lowercase SHA-256 digest')
  }
  for (const field of FORBIDDEN_MAP_FIELDS) {
    if (Object.hasOwn(transport, field)) {
      invalid(`${field} is forbidden in the transport-only envelope`)
    }
  }
  const ids = new Set()
  validatePolylineRecords(transport.displayRoads, 'displayRoads', 1, 1024, transport.grid, ids)
  validatePolylineRecords(transport.bridges, 'bridges', 0, 256, transport.grid, ids)
  validateMetro(transport.metro, transport.grid)
  return transport
}

export async function energyValleyTransportPayloadSha256(
  transport,
  cryptoImpl = globalThis.crypto,
) {
  if (!cryptoImpl?.subtle) {
    invalid('Web Crypto SHA-256 is unavailable')
  }
  const text = stableJson(digestPayload(transport))
  const bytes = new TextEncoder().encode(text)
  const digest = await cryptoImpl.subtle.digest('SHA-256', bytes)
  const hex = Array.from(new Uint8Array(digest), byte =>
    byte.toString(16).padStart(2, '0')).join('')
  return `sha256:${hex}`
}

export async function validateEnergyValleyTransport(
  transport,
  cryptoImpl = globalThis.crypto,
) {
  validateEnergyValleyTransportStructure(transport)
  const actualDigest = await energyValleyTransportPayloadSha256(transport, cryptoImpl)
  if (actualDigest !== transport.payloadSha256) {
    invalid('payloadSha256 does not match the canonical payload')
  }
  return transport
}

export async function loadEnergyValleyTransport(options = {}) {
  const fetchImpl = options.fetchImpl || globalThis.fetch
  const cryptoImpl = options.cryptoImpl || globalThis.crypto
  const now = options.now || Date.now
  const timeoutMs = options.timeoutMs ?? FETCH_TIMEOUT_MS
  let accepted = null
  let timeout = null
  try {
    if (typeof fetchImpl !== 'function') {
      invalid('fetch is unavailable')
    }
    const controller = new AbortController()
    timeout = setTimeout(() => controller.abort(), timeoutMs)
    const response = await fetchImpl(
      `${ENERGY_VALLEY_TRANSPORT_SNAPSHOT.url}?ts=${now()}`,
      { cache: 'no-store', signal: controller.signal },
    )
    if (!response?.ok || typeof response.text !== 'function') {
      invalid('transport fetch failed')
    }
    const text = await response.text()
    if (new TextEncoder().encode(text).byteLength > ENERGY_VALLEY_TRANSPORT_MAX_BYTES) {
      invalid('transport exceeds the 512 KiB runtime limit')
    }
    accepted = await validateEnergyValleyTransport(JSON.parse(text), cryptoImpl)
  } catch {
    accepted = null
  } finally {
    if (timeout !== null) {
      clearTimeout(timeout)
    }
  }
  globalThis[ENERGY_VALLEY_TRANSPORT_SNAPSHOT.jsonGlobal] = accepted
  return accepted
}
