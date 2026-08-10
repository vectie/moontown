import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'

const rendererUrl = new URL(
  './main/authoritative_energy_valley_road_renderer.mbt',
  import.meta.url,
)
const pageUrl = new URL('./main/energy_valley_page.mbt', import.meta.url)
const townLifeCssUrl = new URL('./styles/town-life.css', import.meta.url)

test('transport renderer pins overview hierarchy, clipping, and grounded bridges', async () => {
  const source = await readFile(rendererUrl, 'utf8')
  assert.match(source, /record\?\.class === "collector" && zoom >= 0\.60/)
  assert.match(source, /record\?\.class === "local" && zoom >= 0\.78/)
  assert.match(source, /record\?\.detail === "ramp" && zoom < 0\.72/)
  assert.match(source, /roadClass !== "local" && zoom >= 0\.65/)
  assert.match(source, /casingWidth: Math\.max\(4\.4, 8\.2 \* zoom\)/)
  assert.match(source, /asphaltWidth: Math\.max\(2\.5, 5\.2 \* zoom\)/)
  assert.match(source, /overviewMainlines/)
  assert.match(source, /context\.lineWidth = Math\.max\(7\.0, 13\.5 \* zoom\)/)
  assert.match(source, /style\.casingWidth \+ Math\.max\(1\.4, 2\.5 \* zoom\)/)
  assert.match(source, /context\.clip\("evenodd"\)/)
  assert.match(source, /const bridgeRoads = bridgeIndices/)
  assert.doesNotMatch(source, /context\.translate\(/)
  assert.doesNotMatch(source, /elevation shadow|elevated spans/)
})

test('transport attribution stays linked and clear of responsive controls', async () => {
  const [page, css] = await Promise.all([
    readFile(pageUrl, 'utf8'),
    readFile(townLifeCssUrl, 'utf8'),
  ])
  assert.match(page, /authoritative_energy_valley_transport_ready\(\)/)
  assert.match(page, /https:\/\/www\.openstreetmap\.org\/copyright/)
  assert.match(page, /© OpenStreetMap contributors/)
  assert.match(
    css,
    /bottom: calc\(78px \+ var\(--town-safe-bottom, 0px\)\)/,
  )
  assert.match(css, /@media \(max-width: 680px\)[\s\S]*?bottom: calc\(164px/)
  assert.match(
    css,
    /@media \(orientation: landscape\) and \(max-height: 430px\)[\s\S]*?bottom: calc\(64px/,
  )
})
