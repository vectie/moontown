import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'
import {
  ENERGY_VALLEY_TRANSPORT_MAX_BYTES,
  energyValleyTransportPayloadSha256,
  loadEnergyValleyTransport,
  validateEnergyValleyTransport,
  validateEnergyValleyTransportStructure,
} from './energy_valley_transport.js'

async function transportFixture() {
  const transport = {
    schema: 'moontown.energy-valley.transport.v1',
    grid: {
      width: 256,
      height: 144,
      bboxWgs84: {
        west: 116.39,
        south: 40.09,
        east: 116.52,
        north: 40.145,
      },
      sourceCrs: 'EPSG:4326',
      coordinateScale: 1000,
      presentationTransform: {
        type: 'similarity',
        sourceProjection: 'wide-bbox-linear',
        coefficient: {
          real: 0.881736491,
          imaginary: -0.1526026344,
        },
        translation: {
          x: -7.698386279,
          y: 38.405074113,
        },
        scale: 0.8948445695,
        rotationDegrees: -9.818947,
        anchors: [
          {
            name: '未来科学城北站',
            sourceMillis: [143529, 40259],
            targetMillis: [125000, 52000],
          },
          {
            name: '未来科学城站',
            sourceMillis: [138320, 80186],
            targetMillis: [126500, 88000],
          },
        ],
      },
    },
    displayRoads: [
      {
        id: 'road-0000',
        class: 'arterial',
        detail: 'mainline',
        name: 'Future Science City Road',
        bounds: [1000, 2000, 9000, 7000],
        points: [[1000, 2000], [5000, 3000], [9000, 7000]],
      },
    ],
    bridges: [
      {
        id: 'bridge-0000',
        class: 'collector',
        detail: 'mainline',
        name: 'Wenyu Bridge',
        bounds: [20000, 30000, 24000, 34000],
        points: [[20000, 30000], [24000, 34000]],
      },
    ],
    metro: {
      lineId: 'beijing-metro-line-17',
      path: [[140000, 0], [139000, 40000], [138000, 143000]],
      stations: [
        {
          name: '未来科学城北站',
          xMillis: 140000,
          yMillis: 40000,
          exits: [
            {
              label: 'B',
              destination: '英才北一街',
              sourceNodeId: 11745945903,
              xMillis: 141000,
              yMillis: 40500,
            },
          ],
        },
        {
          name: '未来科学城站',
          xMillis: 138000,
          yMillis: 80000,
          exits: [
            {
              label: 'A',
              destination: '英才南一街',
              sourceNodeId: 11471886526,
              xMillis: 137000,
              yMillis: 79500,
            },
          ],
        },
      ],
    },
    provenance: {
      source: 'test fixture',
      generatedAt: '2026-08-09T00:00:00Z',
    },
    payloadSha256: `sha256:${'0'.repeat(64)}`,
  }
  transport.payloadSha256 = await energyValleyTransportPayloadSha256(transport)
  return transport
}

function jsonResponse(text, ok = true) {
  return {
    ok,
    async text() {
      return text
    },
  }
}

test('valid transport loads atomically into the transport-only global', async () => {
  const transport = await transportFixture()
  const requests = []
  delete globalThis.__moontownEnergyValleyTransport

  const accepted = await loadEnergyValleyTransport({
    fetchImpl: async (url, options) => {
      requests.push({ url, options })
      return jsonResponse(JSON.stringify(transport))
    },
    now: () => 42,
  })

  assert.deepEqual(accepted, transport)
  assert.strictEqual(globalThis.__moontownEnergyValleyTransport, accepted)
  assert.equal(requests.length, 1)
  assert.equal(
    requests[0].url,
    './tilemap/energy-valley-transport-v1.json?ts=42',
  )
  assert.equal(requests[0].options.cache, 'no-store')
  assert.ok(requests[0].options.signal instanceof AbortSignal)
  delete globalThis.__moontownEnergyValleyTransport
})

test('structural validator rejects malformed or mixed-geography transport', async () => {
  const baseline = await transportFixture()
  const cases = [
    transport => {
      transport.schema = 'moontown.energy-valley.layout.v1'
    },
    transport => {
      transport.displayRoads[0].class = 'service'
    },
    transport => {
      transport.displayRoads[0].detail = 'interchange'
    },
    transport => {
      transport.displayRoads[0].bounds[2] -= 1
    },
    transport => {
      transport.bridges[0].id = transport.displayRoads[0].id
    },
    transport => {
      transport.metro.stations.pop()
    },
    transport => {
      transport.metro.stations[0].exits[0].sourceNodeId =
        transport.metro.stations[1].exits[0].sourceNodeId
    },
    transport => {
      transport.metro.stations[0].exits[0].xMillis = 200000
    },
    transport => {
      transport.grid.presentationTransform.anchors[0].targetMillis[0] += 1
    },
    transport => {
      transport.terrainRows = Array(144).fill('.'.repeat(256))
    },
  ]

  for (const mutate of cases) {
    const candidate = structuredClone(baseline)
    mutate(candidate)
    assert.throws(() => validateEnergyValleyTransportStructure(candidate))
  }

})

