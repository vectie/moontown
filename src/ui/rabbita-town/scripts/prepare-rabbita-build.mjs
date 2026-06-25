import { spawnSync } from 'node:child_process'
import { copyFileSync, existsSync, mkdirSync } from 'node:fs'
import path from 'node:path'

const root = path.resolve(new URL('..', import.meta.url).pathname)
const buildRoot = path.join(root, '_build')

function runMoonBuild(mode) {
  const result = spawnSync(
    'moon',
    ['build', '--target', 'js', mode === 'release' ? '--release' : '--debug'],
    { cwd: root, encoding: 'utf8', stdio: 'inherit' },
  )
  if (result.status !== 0) {
    process.exit(result.status ?? 1)
  }
}

function syncPackageMetadata(mode) {
  const source = path.join(buildRoot, 'js', mode, 'build', 'all_pkgs.json')
  const target = path.join(buildRoot, 'packages.json')
  if (!existsSync(source)) {
    throw new Error(`Missing MoonBit package metadata: ${source}`)
  }
  mkdirSync(buildRoot, { recursive: true })
  copyFileSync(source, target)
}

runMoonBuild('release')
syncPackageMetadata('release')
