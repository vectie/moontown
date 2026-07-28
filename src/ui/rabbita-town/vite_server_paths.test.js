import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import path from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'
import test from 'node:test'

const moduleUrl = pathToFileURL(
  path.join(path.dirname(fileURLToPath(import.meta.url)), 'vite_server_paths.js'),
).href

function suiteRootForEnvironment(overrides) {
  const {
    MOONTOWN_SUITE_ROOT: _moontownSuiteRoot,
    MOONSUITE_ROOT: _moonsuiteRoot,
    ...baseEnvironment
  } = process.env
  const result = spawnSync(
    process.execPath,
    [
      '--input-type=module',
      '--eval',
      `const { suiteRootPath } = await import(${JSON.stringify(moduleUrl)}); process.stdout.write(suiteRootPath)`,
    ],
    {
      encoding: 'utf8',
      env: { ...baseEnvironment, ...overrides },
    },
  )
  assert.equal(result.status, 0, result.stderr)
  return result.stdout
}

test('server paths keep runtime state out of the source checkout by default', () => {
  assert.equal(
    suiteRootForEnvironment({ HOME: '/tmp/moontown-path-home' }),
    '/tmp/moontown-path-home/moonsuite',
  )
})

test('server paths accept the shared MoonSuite root', () => {
  assert.equal(
    suiteRootForEnvironment({
      HOME: '/tmp/moontown-path-home',
      MOONSUITE_ROOT: '/tmp/shared-suite',
    }),
    '/tmp/shared-suite',
  )
})

test('MoonTown-specific suite root takes precedence', () => {
  assert.equal(
    suiteRootForEnvironment({
      HOME: '/tmp/moontown-path-home',
      MOONSUITE_ROOT: '/tmp/shared-suite',
      MOONTOWN_SUITE_ROOT: '/tmp/moontown-suite',
    }),
    '/tmp/moontown-suite',
  )
})
