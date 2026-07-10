import path from 'node:path'
import { fileURLToPath } from 'node:url'

const rabbitaTownDir = path.dirname(fileURLToPath(import.meta.url))
const repoRootPath = path.resolve(rabbitaTownDir, '../../..')
const suiteRootPath = path.resolve(process.env.MOONTOWN_SUITE_ROOT || repoRootPath)

export const publicAssetRootPath = path.resolve(rabbitaTownDir, '../assets')

export const moontownProductStatePath = path.resolve(
  process.env.MOONTOWN_PRODUCT_STATE_ROOT ||
    path.join(suiteRootPath, '.moonsuite/products/moontown'),
)

export const townSnapshotPath = path.join(moontownProductStatePath, 'town.json')
export const visualProjectionPath = path.join(
  moontownProductStatePath,
  'visual-projection.json',
)
export const liveAutonomyPath = path.join(moontownProductStatePath, 'live-autonomy.json')
export const liveDigestPath = path.join(moontownProductStatePath, 'live-digest.md')
export const editorPipelinePath = path.join(
  moontownProductStatePath,
  'editor-pipeline.json',
)
export const daemonSnapshotPath = path.join(moontownProductStatePath, 'daemon.json')
export const standingGoalsPath = path.join(moontownProductStatePath, 'standing-goals.json')
export const bookTemplateRequestPath = path.join(
  moontownProductStatePath,
  'book-template-requests.json',
)
export const bookTemplateConfigDir = path.join(
  moontownProductStatePath,
  'book-template-configs',
)
export const civicStatusPath = path.join(moontownProductStatePath, 'civic/status.json')
export const watcherDir = path.join(moontownProductStatePath, 'watchers')
export const operatorRequestDir = path.join(moontownProductStatePath, 'operator-requests')
export const operatorRequestLedgerPath = path.join(operatorRequestDir, 'requests.jsonl')
export const booksRootPath = path.resolve(
  process.env.MOONTOWN_BOOKS_ROOT || path.join(suiteRootPath, 'books'),
)
export const bookProjectionPolicyPath = path.join(
  moontownProductStatePath,
  'book-projection-policy.json',
)
export const operatorRequestPolicyPath = path.resolve(
  repoRootPath,
  'assets/templates/operator-request-policy.json',
)
export const bookResultDir = path.join(moontownProductStatePath, 'book-results')
export const moondeskDispatchDir = path.join(
  moontownProductStatePath,
  'moondesk-dispatches',
)
export const moondeskRequestDir = path.join(
  moontownProductStatePath,
  'moondesk-requests',
)

export const moondeskRootPath = path.resolve(process.cwd(), '../../../moondesk')

export const keyBookOutputFiles = [
  'book/Home.html',
  'book/index.html',
  'book/site/generated/index.html',
  'book/synthesis/report.html',
  'book/synthesis/overview.html',
  'book/synthesis/evidence.html',
  'book/reviews/pending.html',
]
