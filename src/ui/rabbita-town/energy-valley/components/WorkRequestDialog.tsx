import {
  useEffect,
  useId,
  useRef,
  useState,
  type FormEvent,
  type KeyboardEvent,
} from 'react'
import {
  DEFAULT_OPERATOR_REQUEST,
  submitOperatorRequest,
  type AcceptedOperatorRequest,
  type OperatorRequestInput,
} from '../runtime/requests'

const TARGET_BOOKS = [
  ['research-agent-work-projection', 'Agent work projection'],
  ['research-ai-agents', 'AI agent systems'],
  ['research-opc', 'OPC research'],
  ['research-llm-training', 'LLM training'],
  ['research-ai-hardware', 'AI hardware'],
  ['research-embodied-robotics', 'Embodied robotics'],
] as const

export function WorkRequestDialog(props: {
  onClose: () => void
  onAccepted: (receipt: AcceptedOperatorRequest) => void
}) {
  const titleId = useId()
  const descriptionId = useId()
  const titleInputId = useId()
  const promptId = useId()
  const targetId = useId()
  const cadenceId = useId()
  const qualityId = useId()
  const dialogRef = useRef<HTMLElement>(null)
  const abortRef = useRef<AbortController | null>(null)
  const [input, setInput] = useState<OperatorRequestInput>({
    ...DEFAULT_OPERATOR_REQUEST,
  })
  const [phase, setPhase] = useState<
    'editing' | 'submitting' | 'accepted' | 'error'
  >('editing')
  const [error, setError] = useState<string>()
  const [receipt, setReceipt] = useState<AcceptedOperatorRequest>()

  useEffect(() => () => abortRef.current?.abort(), [])

  function update<K extends keyof OperatorRequestInput>(
    key: K,
    value: OperatorRequestInput[K],
  ) {
    setInput(current => ({ ...current, [key]: value }))
    if (phase === 'error') {
      setPhase('editing')
      setError(undefined)
    }
  }

  async function submit(event: FormEvent) {
    event.preventDefault()
    if (phase === 'submitting') return
    abortRef.current?.abort()
    const controller = new AbortController()
    abortRef.current = controller
    setPhase('submitting')
    setError(undefined)
    try {
      const accepted = await submitOperatorRequest(input, {
        signal: controller.signal,
      })
      setReceipt(accepted)
      setPhase('accepted')
      props.onAccepted(accepted)
    } catch (value) {
      if (controller.signal.aborted) return
      setError(
        value instanceof Error
          ? value.message
          : 'The request could not be sent to the Mayor queue.',
      )
      setPhase('error')
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
      'button:not([disabled]), input:not([disabled]), textarea:not([disabled]), select:not([disabled])',
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
      role="dialog"
      aria-modal="true"
      aria-labelledby={titleId}
      aria-describedby={descriptionId}
      onKeyDown={onDialogKeyDown}
      className="work-request-dialog pointer-events-auto w-full max-w-xl overflow-y-auto rounded-2xl border border-sky-300/20 bg-slate-950/95 p-5 shadow-2xl backdrop-blur-md"
    >
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-[10px] font-semibold uppercase tracking-[0.18em] text-sky-300">
            Mayor queue
          </p>
          <h2 id={titleId} className="mt-1 text-[18px] font-bold text-amber-100">
            Create real work
          </h2>
          <p id={descriptionId} className="mt-1 text-[12px] leading-relaxed text-slate-400">
            This creates a durable research goal. Acceptance means queued—not
            dispatched, running, or completed.
          </p>
        </div>
        <button
          type="button"
          aria-label="Close create real work dialog"
          onClick={props.onClose}
          className="min-h-11 min-w-11 rounded-xl text-slate-400 hover:bg-white/10 hover:text-slate-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-300/70"
        >
          ✕
        </button>
      </div>

      {phase === 'accepted' && receipt ? (
        <div className="mt-5">
          <div role="status" aria-live="polite" className="rounded-xl border border-emerald-300/20 bg-emerald-400/10 p-4">
            <div className="font-semibold text-emerald-200">
              Accepted into the Mayor queue
            </div>
            <p className="mt-1 text-[12px] leading-relaxed text-emerald-100/80">
              The runtime will decide when to dispatch it. Energy Valley is now
              watching for a correlated task.
            </p>
            <dl className="mt-3 grid gap-2 font-mono text-[10px] text-slate-300">
              <div>
                <dt className="text-slate-500">Request ID</dt>
                <dd className="select-text break-all">{receipt.requestId}</dd>
              </div>
              <div>
                <dt className="text-slate-500">Standing goal ID</dt>
                <dd className="select-text break-all">{receipt.standingGoalId}</dd>
              </div>
            </dl>
          </div>
          <button
            type="button"
            autoFocus
            onClick={props.onClose}
            className="mt-4 min-h-11 w-full rounded-xl bg-amber-300 text-[13px] font-bold text-slate-950 hover:bg-amber-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-100"
          >
            Watch the queue
          </button>
        </div>
      ) : (
        <form onSubmit={submit} className="mt-5 grid gap-4">
          <label className="grid gap-1.5 text-[11px] font-medium text-slate-300" htmlFor={titleInputId}>
            Title
            <input
              id={titleInputId}
              autoFocus
              required
              value={input.title}
              onChange={event => update('title', event.target.value)}
              placeholder="Audit how real agents perform useful work"
              className="min-h-11 rounded-xl border border-white/10 bg-white/5 px-3 text-[13px] text-slate-100 outline-none placeholder:text-slate-600 focus:border-sky-300/50 focus:ring-2 focus:ring-sky-300/20"
            />
          </label>

          <label className="grid gap-1.5 text-[11px] font-medium text-slate-300" htmlFor={promptId}>
            Research request
            <textarea
              id={promptId}
              required
              rows={5}
              value={input.prompt}
              onChange={event => update('prompt', event.target.value)}
              placeholder="Inspect the real agent work projection, gather evidence, and return a reviewable report with source-backed findings."
              className="resize-y rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-[13px] leading-relaxed text-slate-100 outline-none placeholder:text-slate-600 focus:border-sky-300/50 focus:ring-2 focus:ring-sky-300/20"
            />
          </label>

          <label className="grid gap-1.5 text-[11px] font-medium text-slate-300" htmlFor={targetId}>
            Target research book
            <select
              id={targetId}
              value={input.targetBookId}
              onChange={event => update('targetBookId', event.target.value)}
              className="min-h-11 rounded-xl border border-white/10 bg-slate-900 px-3 text-[12px] text-slate-100 outline-none focus:border-sky-300/50 focus:ring-2 focus:ring-sky-300/20"
            >
              {TARGET_BOOKS.map(([value, label]) => (
                <option key={value} value={value}>{label} · {value}</option>
              ))}
            </select>
          </label>

          <details className="rounded-xl border border-white/10 bg-white/[0.03]">
            <summary className="flex min-h-11 cursor-pointer items-center px-3 text-[11px] text-slate-300">
              Advanced scheduling and quality
            </summary>
            <div className="grid gap-3 border-t border-white/10 p-3 sm:grid-cols-2">
              <label className="grid gap-1.5 text-[10px] text-slate-400" htmlFor={cadenceId}>
                Cadence in runtime ticks
                <input
                  id={cadenceId}
                  type="number"
                  min={1}
                  step={1}
                  value={input.cadenceTicks}
                  onChange={event => update('cadenceTicks', Number(event.target.value))}
                  className="min-h-11 rounded-xl border border-white/10 bg-slate-900 px-3 font-mono text-[12px] text-slate-100 outline-none focus:border-sky-300/50"
                />
              </label>
              <label className="grid gap-1.5 text-[10px] text-slate-400" htmlFor={qualityId}>
                Quality threshold
                <input
                  id={qualityId}
                  type="number"
                  min={1}
                  max={100}
                  step={1}
                  value={input.qualityThreshold}
                  onChange={event => update('qualityThreshold', Number(event.target.value))}
                  className="min-h-11 rounded-xl border border-white/10 bg-slate-900 px-3 font-mono text-[12px] text-slate-100 outline-none focus:border-sky-300/50"
                />
              </label>
            </div>
          </details>

          {error && (
            <p role="alert" className="rounded-xl bg-rose-500/10 px-3 py-2 text-[11px] leading-relaxed text-rose-200 ring-1 ring-rose-400/20">
              {error}
            </p>
          )}

          <div className="grid grid-cols-[auto_1fr] gap-2">
            <button
              type="button"
              onClick={props.onClose}
              className="min-h-11 rounded-xl bg-white/5 px-4 text-[12px] text-slate-300 hover:bg-white/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-300/50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={phase === 'submitting'}
              aria-busy={phase === 'submitting'}
              className="min-h-11 rounded-xl bg-amber-300 px-4 text-[13px] font-bold text-slate-950 hover:bg-amber-200 disabled:cursor-wait disabled:opacity-60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-100"
            >
              {phase === 'submitting'
                ? 'Sending to Mayor queue…'
                : 'Create real work'}
            </button>
          </div>
        </form>
      )}
    </section>
  )
}