test('canonical digest covers only transport fields and is key-order stable', async () => {
  const transport = await transportFixture()
  const reordered = JSON.parse(JSON.stringify(transport), (key, value) => {
    if (!value || Array.isArray(value) || typeof value !== 'object') {
      return value
    }
    return Object.fromEntries(Object.entries(value).reverse())
  })
  reordered.provenance = { source: 'a different authoring note' }

  assert.equal(
    await energyValleyTransportPayloadSha256(reordered),
    transport.payloadSha256,
  )

  reordered.displayRoads[0].points[1][0] += 1
  reordered.displayRoads[0].bounds = [1000, 2000, 9000, 7000]
  await assert.rejects(
    validateEnergyValleyTransport(reordered),
    /payloadSha256 does not match/,
  )
})

test('fetch, size, parse, and digest failures clear stale transport authority', async () => {
  const valid = await transportFixture()
  const invalidDigest = structuredClone(valid)
  invalidDigest.payloadSha256 = `sha256:${'f'.repeat(64)}`
  const bodies = [
    '{',
    JSON.stringify({ schema: valid.schema, grid: valid.grid }),
    JSON.stringify(invalidDigest),
    ' '.repeat(ENERGY_VALLEY_TRANSPORT_MAX_BYTES + 1),
  ]

  for (const body of bodies) {
    globalThis.__moontownEnergyValleyTransport = { stale: true }
    const accepted = await loadEnergyValleyTransport({
      fetchImpl: async () => jsonResponse(body),
      now: () => 7,
    })
    assert.equal(accepted, null)
    assert.equal(globalThis.__moontownEnergyValleyTransport, null)
  }

  globalThis.__moontownEnergyValleyTransport = { stale: true }
  assert.equal(
    await loadEnergyValleyTransport({
      fetchImpl: async () => jsonResponse('', false),
    }),
    null,
  )
  assert.equal(globalThis.__moontownEnergyValleyTransport, null)
  delete globalThis.__moontownEnergyValleyTransport
})

test('checked-in transport is compact, digest-valid, and contains no map replacement', async () => {
  const text = await readFile(
    new URL('../assets/tilemap/energy-valley-transport-v1.json', import.meta.url),
    'utf8',
  )
  assert.ok(new TextEncoder().encode(text).byteLength <= ENERGY_VALLEY_TRANSPORT_MAX_BYTES)
  const transport = JSON.parse(text)
  await validateEnergyValleyTransport(transport)
  for (const rejected of ['terrainRows', 'roadRows', 'structures', 'modules', 'landmarks']) {
    assert.equal(Object.hasOwn(transport, rejected), false)
  }
  assert.equal(transport.displayRoads.length, 280)
  assert.equal(transport.bridges.length, 58)
  const allRoads = [...transport.displayRoads, ...transport.bridges]
  assert.equal(allRoads.filter(record => record.detail === 'mainline').length, 283)
  assert.equal(allRoads.filter(record => record.detail === 'ramp').length, 55)
  assert.equal(
    allRoads.every(record => ['mainline', 'ramp'].includes(record.detail)),
    true,
  )
  assert.equal(transport.grid.presentationTransform.type, 'similarity')
  assert.equal(transport.grid.presentationTransform.scale, 0.8948445695)
  assert.deepEqual(
    transport.grid.presentationTransform.anchors.map(anchor => [
      anchor.name,
      anchor.sourceMillis,
      anchor.targetMillis,
    ]),
    [
      ['未来科学城北站', [143529, 40259], [125000, 52000]],
      ['未来科学城站', [138320, 80186], [126500, 88000]],
    ],
  )
  assert.deepEqual(
    transport.metro.stations.map(station => [
      station.name,
      station.xMillis,
      station.yMillis,
    ]),
    [
      ['未来科学城北站', 125000, 52000],
      ['未来科学城站', 126500, 88000],
    ],
  )
  assert.deepEqual(
    transport.metro.stations.map(station => [
      station.name,
      station.exits.map(exit => exit.label),
    ]),
    [
      ['未来科学城北站', ['B', 'C', 'D']],
      ['未来科学城站', ['A', 'B', 'C', 'D']],
    ],
  )
})
