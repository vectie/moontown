///|
pub fn research_salon_pattern() -> CivicCommunicationPattern {
  {
    id: "research-salon",
    title: "Research Salon",
    category: "knowledge-exchange",
    summary: "Many specialist workspaces exchange perspectives, reduce tensions into research questions, and return follow-up ideas home.",
    protocol_mode: "exchange-reduce-distribute",
    input_contract: "perspective packet",
    reduction_contract: "cross-area idea reduction",
    output_contract: "civic.salon.idea_reduction.v1",
    review_contract: "novelty, feasibility, evidence gap, owner workspace",
    cadence_hint: "30m to weekly, depending on research velocity",
    good_for: [
      "cross-domain research", "frontier topic scouting", "finding non-obvious questions",
    ],
    civic_examples: [
      "embodied robotics research salon", "OPC research salon", "EUV lithography research salon",
    ],
  }
}

///|
pub fn signal_watch_pattern() -> CivicCommunicationPattern {
  {
    id: "signal-watch",
    title: "Signal Watch",
    category: "long-horizon-monitoring",
    summary: "A watcher checks sources on a real-world cadence, separates no-change cycles from accepted facts, and emits concise change digests.",
    protocol_mode: "observe-filter-update",
    input_contract: "source observation packet",
    reduction_contract: "change/no-change digest",
    output_contract: "civic.signal_watch.digest.v1",
    review_contract: "source quality, novelty, domain relevance, page changes",
    cadence_hint: "15m to daily",
    good_for: ["news monitoring", "policy tracking", "market updates"],
    civic_examples: [
      "OPC watcher", "policy update watch", "local-event signal watch",
    ],
  }
}
