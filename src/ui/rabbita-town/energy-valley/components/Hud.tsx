// ============================================================
// HUD —— 极简覆盖层：镇名牌 / 指标 / 工具坞 / 事件流 / 视察面板 / 看板
// ============================================================

import { useState } from 'react'
import type { Agent, Building, TownEvent, WeatherKind } from '../engine/types'
import { roleIcon } from '../engine/sim'
import { archetype } from '../engine/world'
import { COSTS } from '../engine/build'
import type { ToolId } from '../engine/types'
import moontownLogo from '../../../assets/moontown.svg'

// ---------- 顶部左：镇名 + 时间 ----------
export function TownBadge(props: {
  day: number; hour: number; weather: WeatherKind; weatherAuto: boolean
  onToggleWeather: (w: WeatherKind) => void
  onToggleAuto: () => void
}) {
  const hh = Math.floor(props.hour)
  const mm = Math.floor((props.hour - hh) * 60)
  const wIcon: Record<WeatherKind, string> = { sunny: '☀️', cloudy: '☁️', rain: '🌧️', snow: '❄️' }
  return (
    <div className="pointer-events-auto flex items-center gap-3 rounded-2xl bg-slate-950/60 px-4 py-2.5 backdrop-blur-md border border-white/10 shadow-xl">
      <img src={moontownLogo} alt="" className="h-9 w-9 rounded-xl shadow-lg" />
      <div>
        <div className="text-[15px] font-bold tracking-wide text-amber-100">MoonTown · 能源谷</div>
        <div className="text-[10px] text-slate-400 tracking-widest">WENYU VALLEY · CHANGPING</div>
      </div>
      <div className="h-8 w-px bg-white/10" />
      <div className="text-center">
        <div className="text-[15px] font-mono text-slate-100">{String(hh).padStart(2, '0')}:{String(mm).padStart(2, '0')}</div>
        <div className="text-[10px] text-slate-400">第 {props.day} 天</div>
      </div>
      <div className="h-8 w-px bg-white/10" />
      <div className="flex items-center gap-1">
        {(['sunny', 'cloudy', 'rain', 'snow'] as WeatherKind[]).map(w => (
          <button
            key={w}
            onClick={() => props.onToggleWeather(w)}
            aria-label={`天气：${{ sunny: '晴天', cloudy: '多云', rain: '雨天', snow: '雪天' }[w]}`}
            aria-pressed={props.weather === w}
            title={props.weatherAuto ? '手动指定后自动天气关闭' : ''}
            className={`rounded-lg px-1.5 py-1 text-sm transition ${props.weather === w ? 'bg-amber-300/25 ring-1 ring-amber-300/50' : 'hover:bg-white/10 opacity-60'}`}
          >
            {wIcon[w]}
          </button>
        ))}
        <button
          onClick={props.onToggleAuto}
          aria-pressed={props.weatherAuto}
          aria-label="自动天气"
          className={`ml-1 rounded-lg px-2 py-1 text-[10px] transition ${props.weatherAuto ? 'bg-emerald-400/20 text-emerald-200 ring-1 ring-emerald-300/40' : 'bg-white/5 text-slate-400'}`}
        >
          自动
        </button>
      </div>
    </div>
  )
}

