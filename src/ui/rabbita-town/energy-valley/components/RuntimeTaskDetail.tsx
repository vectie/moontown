import { useEffect, useMemo, useRef, useState, type KeyboardEvent } from 'react'
import type {
  RuntimeAgent,
  RuntimeParticipantStatus,
  RuntimeProjectionPhase,
  RuntimeWorkItem,
  RuntimeWorkStatus,
  RuntimeTimestamp,
} from '../runtime/types'

const STATUS_LABEL: Record<RuntimeWorkStatus, string> = {
  queued: 'Queued',
  assigned: 'Assigned',
  running: 'Running',
  waiting_review: 'Waiting for review',
  completed: 'Completed',
  failed: 'Failed',
  blocked: 'Blocked',
}

const PARTICIPANT_STATUS_LABEL: Record<RuntimeParticipantStatus, string> = {
  ...STATUS_LABEL,
  unknown: 'Unknown',
}

const SOURCE_LABEL: Record<RuntimeWorkItem['source'], string> = {
  'town-runtime': 'Town runtime',
  'standing-goal': 'Standing goal',
  watcher: 'Watcher',
  'operator-request': 'Operator request',
}

const MAIN_STAGES: RuntimeWorkStatus[] = [
  'queued',
  'assigned',
  'running',
  'waiting_review',
  'completed',
]

function progressRows(task: RuntimeWorkItem) {
  const progress = task.progress
  if (!progress) return []
  return [
    ['Sources checked', progress.checkedSources],
    ['New sources', progress.newSources],
    ['Accepted facts', progress.acceptedFacts],
    ['Rejected facts', progress.rejectedFacts],
    ['Pages changed', progress.pagesChanged],
    ['Book changed', progress.bookChanged === undefined
      ? undefined
      : progress.bookChanged ? 'Yes' : 'No'],
  ].filter((row): row is [string, number | string] => row[1] !== undefined)
}

function timestampLabel(value: RuntimeTimestamp | undefined): string | undefined {
  if (value === undefined) return undefined
  const parsed = typeof value === 'number' ? value : Date.parse(value)
  if (!Number.isFinite(parsed)) return String(value)
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(parsed))
}

