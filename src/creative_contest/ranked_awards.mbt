///|
fn ranked_awards(
  state : State,
  actor : String,
  now : UInt64,
) -> Array[Award] raise {
  guard state.voting_settlements.get(0) is Some(settlement) else {
    raise Conflict("投票尚未封榜，请在投票截止后核对结果。")
  }
  let rows = settlement.rows.filter(row => {
    row.eligible_at_close && eligible(state, row.entry_id)
  })
  rows.sort_by((a, b) => b.votes.compare(a.votes))
  guard rows.length() >= 3 && rows[2].votes > 0 else {
    raise Conflict(
      "有效得票作品不足三件，暂不能公布三个奖项。",
    )
  }
  for i in 0..<3 {
    guard rows.filter(row => row.votes == rows[i].votes).length() == 1 else {
      raise Conflict(
        "获奖名次存在同票，请先公布同票处理安排，暂不分配奖品。",
      )
    }
  }
  // A later withdrawal never silently promotes a different work into an award.
  guard rows[0].rank == 1 && rows[1].rank == 2 && rows[2].rank == 3 else {
    raise Conflict("获奖作品状态已变化，请先核对封榜结果。")
  }
  ["creative", "popular", "coffee"].mapi((i, prize) => {
    entry_id: rows[i].entry_id,
    prize,
    reason: "大众投票第\{i + 1}名 · \{rows[i].votes}票",
    recorded_ms: now,
    operator: actor,
  })
}

///|
fn ranked_award_projection(
  state : State,
  config : Config,
  now : UInt64,
) -> Json {
  if !builtin(config) {
    return Json::null()
  }
  try ranked_awards(state, "", now) catch {
    Conflict(message) =>
      { "ready": false, "message": message, "candidates": [] }
    _ =>
      {
        "ready": false,
        "message": "暂时无法核对投票结果。",
        "candidates": [],
      }
  } noraise {
    awards =>
      {
        "ready": now >= config.awards_ms && !state.results_published,
        "message": if state.results_published {
          "一、二、三等奖已公布。"
        } else if now < config.awards_ms {
          "已按封榜票数排列，开奖时间到后可确认公布。"
        } else {
          "已按封榜票数确定一、二、三等奖，请核对后公布。"
        },
        "candidates": awards.map(award => award.to_json()),
      }
  }
}
