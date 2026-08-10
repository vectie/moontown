import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'

const cssUrl = new URL('./energy-valley-life-hud.css', import.meta.url)

test('MoonTown HUD keeps its own palette and town-state disclosure', async () => {
  const css = await readFile(cssUrl, 'utf8')
  const marker = '/* Final MoonTown responsive authority'
  const authorityStart = css.indexOf(marker)

  assert.notEqual(authorityStart, -1)
  assert.ok(authorityStart > css.indexOf('/* MoonTown progressive disclosure'))
  assert.match(css, /--town-panel: #27362d;/)
  assert.match(css, /\.town-topbar-town-state/)
  assert.match(
    css,
    /\.town-topbar-leading,\n\.town-topbar-trailing \{\n\s*min-height: 54px;\n\s*display: flex;\n\s*align-items: center;/,
  )
  assert.match(
    css,
    /\.town-tool-dock \{[\s\S]*?display: flex;\n\s*align-items: center;/,
  )
  assert.match(css, /--town-gold: #f2c94c;/)
  assert.match(css, /\.town-graduated \.moonclaw-pet,/)
  assert.doesNotMatch(css, /Contemporary civic HUD|#dceff3|--town-cyan/)
  assert.doesNotMatch(css, /top: calc\(188px|left: calc\(min\(340px/)
})

test('final mobile HUD authority keeps portrait and landscape lanes clear', async () => {
  const css = await readFile(cssUrl, 'utf8')
  const authority = css.slice(
    css.indexOf('/* Final MoonTown responsive authority'),
  )

  assert.match(authority, /@media \(max-width: 680px\)/)
  assert.match(
    authority,
    /@media \(orientation: landscape\) and \(max-height: 430px\)/,
  )
  assert.equal(
    [...authority.matchAll(/\.town-graduated \.town-quest-wrap,\n\s*\.town-graduated \.quest-tracker-done \{\n\s*display: none !important;/g)]
      .length,
    2,
  )
  assert.equal(
    [...authority.matchAll(/transform: translateX\(-50%\);/g)].length,
    2,
  )
  assert.equal(
    [...authority.matchAll(/bottom: calc\(100px \+ var\(--town-safe-bottom\)\);/g)]
      .length,
    2,
  )
  assert.equal(
    [...authority.matchAll(/\.town-actions\.town-utility-disclosure \{\n\s*position: absolute;\n\s*top: auto;/g)]
      .length,
    2,
  )
  assert.match(authority, /min-width: 48px;\n\s*min-height: 48px;/)
  assert.match(
    authority,
    /:has\(\.town-dock-more\[open\]\) \.town-player-wrap,[\s\S]*?visibility: hidden;\n\s*pointer-events: none;/,
  )
  assert.doesNotMatch(authority, /top: calc\(188px/)
})