// ---------- 顶部右：指标 ----------
export function MetricChips(props: {
  population: number; vitality: number; budget: number; agentsOnline: number
  paused: boolean; timeScale: number
  onPause: () => void; onSpeed: (s: number) => void
  onToggleBoard: () => void; boardOpen: boolean
}) {
  return (
    <div className="pointer-events-auto flex items-center gap-2">
      <div className="flex items-center gap-3 rounded-2xl bg-slate-950/60 px-4 py-2.5 backdrop-blur-md border border-white/10 shadow-xl text-[13px]">
        <Chip icon="👥" label="居民" value={String(props.population)} />
        <Chip icon="⚡" label="活力" value={String(Math.round(props.vitality))} tone={props.vitality > 60 ? 'good' : props.vitality > 35 ? 'mid' : 'bad'} />
        <Chip icon="💰" label="预算" value={fmtBudget(props.budget)} />
        <Chip icon="🤖" label="Agent" value={String(props.agentsOnline)} />
      </div>
      <div className="flex items-center gap-1 rounded-2xl bg-slate-950/60 px-2 py-2 backdrop-blur-md border border-white/10 shadow-xl">
        <button
          onClick={props.onPause}
          aria-label={props.paused ? '继续模拟' : '暂停模拟'}
          aria-pressed={props.paused}
          className="rounded-lg px-2 py-1 text-sm hover:bg-white/10"
          title="空格键"
        >
          {props.paused ? '▶️' : '⏸️'}
        </button>
        {[30, 60, 240].map((s, i) => (
          <button
            key={s}
            onClick={() => props.onSpeed(s)}
            aria-label={`模拟速度 ${['1×', '2×', '8×'][i]}`}
            aria-pressed={props.timeScale === s}
            className={`rounded-lg px-1.5 py-1 text-[11px] font-mono ${props.timeScale === s ? 'bg-amber-300/25 text-amber-100 ring-1 ring-amber-300/50' : 'text-slate-400 hover:bg-white/10'}`}
          >
            {['1×', '2×', '8×'][i]}
          </button>
        ))}
        <button
          onClick={props.onToggleBoard}
          aria-expanded={props.boardOpen}
          className={`ml-1 rounded-lg px-2.5 py-1 text-[12px] ${props.boardOpen ? 'bg-amber-300/25 text-amber-100 ring-1 ring-amber-300/50' : 'text-slate-200 hover:bg-white/10'}`}
        >
          📊 看板
        </button>
      </div>
    </div>
  )
}

function Chip(props: { icon: string; label: string; value: string; tone?: 'good' | 'mid' | 'bad' }) {
  const toneCls = props.tone === 'good' ? 'text-emerald-300' : props.tone === 'mid' ? 'text-amber-200' : props.tone === 'bad' ? 'text-rose-300' : 'text-slate-100'
  return (
    <div className="flex items-center gap-1.5" title={props.label}>
      <span className="text-sm">{props.icon}</span>
      <span className={`font-mono font-semibold ${toneCls}`}>{props.value}</span>
    </div>
  )
}

function fmtBudget(v: number): string {
  return v >= 10000 ? `${(v / 1000).toFixed(1)}k` : String(Math.round(v))
}

// ---------- 底部工具坞 ----------
const BUILD_TOOLS: { id: ToolId; glyph: string; name: string; cost: number }[] = [
  { id: 'bld:c-tower', glyph: '研', name: '研发塔楼', cost: 800 },
  { id: 'bld:c-lab', glyph: '实', name: '实验室', cost: 500 },
  { id: 'bld:c-hall', glyph: '坊', name: '创新工坊', cost: 400 },
  { id: 'bld:c-home', glyph: '寓', name: '人才公寓', cost: 350 },
]

export function ToolDock(props: { tool: ToolId; onTool: (t: ToolId) => void }) {
  const base: { id: ToolId; icon: string; name: string; cost?: number; key: string }[] = [
    { id: 'inspect', icon: '🖐️', name: '视察', key: '1' },
    { id: 'road', icon: '🛣️', name: '铺路', cost: COSTS.road, key: '2' },
    { id: 'park', icon: '🌳', name: '造林', cost: COSTS.park, key: '3' },
    { id: 'demolish', icon: '🧹', name: '拆除', key: '4' },
  ]
  return (
    <div className="pointer-events-auto flex items-end gap-2 rounded-2xl bg-slate-950/60 px-3 py-2 backdrop-blur-md border border-white/10 shadow-xl">
      {base.map(b => (
        <DockBtn
          key={b.id}
          active={props.tool === b.id}
          onClick={() => props.onTool(b.id)}
          hotkey={b.key}
          label={b.name}
          cost={b.cost}
        >
          <span className="text-lg">{b.icon}</span>
        </DockBtn>
      ))}
      <div className="mx-1 h-10 w-px bg-white/10" />
      {BUILD_TOOLS.map((b, i) => (
        <DockBtn
          key={b.id}
          active={props.tool === b.id}
          onClick={() => props.onTool(b.id)}
          hotkey={String(i + 5)}
          label={b.name}
          cost={b.cost}
        >
          <span className="flex h-7 w-7 items-center justify-center rounded-md bg-gradient-to-br from-indigo-400/80 to-sky-500/80 text-[13px] font-bold text-white shadow">
            {b.glyph}
          </span>
        </DockBtn>
      ))}
    </div>
  )
}

