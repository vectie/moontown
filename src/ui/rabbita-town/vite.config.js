import { defineConfig } from 'vite'
import rabbita from '@rabbita/vite'
import path from 'node:path'
import {
  handleBookTemplateRequest,
  handleOperatorRequest,
} from './vite_api_handlers.js'
import { serveBookOutput } from './vite_book_output.js'
import { loadModuleProjectionIndex } from './vite_book_projections.js'
import { loadMoondeskBridgeIndex } from './vite_moondesk_bridge.js'
import {
  bookTemplateRequestPath,
  civicStatusPath,
  daemonSnapshotPath,
  editorPipelinePath,
  liveAutonomyPath,
  liveDigestPath,
  operatorRequestLedgerPath,
  standingGoalsPath,
  townSnapshotPath,
  visualProjectionPath,
  watcherDir,
} from './vite_server_paths.js'
import {
  rejectUnsafeWrite,
  safeSegment,
  sendJson,
  serveJsonFile,
  serveTextFile,
} from './vite_server_io.js'
import { exportStaticRuntimeBundle } from './vite_static_export.js'
import {
  loadWatcherLedgerIndex,
  serveJsonlAsArray,
} from './vite_watcher_ledgers.js'

function moontownSnapshotPlugin() {
  return {
    name: 'moontown-town-snapshot',
    configureServer(server) {
      server.middlewares.use('/town.json', async (_req, res) => {
        await serveJsonFile(res, townSnapshotPath, 'missing town snapshot')
      })
      server.middlewares.use('/visual-projection.json', async (_req, res) => {
        await serveJsonFile(res, visualProjectionPath, 'missing visual projection')
      })
      server.middlewares.use('/module-projections.json', async (_req, res) => {
        sendJson(res, await loadModuleProjectionIndex())
      })
      server.middlewares.use('/moondesk-bridge.json', async (_req, res) => {
        sendJson(res, await loadMoondeskBridgeIndex())
      })
      server.middlewares.use('/civic-status.json', async (_req, res) => {
        await serveJsonFile(res, civicStatusPath, 'missing civic status')
      })
      server.middlewares.use('/book-output', async (req, res) => {
        await serveBookOutput(req, res)
      })
      server.middlewares.use('/daemon.json', async (_req, res) => {
        await serveJsonFile(res, daemonSnapshotPath, 'missing daemon snapshot')
      })
      server.middlewares.use('/live-autonomy.json', async (_req, res) => {
        await serveJsonFile(res, liveAutonomyPath, 'missing live autonomy spine')
      })
      server.middlewares.use('/editor-pipeline.json', async (_req, res) => {
        await serveJsonFile(res, editorPipelinePath, 'missing editor pipeline')
      })
      server.middlewares.use('/live-digest.md', async (_req, res) => {
        await serveTextFile(
          res,
          liveDigestPath,
          'missing live digest',
          'text/markdown; charset=utf-8',
        )
      })
      server.middlewares.use('/standing-goals.json', async (_req, res) => {
        await serveJsonFile(res, standingGoalsPath, 'missing standing goals')
      })
      server.middlewares.use('/watchers', async (req, res) => {
        const pathname = new URL(req.url || '/', 'http://moontown.local').pathname
        if (pathname === '/index.json' || pathname === '/index') {
          sendJson(res, await loadWatcherLedgerIndex())
          return
        }

        const requested = safeSegment(pathname.replace(/^\//, '').replace(/\.jsonl$/, ''))
        const filePath = path.join(watcherDir, `${requested}.jsonl`)
        await serveJsonlAsArray(res, filePath)
      })
      server.middlewares.use('/operator-requests.json', async (_req, res) => {
        await serveJsonlAsArray(res, operatorRequestLedgerPath)
      })
      server.middlewares.use('/book-template-requests.json', async (_req, res) => {
        await serveJsonFile(
          res,
          bookTemplateRequestPath,
          'missing book template requests',
        )
      })
      server.middlewares.use('/api/operator-requests', async (req, res) => {
        if (rejectUnsafeWrite(req, res)) {
          return
        }

        await handleOperatorRequest(req, res)
      })
      server.middlewares.use('/api/book-template-requests', async (req, res) => {
        if (rejectUnsafeWrite(req, res)) {
          return
        }

        await handleBookTemplateRequest(req, res)
      })
    },
    async closeBundle() {
      await exportStaticRuntimeBundle()
    },
  }
}

export default defineConfig({
  base: './',
  publicDir: '../assets',
  plugins: [rabbita(), moontownSnapshotPlugin()],
  build: {
    copyPublicDir: false,
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
    host: '127.0.0.1',
    fs: { allow: ['..', '../..', '../../..'] },
  },
})
