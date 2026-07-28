import type {
  AcceptedOperatorRequest,
  RuntimeProjection,
  RuntimeWorkItem,
  RuntimeWorkStatus,
} from '../runtime'
import { matchesAcceptedRequest } from '../runtime'

export type RuntimeViewPhase =
  | 'loading'
  | 'live'
  | 'unavailable'
  | 'error'
  | 'stale'

const ACTIVE_STATUSES = new Set<RuntimeWorkStatus>([
  'queued',
  'assigned',
  'running',
  'waiting_review',
  'blocked',
])

const STATUS_COPY: Record<RuntimeWorkStatus, { icon: string; label: string; tone: string }> = {
  queued: { icon: '○', label: '排队', tone: 'text-slate-300' },
  assigned: { icon: '→', label: '已派工', tone: 'text-sky-200' },
  running: { icon: '●', label: '执行中', tone: 'text-emerald-200' },
  waiting_review: { icon: '◇', label: '待评审', tone: 'text-amber-200' },
  completed: { icon: '✓', label: '已完成', tone: 'text-emerald-200' },
  failed: { icon: '×', label: '失败', tone: 'text-rose-200' },
  blocked: { icon: '!', label: '受阻', tone: 'text-orange-200' },
}

function phaseCopy(
  phase: RuntimeViewPhase,
  projection: RuntimeProjection | null,
): { label: string; detail: string; tone: string } {
  switch (phase) {
    case 'live':
      return {
        label: '真实运行',
        detail: projection?.tick === undefined ? '已连接 MoonTown' : `运行时 tick ${projection.tick}`,
        tone: 'bg-emerald-400',
      }
    case 'loading':
      return { label: '连接中', detail: '正在读取 MoonTown 运行时', tone: 'bg-sky-400' }
    case 'stale':
      return { label: '数据已过期', detail: '保留最后一次真实快照，不推测新工作', tone: 'bg-amber-400' }
    case 'error':
      return { label: '连接错误', detail: '地图可浏览；Agent 不会冒充执行任务', tone: 'bg-rose-400' }
    case 'unavailable':
      return { label: '演示模式', detail: '运行时未连接；移动仅为环境动画', tone: 'bg-slate-400' }
  }
}

function activeTasks(projection: RuntimeProjection | null): RuntimeWorkItem[] {
  return (projection?.tasks ?? []).filter(task => ACTIVE_STATUSES.has(task.status))
}

export function RuntimeWorkPanel(props: {
  phase: RuntimeViewPhase
  projection: RuntimeProjection | null
  error?: string
  onRefresh?: () => void
  onCreateRequest: () => void
  onSelectTask?: (task: RuntimeWorkItem) => void
  acceptedRequest?: AcceptedOperatorRequest
}) {
  const phase = phaseCopy(props.phase, props.projection)
  const active = activeTasks(props.projection)
  const recent = props.projection?.tasks.filter(task => !ACTIVE_STATUSES.has(task.status)).slice(0, 2) ?? []
  const tracked = props.acceptedRequest
    ? props.projection?.tasks.find(task =>
      matchesAcceptedRequest(task, props.acceptedRequest!),
    )
    : undefined
  const tasks = [
    ...(tracked ? [tracked] : []),
    ...active.filter(task => task.id !== tracked?.id).slice(0, tracked ? 3 : 4),
    ...recent.filter(task => task.id !== tracked?.id).slice(0, 2),
  ]

  return (
    <details className="runtime-work pointer-events-auto w-80 rounded-2xl border border-white/10 bg-slate-950/70 shadow-xl backdrop-blur-md">
      <summary className="flex min-h-11 cursor-pointer list-none items-center gap-2 rounded-2xl px-3 py-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-300/70">
        <span className={`h-2.5 w-2.5 rounded-full ${phase.tone}`} aria-hidden="true" />
        <span className="min-w-0 flex-1">
          <span className="block text-[11px] font-semibold text-slate-100">{phase.label}</span>
          <span className="block truncate text-[10px] text-slate-400">{phase.detail}</span>
        </span>
        <span className="rounded-lg bg-white/5 px-2 py-1 font-mono text-[10px] text-slate-300">
          {active.length} 项工作
        </span>
      </summary>

      <div className="border-t border-white/10 px-3 pb-3 pt-2">
        <div aria-live="polite" className="sr-only">
          {phase.label}，
          {props.phase === 'live'
            ? `${active.length} 项进行中的真实工作`
            : `最后一次快照包含 ${active.length} 项工作`}
        </div>

        {props.error && (
          <p role="alert" className="mb-2 rounded-lg bg-rose-500/10 px-2 py-1.5 text-[10px] leading-relaxed text-rose-200">
            {props.error}
          </p>
        )}

        {tasks.length === 0 ? (
          <p className="rounded-lg bg-white/[0.04] px-2 py-2 text-[10px] leading-relaxed text-slate-400">
            {props.phase === 'live'
              ? '运行时在线，目前没有排队或执行中的工作。'
              : '连接真实运行时后，任务、Agent、建筑和产物会在这里出现。'}
          </p>
        ) : (
          <div className="flex max-h-64 flex-col gap-1 overflow-y-auto">
            {tasks.map(task => {
              const status = STATUS_COPY[task.status]
              return (
                <button
                  key={task.id}
                  type="button"
                  onClick={() => props.onSelectTask?.(task)}
                  className={`min-h-11 rounded-lg px-2 py-2 text-left hover:bg-white/[0.07] focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-amber-300/60 ${
                    task.id === tracked?.id ? 'bg-amber-300/10 ring-1 ring-amber-300/20' : ''
                  }`}
                >
                  <span className="flex items-center gap-2">
                    <span className={`w-12 shrink-0 text-[10px] ${status.tone}`}>
                      {status.icon} {status.label}
                    </span>
                    <span className="min-w-0 flex-1 truncate text-[11px] text-slate-100">{task.title}</span>
                  </span>
                  <span className="mt-1 block truncate pl-14 text-[9px] text-slate-500">
                    {task.agentName ?? task.agentId ?? '待分配 Agent'}
                    {task.runId ? ` · ${task.runId}` : ''}
                    {task.artifacts.length > 0 ? ` · ${task.artifacts.length} 个产物` : ''}
                  </span>
                  {task.id === tracked?.id && (
                    <span className="mt-1 block pl-14 text-[9px] font-semibold text-amber-300">
                      Your accepted request
                    </span>
                  )}
                </button>
              )
            })}
          </div>
        )}

        {props.acceptedRequest && !tracked && (
          <div role="status" className="mt-2 rounded-lg bg-amber-300/10 px-2 py-2 text-[10px] leading-relaxed text-amber-100 ring-1 ring-amber-300/20">
            Accepted and queued. Waiting for runtime correlation.
            <span className="mt-1 block select-text break-all font-mono text-[9px] text-amber-200/70">
              {props.acceptedRequest.standingGoalId}
            </span>
          </div>
        )}

        <button
          type="button"
          onClick={props.onCreateRequest}
          className="mt-2 min-h-11 w-full rounded-lg bg-amber-300 text-[11px] font-bold text-slate-950 hover:bg-amber-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-100"
        >
          Create real work
        </button>

        {props.onRefresh && (
          <button
            type="button"
            onClick={props.onRefresh}
            className="mt-2 min-h-11 w-full rounded-lg bg-white/5 text-[10px] text-slate-300 hover:bg-white/10 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-amber-300/60"
          >
            立即刷新运行时
          </button>
        )}
      </div>
    </details>
  )
}