function DockBtn(props: {
  active: boolean; onClick: () => void; label: string; cost?: number; hotkey: string; children: React.ReactNode
}) {
  return (
    <button
      onClick={props.onClick}
      aria-label={`${props.label}${props.cost !== undefined ? `，花费 ${props.cost}` : ''}，快捷键 ${props.hotkey}`}
      aria-pressed={props.active}
      className={`group relative flex flex-col items-center gap-0.5 rounded-xl px-2.5 py-1.5 transition ${
        props.active ? 'bg-amber-300/25 ring-1 ring-amber-300/60' : 'hover:bg-white/10'
      }`}
    >
      {props.children}
      <span className="text-[10px] text-slate-300">{props.label}</span>
      {props.cost !== undefined && <span className="text-[9px] font-mono text-amber-200/80">{props.cost}</span>}
      <span className="absolute -top-1.5 -right-1 rounded bg-white/10 px-1 text-[8px] text-slate-400 opacity-0 transition group-hover:opacity-100">
        {props.hotkey}
      </span>
    </button>
  )
}

// ---------- 事件流 ----------
export function EventFeed(props: { events: TownEvent[] }) {
  return (
    <div className="pointer-events-none flex w-72 flex-col gap-1">
      {props.events.slice(0, 4).map((e, i) => (
        <div
          key={e.id}
          className="flex items-center gap-2 rounded-xl bg-slate-950/50 px-3 py-1.5 backdrop-blur-sm border border-white/5 text-[12px] text-slate-200"
          style={{ opacity: 1 - i * 0.22 }}
        >
          <span>{e.icon}</span>
          <span className={e.level === 'good' ? 'text-emerald-200' : e.level === 'warn' ? 'text-amber-200' : ''}>{e.text}</span>
        </div>
      ))}
    </div>
  )
}

// ---------- 视察面板（建筑 / Agent） ----------
export function Inspector(props: {
  building?: Building | null
  agent?: Agent | null
  buildingName?: (b: Building) => string
  onClose: () => void
  onFollow?: (id: string | null) => void
  following?: boolean
  onDemolish?: (b: Building) => void
}) {
  const b = props.building
  const ag = props.agent
  if (!b && !ag) return null
  return (
    <div className="pointer-events-auto w-64 rounded-2xl bg-slate-950/70 p-4 backdrop-blur-md border border-white/10 shadow-2xl">
      {b && (
        <>
          <div className="mb-1 flex items-start justify-between">
            <div>
              <div className="text-[15px] font-bold text-amber-100">{b.name}</div>
              <div className="text-[11px] text-slate-400">{archetype(b.archetype).desc}</div>
            </div>
            <button onClick={props.onClose} className="rounded-lg px-2 py-0.5 text-slate-400 hover:bg-white/10">✕</button>
          </div>
          {b.isCivic && (
            <div className="mb-2 rounded-lg bg-indigo-400/15 px-2 py-1 text-[10px] text-indigo-200 ring-1 ring-indigo-300/30">
              市政协议模块 · {b.moduleKey}
            </div>
          )}
          <Meter label="活力" value={b.vitality} color="bg-emerald-400" />
          <Meter label="建造" value={b.progress * 100} color="bg-sky-400" />
          <div className="mt-2 flex items-center justify-between text-[12px] text-slate-300">
            <span>在内 Agent</span>
            <span className="font-mono text-slate-100">{b.occupants}</span>
          </div>
          {!b.builtin && (
            <button
              onClick={() => props.onDemolish?.(b)}
              className="mt-3 w-full rounded-lg bg-rose-500/20 py-1.5 text-[12px] text-rose-200 ring-1 ring-rose-400/40 hover:bg-rose-500/30"
            >
              拆除（返还 50%）
            </button>
          )}
        </>
      )}
      {ag && (
        <>
          <div className="mb-1 flex items-start justify-between">
            <div>
              <div className="text-[15px] font-bold text-amber-100">{roleIcon(ag.role)} {ag.name}</div>
              <div className="text-[11px] text-slate-400">
                {ag.role === 'mayor' ? '镇长 · 战略巡检' : ag.role === 'keeper' ? '看护 · 书本记忆' : ag.role === 'worker' ? '工蜂 · 任务执行' : '谷民 · 数字分身'}
              </div>
            </div>
            <button onClick={props.onClose} className="rounded-lg px-2 py-0.5 text-slate-400 hover:bg-white/10">✕</button>
          </div>
          <div className="mt-2 flex items-center justify-between text-[12px] text-slate-300">
            <span>当前目的</span>
            <span className="text-slate-100">{ag.purpose}</span>
          </div>
          <div className="mt-1 flex items-center justify-between text-[12px] text-slate-300">
            <span>状态</span>
            <span className="text-slate-100">{ag.state === 'walking' ? '通勤中' : '驻楼办公'}</span>
          </div>
          <button
            onClick={() => props.onFollow?.(props.following ? null : ag.id)}
            className={`mt-3 w-full rounded-lg py-1.5 text-[12px] ring-1 ${
              props.following
                ? 'bg-amber-300/25 text-amber-100 ring-amber-300/50'
                : 'bg-sky-500/20 text-sky-200 ring-sky-400/40 hover:bg-sky-500/30'
            }`}
          >
            {props.following ? '取消跟随' : '🎥 跟随视角'}
          </button>
        </>
      )}
    </div>
  )
}

