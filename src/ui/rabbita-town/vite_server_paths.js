import path from 'node:path'

const moontownRootPath = path.resolve(process.cwd(), '../../.moontown')

export const townSnapshotPath = path.join(moontownRootPath, 'town.json')
export const visualProjectionPath = path.join(moontownRootPath, 'visual-projection.json')
export const liveAutonomyPath = path.join(moontownRootPath, 'live-autonomy.json')
export const liveDigestPath = path.join(moontownRootPath, 'live-digest.md')
export const editorPipelinePath = path.join(moontownRootPath, 'editor-pipeline.json')
export const daemonSnapshotPath = path.join(moontownRootPath, 'daemon.json')
export const standingGoalsPath = path.join(moontownRootPath, 'standing-goals.json')
export const bookTemplateRequestPath = path.join(
  moontownRootPath,
  'book-template-requests.json',
)
export const bookTemplateConfigDir = path.join(moontownRootPath, 'book-template-configs')
export const civicStatusPath = path.join(moontownRootPath, 'civic/status.json')
export const watcherDir = path.join(moontownRootPath, 'watchers')
export const operatorRequestDir = path.join(moontownRootPath, 'operator-requests')
export const operatorRequestLedgerPath = path.join(operatorRequestDir, 'requests.jsonl')
export const booksRootPath = path.join(moontownRootPath, 'books')
export const bookProjectionPolicyPath = path.join(
  moontownRootPath,
  'book-projection-policy.json',
)
export const bookResultDir = path.join(moontownRootPath, 'book-results')
export const moondeskDispatchDir = path.join(moontownRootPath, 'moondesk-dispatches')
export const moondeskRequestDir = path.join(moontownRootPath, 'moondesk-requests')

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
