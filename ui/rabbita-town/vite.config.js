import { defineConfig } from 'vite'
import rabbita from '@rabbita/vite'
import { existsSync } from 'node:fs'
import { mkdir, readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'

const townSnapshotPath = path.resolve(process.cwd(), '../../.moontown/town.json')
const daemonSnapshotPath = path.resolve(process.cwd(), '../../.moontown/daemon.json')

function serveJsonSnapshot(res, snapshotPath, missingMessage) {
  if (!existsSync(snapshotPath)) {
    res.statusCode = 404
    res.setHeader('Content-Type', 'application/json')
    res.end(`{"error":"${missingMessage}"}`)
    return false
  }

  return true
}

function moontownSnapshotPlugin() {
  return {
    name: 'moontown-town-snapshot',
    configureServer(server) {
      server.middlewares.use('/town.json', async (_req, res) => {
        if (!serveJsonSnapshot(res, townSnapshotPath, 'missing town snapshot')) {
          return
        }

        const contents = await readFile(townSnapshotPath, 'utf8')
        res.statusCode = 200
        res.setHeader('Content-Type', 'application/json')
        res.end(contents)
      })
      server.middlewares.use('/daemon.json', async (_req, res) => {
        if (!serveJsonSnapshot(res, daemonSnapshotPath, 'missing daemon snapshot')) {
          return
        }

        const contents = await readFile(daemonSnapshotPath, 'utf8')
        res.statusCode = 200
        res.setHeader('Content-Type', 'application/json')
        res.end(contents)
      })
    },
    async closeBundle() {
      const distDir = path.resolve(process.cwd(), 'dist')
      await mkdir(distDir, { recursive: true })

      if (existsSync(townSnapshotPath)) {
        await writeFile(
          path.join(distDir, 'town.json'),
          await readFile(townSnapshotPath, 'utf8'),
          'utf8',
        )
      }

      if (existsSync(daemonSnapshotPath)) {
        await writeFile(
          path.join(distDir, 'daemon.json'),
          await readFile(daemonSnapshotPath, 'utf8'),
          'utf8',
        )
      }
    },
  }
}

export default defineConfig({
  base: './',
  publicDir: '../assets',
  plugins: [rabbita(), moontownSnapshotPlugin()],
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes('node_modules')) {
            if (id.includes('@rabbita')) return 'rabbita-vendor'
            return 'vendor'
          }
        },
      },
    },
  },
  server: {
    host: true,
    fs: { allow: ['..', '../..', '../../..'] },
  },
})
