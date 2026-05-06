import { defineConfig } from 'vite'
import rabbita from '@rabbita/vite'
import { existsSync } from 'node:fs'
import { mkdir, readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'

const townSnapshotPath = path.resolve(process.cwd(), '../../.moontown/town.json')

function moontownSnapshotPlugin() {
  return {
    name: 'moontown-town-snapshot',
    configureServer(server) {
      server.middlewares.use('/town.json', async (_req, res) => {
        if (!existsSync(townSnapshotPath)) {
          res.statusCode = 404
          res.setHeader('Content-Type', 'application/json')
          res.end('{"error":"missing town snapshot"}')
          return
        }

        const contents = await readFile(townSnapshotPath, 'utf8')
        res.statusCode = 200
        res.setHeader('Content-Type', 'application/json')
        res.end(contents)
      })
    },
    async closeBundle() {
      if (!existsSync(townSnapshotPath)) {
        return
      }

      const distDir = path.resolve(process.cwd(), 'dist')
      await mkdir(distDir, { recursive: true })
      await writeFile(
        path.join(distDir, 'town.json'),
        await readFile(townSnapshotPath, 'utf8'),
        'utf8',
      )
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
