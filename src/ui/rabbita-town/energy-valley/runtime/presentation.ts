import type { RuntimeProjectionPhase } from './types'

export function runtimeAgentMetricLabel(
  phase?: RuntimeProjectionPhase,
): '真实 Agent' | '环境角色' {
  return phase === 'live' ? '真实 Agent' : '环境角色'
}
