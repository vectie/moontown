import { spawn } from 'node:child_process'
import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises'
import net from 'node:net'
import os from 'node:os'
import path from 'node:path'

async function availablePort() {
  const server = net.createServer()
  await new Promise((resolve, reject) => {
    server.once('error', reject)
    server.listen(0, '127.0.0.1', resolve)
  })
  const address = server.address()
  const port = typeof address === 'object' && address ? address.port : 4179
  await new Promise(resolve => server.close(resolve))
  return port
}

async function waitForServer(url, child) {
  for (let attempt = 0; attempt < 80; attempt += 1) {
    if (child.exitCode !== null) {
      throw new Error(`Vite exited before smoke verification (${child.exitCode})`)
    }
    try {
      const response = await fetch(url)
      if (response.ok) return
    } catch {
      // The server is still starting.
    }
    await new Promise(resolve => setTimeout(resolve, 100))
  }
  throw new Error('Timed out waiting for the Rabbita development server')
}

const suiteRoot = await mkdtemp(path.join(os.tmpdir(), 'moontown-ui-e2e-'))
const stateRoot = path.join(suiteRoot, '.moonsuite', 'products', 'moontown')
await mkdir(stateRoot, { recursive: true })
await writeFile(path.join(stateRoot, 'town.json'), JSON.stringify({
  town: {
    config: {
      id: 'wenyu-e2e',
      name: 'Wenyu Valley / AI Innovation Town',
      heartbeat_seconds: 30,
      max_concurrent_tasks: 12,
    },
    books: [],
    workers: [],
    tasks: [],
    executions: [],
    events: [{
      id: 'e2e-ready',
      kind: 'runtime-ready',
      detail: 'End-to-end live projection ready.',
      related_task_id: null,
      related_book_id: null,
      related_proposal_id: null,
      related_run_id: null,
    }],
  },
  event_count: 1,
}), 'utf8')

const port = await availablePort()
const baseUrl = `http://127.0.0.1:${port}`
const child = spawn(
  process.execPath,
  ['./node_modules/vite/bin/vite.js', '--host', '127.0.0.1', '--port', String(port)],
  {
    cwd: path.resolve(import.meta.dirname, '..'),
    env: {
      ...process.env,
      MOONTOWN_SUITE_ROOT: suiteRoot,
      MOONTOWN_PRODUCT_STATE_ROOT: stateRoot,
    },
    stdio: ['ignore', 'pipe', 'pipe'],
  },
)

let stderr = ''
child.stderr.on('data', chunk => {
  stderr += chunk.toString()
})

try {
  await waitForServer(baseUrl, child)
  process.env.MOONTOWN_SMOKE_BASE_URL = baseUrl
  process.env.MOONTOWN_PRODUCT_STATE_ROOT = stateRoot
  process.env.MOONTOWN_SMOKE_SUFFIX = String(Date.now())
  await import(`./smoke-user-workflows.mjs?run=${Date.now()}`)
} finally {
  child.kill('SIGTERM')
  await new Promise(resolve => {
    if (child.exitCode !== null) resolve()
    else child.once('exit', resolve)
  })
  await rm(suiteRoot, { recursive: true, force: true })
}

if (stderr.trim()) {
  console.error(stderr.trim())
}