export function RuntimeTaskDetail(props: {
  task: RuntimeWorkItem
  agents: RuntimeAgent[]
  located: boolean
  phase: RuntimeProjectionPhase
  onClose: () => void
}) {
  const dialogRef = useRef<HTMLElement>(null)
  const [copied, setCopied] = useState(false)
  const collaborators = useMemo(
    () => props.agents.filter(agent =>
      agent.workItemId === props.task.id || agent.id === props.task.agentId,
    ),
    [props.agents, props.task.agentId, props.task.id],
  )
  const progress = progressRows(props.task)
  const currentStage = MAIN_STAGES.indexOf(props.task.status)

  useEffect(() => {
    dialogRef.current?.focus()
  }, [])

  async function copyRunId() {
    if (!props.task.runId) return
    try {
      await navigator.clipboard.writeText(props.task.runId)
      setCopied(true)
      window.setTimeout(() => setCopied(false), 1_600)
    } catch {
      setCopied(false)
    }
  }

  function onDialogKeyDown(event: KeyboardEvent<HTMLElement>) {
    event.stopPropagation()
    if (event.key === 'Escape') {
      event.preventDefault()
      props.onClose()
      return
    }
    if (event.key !== 'Tab') return
    const focusable = [...(dialogRef.current?.querySelectorAll<HTMLElement>(
      'button:not([disabled]), a[href]',
    ) ?? [])]
    if (focusable.length === 0) return
    const first = focusable[0]
    const last = focusable[focusable.length - 1]
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }

  return (
    <section
      ref={dialogRef}
      tabIndex={-1}
      role="dialog"
      aria-modal="true"
      aria-labelledby="runtime-task-detail-title"
      onKeyDown={onDialogKeyDown}
      className="runtime-task-detail pointer-events-auto w-full max-w-2xl overflow-y-auto rounded-2xl border border-white/10 bg-slate-950/95 p-5 shadow-2xl backdrop-blur-md focus:outline-none"
    >
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2 text-[10px]">
            <span className="rounded-full bg-sky-400/10 px-2 py-1 text-sky-200 ring-1 ring-sky-300/20">
              {STATUS_LABEL[props.task.status]}
            </span>
            <span className="text-slate-500">{SOURCE_LABEL[props.task.source]}</span>
          </div>
          <h2 id="runtime-task-detail-title" className="mt-2 text-[18px] font-bold leading-snug text-amber-100">
            {props.task.title}
          </h2>
          <p className={`mt-1 text-[11px] ${props.located ? 'text-emerald-300' : 'text-amber-300'}`}>
            {props.located
              ? `Located at ${props.task.buildingModuleKey}`
              : `Unlocated work · no completed building matches ${props.task.buildingModuleKey}`}
          </p>
        </div>
        <button
          type="button"
          aria-label="Close real work details"
          onClick={props.onClose}
          className="min-h-11 min-w-11 rounded-xl text-slate-400 hover:bg-white/10 hover:text-slate-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-300/70"
        >
          ✕
        </button>
      </div>

      <ol aria-label="Work lifecycle" className="mt-5 grid grid-cols-5 gap-1">
        {MAIN_STAGES.map((status, index) => {
          const active = status === props.task.status
          const passed = currentStage >= 0 && index < currentStage
          return (
            <li
              key={status}
              aria-current={active ? 'step' : undefined}
              className={`rounded-lg px-1 py-2 text-center text-[9px] ${
                active
                  ? 'bg-amber-300/20 text-amber-100 ring-1 ring-amber-300/40'
                  : passed
                    ? 'bg-emerald-400/10 text-emerald-300'
                    : 'bg-white/[0.03] text-slate-600'
              }`}
            >
              {STATUS_LABEL[status]}
            </li>
          )
        })}
      </ol>
      {(props.task.status === 'blocked' || props.task.status === 'failed') && (
        <p role="status" className="mt-2 rounded-lg bg-rose-500/10 px-3 py-2 text-[11px] text-rose-200">
          This work is {STATUS_LABEL[props.task.status].toLowerCase()}; inspect
          the summary and runtime evidence before retrying.
        </p>
      )}
      {props.phase !== 'live' && (
        <p role="status" className="mt-2 rounded-lg bg-amber-300/10 px-3 py-2 text-[11px] text-amber-100">
          This is the last genuine task snapshot. Runtime phase is {props.phase};
          no newer work state is inferred.
        </p>
      )}

      <div className="mt-5 grid gap-4 sm:grid-cols-2">
        <section aria-labelledby="work-identity-title" className="rounded-xl bg-white/[0.04] p-3">
          <h3 id="work-identity-title" className="text-[11px] font-semibold text-slate-200">
            Work identity
          </h3>
          <dl className="mt-2 grid gap-2 text-[10px]">
            {[
              ['Work item', props.task.id],
              ['Book', props.task.bookId],
              ['Request', props.task.requestId],
              ['Standing goal', props.task.standingGoalId],
              ['Correlation', props.task.correlationId],
              ['Updated', props.task.updatedAt],
            ].filter((row): row is [string, string] => Boolean(row[1])).map(([label, value]) => (
              <div key={label}>
                <dt className="text-slate-500">{label}</dt>
                <dd className="select-text break-all font-mono text-slate-300">{value}</dd>
              </div>
            ))}
          </dl>
        </section>

        <section aria-labelledby="run-identity-title" className="rounded-xl bg-white/[0.04] p-3">
          <h3 id="run-identity-title" className="text-[11px] font-semibold text-slate-200">
            Run identity
          </h3>
          {props.task.runId ? (
            <>
              <p className="mt-2 select-text break-all font-mono text-[10px] leading-relaxed text-slate-300">
                {props.task.runId}
              </p>
              <button
                type="button"
                onClick={copyRunId}
                className="mt-2 min-h-11 w-full rounded-lg bg-white/5 text-[10px] text-slate-300 hover:bg-white/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sky-300/50"
              >
                {copied ? 'Copied Run ID' : 'Copy Run ID'}
              </button>
              <span aria-live="polite" className="sr-only">
                {copied ? 'Run ID copied' : ''}
              </span>
            </>
          ) : (
            <p className="mt-2 text-[10px] text-slate-500">
              No run has been assigned yet.
            </p>
          )}
        </section>
      </div>

      {props.task.summary && (
        <section aria-labelledby="work-summary-title" className="mt-4 rounded-xl bg-white/[0.04] p-3">
          <h3 id="work-summary-title" className="text-[11px] font-semibold text-slate-200">
            Runtime summary
          </h3>
          <p className="mt-1 select-text whitespace-pre-wrap text-[11px] leading-relaxed text-slate-300">
            {props.task.summary}
          </p>
        </section>
      )}

      {progress.length > 0 && (
        <section aria-labelledby="work-progress-title" className="mt-4">
          <h3 id="work-progress-title" className="text-[11px] font-semibold text-slate-200">
            Evidence progress
          </h3>
          <dl className="mt-2 grid grid-cols-2 gap-2 sm:grid-cols-3">
            {progress.map(([label, value]) => (
              <div key={label} className="rounded-xl bg-white/[0.04] p-2">
                <dt className="text-[9px] text-slate-500">{label}</dt>
                <dd className="mt-0.5 font-mono text-[13px] text-slate-200">{value}</dd>
              </div>
            ))}
          </dl>
        </section>
      )}

      <section aria-labelledby="collaborator-title" className="mt-4">
        <div className="flex items-center justify-between">
          <h3 id="collaborator-title" className="text-[11px] font-semibold text-slate-200">
            Runtime collaborators
          </h3>
          <span className="text-[9px] uppercase tracking-wider text-slate-500">
            {props.task.collaboration?.mode ?? 'unknown'} mode
          </span>
        </div>
        {collaborators.length === 0 && (props.task.collaboration?.participants.length ?? 0) === 0 ? (
          <p className="mt-2 rounded-xl bg-white/[0.03] p-3 text-[10px] text-slate-500">
            No collaborator has been assigned to this work item yet.
          </p>
        ) : (
          <div className="mt-2 grid gap-2 sm:grid-cols-2">
            {collaborators.length > 0 && (
              <ul aria-label="Assigned runtime agents" className="grid gap-1">
                {collaborators.map(agent => (
                  <li key={agent.id} className="rounded-xl bg-white/[0.04] px-3 py-2">
                    <div className="text-[11px] text-slate-200">{agent.name}</div>
                    <div className="font-mono text-[9px] text-slate-500">
                      {agent.role} · {agent.status} · {agent.id}
                    </div>
                  </li>
                ))}
              </ul>
            )}
            {(props.task.collaboration?.participants.length ?? 0) > 0 && (
              <ul aria-label="Collaboration run participants" className="grid gap-1">
                {props.task.collaboration?.participants.map(participant => (
                  <li key={participant.runId} className="rounded-xl bg-white/[0.04] px-3 py-2">
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-[11px] text-slate-200">{participant.family}</span>
                      <span className="text-[9px] text-sky-300">
                        {PARTICIPANT_STATUS_LABEL[participant.status]}
                      </span>
                    </div>
                    <div className="mt-0.5 select-text break-all font-mono text-[9px] text-slate-500">
                      {participant.runId}
                    </div>
                    {participant.parentRunId && (
                      <div className="select-text break-all font-mono text-[9px] text-slate-600">
                        parent · {participant.parentRunId}
                      </div>
                    )}
                    {(participant.startedAt !== undefined || participant.completedAt !== undefined) && (
                      <div className="mt-1 text-[9px] text-slate-500">
                        {timestampLabel(participant.startedAt) ?? 'Unknown start'}
                        {participant.completedAt !== undefined
                          ? ` → ${timestampLabel(participant.completedAt)}`
                          : ''}
                      </div>
                    )}
                    {participant.artifacts.length > 0 && (
                      <div className="mt-1 text-[9px] text-slate-500">
                        {participant.artifacts.length} recorded artifact(s)
                      </div>
                    )}
                  </li>
                ))}
              </ul>
            )}
          </div>
        )}
      </section>

      <section aria-labelledby="result-links-title" className="mt-4">
        <h3 id="result-links-title" className="text-[11px] font-semibold text-slate-200">
          Reviewable results
        </h3>
        {(props.task.resultLinks?.length ?? 0) > 0 ? (
          <div className="mt-2 grid gap-2 sm:grid-cols-2">
            {props.task.resultLinks?.map(link => (
              <a
                key={`${link.kind}:${link.url}`}
                href={link.url}
                target="_blank"
                rel="noopener noreferrer"
                className="flex min-h-11 items-center justify-between rounded-xl bg-sky-400/10 px-3 text-[11px] text-sky-200 ring-1 ring-sky-300/20 hover:bg-sky-400/20 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sky-200"
              >
                <span>{link.label}</span>
                <span className="text-[9px] uppercase tracking-wider text-sky-400">{link.kind}</span>
              </a>
            ))}
          </div>
        ) : (
          <p className="mt-2 rounded-xl bg-white/[0.03] p-3 text-[10px] text-slate-500">
            No server-curated result link is available yet. Recorded artifact
            paths are shown as evidence only and are never opened directly.
          </p>
        )}
        {props.task.artifacts.length > 0 && (
          <ul aria-label="Recorded artifact paths" className="mt-2 grid gap-1">
            {props.task.artifacts.map(artifact => (
              <li key={artifact} className="select-text break-all rounded-lg bg-white/[0.03] px-2 py-1 font-mono text-[9px] text-slate-500">
                {artifact}
              </li>
            ))}
          </ul>
        )}
      </section>
    </section>
  )
}