function Meter(props: { label: string; value: number; color: string }) {
  return (
    <div className="mt-2">
      <div className="mb-0.5 flex justify-between text-[11px] text-slate-400">
        <span>{props.label}</span>
        <span className="font-mono">{Math.round(props.value)}</span>
      </div>
      <div className="h-1.5 overflow-hidden rounded-full bg-white/10">
        <div className={`h-full rounded-full ${props.color} transition-all`} style={{ width: `${Math.min(100, props.value)}%` }} />
      </div>
    </div>
  )
}

// ---------- 全镇看板 ----------
export function Dashboard(props: {
  open: boolean
  vitality: number
  history: { vitality: number; population: number }[]
  buildings: Building[]
  events: TownEvent[]
  onClose: () => void
  onSelect: (b: Building) => void
  onGuide: () => void
  onReset: () => void
}) {
  const [section, setSection] = useState<'services' | 'activity'>('services')
  if (!props.open) return null
  const civic = props.buildings.filter(b => b.isCivic)
  const custom = props.buildings.filter(b => !b.isCivic)
  return (
    <div className="town-dashboard pointer-events-auto flex w-[38rem] flex-col gap-3 rounded-2xl bg-slate-950/75 p-4 backdrop-blur-md border border-white/10 shadow-2xl">
      <div className="flex items-center justify-between">
        <div className="text-[15px] font-bold text-amber-100">📊 能源谷运行看板</div>
        <div className="flex items-center gap-1">
          <button onClick={props.onGuide} className="rounded-lg px-2 py-0.5 text-[11px] text-slate-400 hover:bg-white/10 hover:text-slate-200">
            指南
          </button>
          <button onClick={props.onClose} className="rounded-lg px-2 py-0.5 text-slate-400 hover:bg-white/10">✕</button>
        </div>
      </div>

      {/* 活力走势 */}
      <div className="town-dashboard-chart rounded-xl bg-white/5 p-3">
        <div className="mb-1 flex justify-between text-[11px] text-slate-400">
          <span>全镇活力 · 48 小时</span>
          <span className="font-mono text-emerald-300">{Math.round(props.vitality)}</span>
        </div>
        <Sparkline data={props.history.map(h => h.vitality)} />
      </div>

      <div className="flex rounded-xl bg-white/5 p-1">
        <button
          onClick={() => setSection('services')}
          aria-pressed={section === 'services'}
          className={`flex-1 rounded-lg py-1.5 text-[11px] transition ${section === 'services' ? 'bg-amber-300/20 text-amber-100' : 'text-slate-400 hover:text-slate-200'}`}
        >
          市政服务 · {civic.length}
        </button>
        <button
          onClick={() => setSection('activity')}
          aria-pressed={section === 'activity'}
          className={`flex-1 rounded-lg py-1.5 text-[11px] transition ${section === 'activity' ? 'bg-amber-300/20 text-amber-100' : 'text-slate-400 hover:text-slate-200'}`}
        >
          运行活动 · {Math.min(12, props.events.length)}
        </button>
      </div>

      {section === 'services' && (
        <div>
          <div className="grid grid-cols-2 gap-1">
          {civic.map(b => (
            <button
              key={b.id}
              onClick={() => props.onSelect(b)}
              aria-label={`${b.name}，${b.moduleKey ?? b.id}，活力 ${Math.round(b.vitality)}`}
              className="flex items-center gap-2 rounded-lg px-2 py-1.5 text-left hover:bg-white/10"
            >
              <span className="flex h-6 w-6 items-center justify-center rounded-md bg-gradient-to-br from-indigo-400/70 to-sky-500/70 text-[11px] font-bold text-white">
                {archetype(b.archetype).glyph.slice(0, 1)}
              </span>
              <span className="flex-1 text-[12px] text-slate-200">{b.name}</span>
              <span className="w-16">
                <span className="block h-1 overflow-hidden rounded-full bg-white/10">
                  <span className="block h-full rounded-full bg-emerald-400" style={{ width: `${b.vitality}%` }} />
                </span>
              </span>
              <span className="w-8 text-right font-mono text-[10px] text-slate-400">{Math.round(b.vitality)}</span>
            </button>
          ))}
          </div>

          {custom.length > 0 && (
            <div className="mt-2">
              <div className="mb-1.5 text-[11px] tracking-widest text-slate-400">自建建筑 · {custom.length}</div>
              <div className="flex flex-wrap gap-1">
                {custom.map(b => (
                  <button
                    key={b.id}
                    onClick={() => props.onSelect(b)}
                    className="rounded-lg bg-white/5 px-2 py-1 text-[11px] text-slate-300 hover:bg-white/10"
                  >
                    {b.name}{b.progress < 1 ? ' · 建造中' : ''}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {section === 'activity' && (
        <div>
          <div className="flex flex-col gap-1">
            {props.events.slice(0, 12).map(e => (
              <div key={e.id} className="flex min-h-8 items-center gap-2 rounded-lg px-2 text-[11px] text-slate-300 odd:bg-white/[0.03]">
                <span>{e.icon}</span>
                <span className="flex-1">{e.text}</span>
                <span className="font-mono text-slate-500">{String(Math.floor(e.t)).padStart(2, '0')}时</span>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="flex items-center justify-between border-t border-white/10 pt-2 text-[10px] text-slate-500">
        <span>数据来自当前本地模拟 · 每 0.4 秒刷新</span>
        <button onClick={props.onReset} className="rounded-lg px-2 py-1 text-slate-400 hover:bg-white/10 hover:text-rose-200">
          重置小镇
        </button>
      </div>
    </div>
  )
}

function Sparkline(props: { data: number[] }) {
  const d = props.data
  const W = 260, H = 44
  if (d.length < 2) return <div className="flex h-11 items-center justify-center text-[10px] text-slate-500">数据积累中…</div>
  const min = Math.min(...d) - 2
  const max = Math.max(...d) + 2
  const pts = d.map((v, i) => `${(i / (d.length - 1)) * W},${H - ((v - min) / (max - min)) * H}`).join(' ')
  return (
    <svg viewBox={`0 0 ${W} ${H}`} className="w-full">
      <polyline points={pts} fill="none" stroke="#6ee7b7" strokeWidth="2" strokeLinejoin="round" />
      <polyline points={`0,${H} ${pts} ${W},${H}`} fill="rgba(110,231,183,0.12)" stroke="none" />
    </svg>
  )
}

// ---------- 首次引导 ----------
export function Onboarding(props: { onClose: () => void; onGuide: () => void }) {
  return (
    <div className="pointer-events-auto w-[340px] rounded-2xl bg-slate-950/85 p-5 backdrop-blur-md border border-amber-200/20 shadow-2xl">
      <div className="mb-2 text-[16px] font-bold text-amber-100">欢迎来到能源谷 🌙</div>
      <div className="flex flex-col gap-2 text-[12.5px] leading-relaxed text-slate-300">
        <p>这里是参考<b className="text-amber-100">昌平未来科学城 · 能源谷</b>的 AI 小镇实时看板：温榆河穿城，13 座市政协议建筑由 Agent 日夜值守。</p>
        <p>🖐️ <b>视察</b>：点击建筑或小人查看详情，可跟随 Agent 视角<br/>🛣️ <b>搭建</b>：底部工具坞可铺路、造林、建造新楼宇<br/>🌦️ <b>环境</b>：左上角切换天气，右上角调节时间流速</p>
      </div>
      <button
        onClick={props.onClose}
        className="mt-3 w-full rounded-xl bg-amber-300/90 py-2 text-[13px] font-bold text-slate-900 hover:bg-amber-200"
      >
        进入小镇
      </button>
      <button onClick={props.onGuide} className="mt-2 w-full rounded-xl py-1.5 text-[12px] text-slate-400 hover:bg-white/5 hover:text-slate-200">
        先看完整操作指南
      </button>
    </div>
  )
}

export function Guide(props: { onClose: () => void }) {
  return (
    <section
      role="dialog"
      aria-modal="true"
      aria-labelledby="town-guide-title"
      className="pointer-events-auto w-full max-w-3xl rounded-2xl border border-amber-200/20 bg-slate-950/95 p-5 shadow-2xl backdrop-blur-md"
    >
      <div className="flex items-start justify-between gap-4">
        <div>
          <h2 id="town-guide-title" className="text-[17px] font-bold text-amber-100">能源谷操作指南</h2>
          <p className="mt-1 text-[12px] text-slate-400">先看镇况，再视察或建设；所有变化都在本机模拟并自动保存。</p>
        </div>
        <button onClick={props.onClose} aria-label="关闭指南" className="rounded-lg px-2 py-1 text-slate-400 hover:bg-white/10">✕</button>
      </div>

      <div className="mt-4 grid gap-3 text-[12px] leading-relaxed text-slate-300 sm:grid-cols-2">
        <GuideCard title="1 · 看镇况">
          居民是模拟人口；活力是 0–100 的全镇状态；预算用于建设；Agent 是正在执勤的镇长、看护与执行角色。看板把内置地标和活动分开呈现。
        </GuideCard>
        <GuideCard title="2 · 视察">
          选择“视察”后点击建筑或居民。拖动画面平移，滚轮缩放；居民详情可开启或取消跟随。
        </GuideCard>
        <GuideCard title="3 · 建设">
          底部选择道路、造林或四类建筑，再点地图放置。红色预览表示冲突或预算不足；提示会说明原因。
        </GuideCard>
        <GuideCard title="4 · 拆除与恢复">
          “拆除”可清理自建内容；建筑详情会显示返还比例。重置会先确认，并只清除本地小镇存档。
        </GuideCard>
      </div>

      <div className="mt-3 rounded-xl bg-white/5 p-3 text-[11px] text-slate-400">
        <span><b className="text-slate-200">快捷键：</b>1–8 切换工具 · 空格暂停/继续 · Esc 返回视察并关闭面板</span>
      </div>

      <button onClick={props.onClose} className="mt-4 w-full rounded-xl bg-amber-300/90 py-2 text-[13px] font-bold text-slate-900 hover:bg-amber-200">
        开始探索
      </button>
    </section>
  )
}

function GuideCard(props: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-xl bg-white/5 p-3">
      <div className="mb-1 font-semibold text-amber-100">{props.title}</div>
      <div>{props.children}</div>
    </div>
  )
}

export function ResetDialog(props: { onCancel: () => void; onConfirm: () => void }) {
  return (
    <section
      role="alertdialog"
      aria-modal="true"
      aria-labelledby="reset-town-title"
      className="pointer-events-auto w-full max-w-sm rounded-2xl border border-rose-300/20 bg-slate-950/95 p-5 shadow-2xl backdrop-blur-md"
    >
      <h2 id="reset-town-title" className="text-[16px] font-bold text-amber-100">重置能源谷？</h2>
      <p className="mt-2 text-[12px] leading-relaxed text-slate-300">
        这会清除本机保存的自建建筑、道路、造林、预算和模拟时间。市政建筑不会删除。
      </p>
      <div className="mt-4 flex gap-2">
        <button onClick={props.onCancel} className="flex-1 rounded-xl bg-white/10 py-2 text-[12px] text-slate-200 hover:bg-white/15">
          取消
        </button>
        <button onClick={props.onConfirm} className="flex-1 rounded-xl bg-rose-500/80 py-2 text-[12px] font-semibold text-white hover:bg-rose-400">
          确认重置
        </button>
      </div>
    </section>
  )
}
