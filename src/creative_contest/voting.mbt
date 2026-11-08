///|
struct VoteEvent {
  actor : String
  intent : String
  entry_id : String
  created_ms : UInt64
} derive(ToJson, FromJson)

///|
struct RosterEntry {
  entry_id : String
  generation_id : String
  sha256 : String
  title : String
  display_name : String
  actor : String
} derive(ToJson, FromJson)

///|
struct VotingRoster {
  version : Int32
  digest : String
  opens_ms : UInt64
  closes_ms : UInt64
  rows : Array[RosterEntry]
} derive(ToJson, FromJson)

///|
struct VoteCount {
  entry_id : String
  votes : Int32
  rank : Int32
  eligible_at_close : Bool
} derive(ToJson, FromJson)

///|
struct VotingSettlement {
  version : Int32
  digest : String
  roster_digest : String
  closed_ms : UInt64
  rows : Array[VoteCount]
  total_votes : Int32
} derive(ToJson, FromJson)

///|
fn builtin(config : Config) -> Bool {
  config.voting_mode == Some("builtin")
}

///|
fn roster_public_row(row : RosterEntry) -> Json {
  {
    "entry_id": row.entry_id,
    "generation_id": row.generation_id,
    "sha256": row.sha256,
    "title": row.title,
    "display_name": row.display_name,
  }
}

///|
fn roster_hash(config : Config, roster : VotingRoster) -> String {
  hash(
    (
      {
        "challenge_id": config.brief.id,
        "version": roster.version,
        "opens_ms": roster.opens_ms,
        "closes_ms": roster.closes_ms,
        "rows": roster.rows.map(roster_public_row),
      } : Json).stringify(),
  )
}

///|
fn settlement_hash(config : Config, value : VotingSettlement) -> String {
  hash(
    (
      {
        "challenge_id": config.brief.id,
        "version": value.version,
        "roster_digest": value.roster_digest,
        "closed_ms": value.closed_ms,
        "rows": value.rows.map(row => row.to_json()),
        "total_votes": value.total_votes,
      } : Json).stringify(),
  )
}

///|
fn eligible(state : State, id : String) -> Bool {
  state.entries.any(entry => entry.id == id && entry.state == "approved")
}

///|
fn entry_status(state : State, id : String) -> String {
  state.entries
  .iter()
  .find_first(entry => entry.id == id)
  .map(entry => entry.state)
  .unwrap_or("unavailable")
}

///|
fn last_choices(state : State) -> Map[String, String] {
  let choices : Map[String, String] = Map([])
  for ballot in state.vote_events {
    choices[ballot.actor] = ballot.entry_id
  }
  choices
}

///|
fn live_counts(state : State, roster : VotingRoster) -> Array[VoteCount] {
  let choices = last_choices(state)
  let approved = Set::from_array(
    state.entries
    .filter(entry => entry.state == "approved")
    .map(entry => entry.id),
  )
  let counts : Map[String, Int32] = Map([])
  for id in choices.values() {
    if !id.is_empty() && approved.contains(id) {
      counts[id] = counts.get(id).unwrap_or(0) + 1
    }
  }
  let rows = roster.rows.map(row => {
    let active = approved.contains(row.entry_id)
    {
      entry_id: row.entry_id,
      votes: if active {
        counts.get(row.entry_id).unwrap_or(0)
      } else {
        0
      },
      rank: 0,
      eligible_at_close: active,
    }
  })
  rows.sort_by((a, b) => {
    if a.eligible_at_close != b.eligible_at_close {
      if a.eligible_at_close {
        -1
      } else {
        1
      }
    } else if a.votes != b.votes {
      b.votes - a.votes
    } else {
      a.entry_id.compare(b.entry_id)
    }
  })
  let mut previous = -1
  let mut position = 0
  let mut rank = 0
  rows.map(row => {
    if !row.eligible_at_close {
      return row
    }
    position += 1
    if previous != row.votes {
      rank = position
      previous = row.votes
    }
    { ..row, rank, }
  })
}

///|
fn validate_voting_state(state : State, config : Config) -> Unit raise {
  guard state.voting_rosters.length() <= 1 &&
    state.voting_settlements.length() <= 1 &&
    state.vote_events.length() <= 100000 else {
    raise Unavailable
  }
  if !builtin(config) {
    guard state.voting_rosters.is_empty() &&
      state.voting_settlements.is_empty() &&
      state.vote_events.is_empty() else {
      raise Unavailable
    }
    return
  }
  if state.voting_rosters.get(0) is Some(roster) {
    guard roster.opens_ms == config.voting_opens_ms &&
      roster.closes_ms == config.voting_closes_ms &&
      roster.digest == roster_hash(config, roster) &&
      roster.version > 0 &&
      roster.rows.all(row => {
        state.entries.any(entry => {
          entry.id == row.entry_id &&
          entry.actor == row.actor &&
          entry.generation_id == row.generation_id
        })
      }) else {
      raise Unavailable
    }
    let row_ids : Set[String] = Set::new()
    let authors : Map[String, String] = Map([])
    for row in roster.rows {
      guard identifier(row.entry_id) &&
        identifier(row.generation_id) &&
        identifier(row.sha256) &&
        !row_ids.contains(row.entry_id) else {
        raise Unavailable
      }
      row_ids.add(row.entry_id)
      authors[row.entry_id] = row.actor
    }
    let intents : Set[String] = Set::new()
    for event in state.vote_events {
      let key = event.actor.length().to_string() +
        ":" +
        event.actor +
        event.intent
      guard !event.actor.is_empty() &&
        event.actor.length() <= 256 &&
        !event.intent.is_empty() &&
        event.intent.length() <= 128 &&
        event.created_ms >= roster.opens_ms &&
        event.created_ms < roster.closes_ms &&
        !intents.contains(key) &&
        (
          event.entry_id.is_empty() ||
          authors
          .get(event.entry_id)
          .map(author => author != event.actor)
          .unwrap_or(false)
        ) else {
        raise Unavailable
      }
      intents.add(key)
    }
  } else {
    guard state.vote_events.is_empty() && state.voting_settlements.is_empty() else {
      raise Unavailable
    }
  }
  if state.voting_settlements.get(0) is Some(value) {
    guard state.voting_rosters.get(0) is Some(roster) &&
      value.roster_digest == roster.digest &&
      value.closed_ms == config.voting_closes_ms &&
      value.digest == settlement_hash(config, value) else {
      raise Unavailable
    }
    guard value.version > roster.version &&
      value.rows.length() == roster.rows.length() &&
      value.total_votes >= 0 &&
      value.total_votes <= state.vote_events.length() &&
      value.total_votes == value.rows.fold(init=0, (n, row) => n + row.votes) &&
      value.rows.all(row => {
        row.votes >= 0 &&
        row.votes <= state.vote_events.length() &&
        row.rank >= 0 &&
        roster.rows.any(entry => entry.entry_id == row.entry_id)
      }) else {
      raise Unavailable
    }
  }
}

///|
/// State-only deterministic clock advance. Caller persists under the same lock.
fn advance_voting(state : State, config : Config, now : UInt64) -> State raise {
  if !builtin(config) || now < config.voting_opens_ms {
    return state
  }
  let frozen = if state.voting_rosters.is_empty() {
    let rows = state.entries
      .filter(entry => entry.state == "approved")
      .map(entry => {
        guard state.generations
          .iter()
          .find_first(job => {
            job.id == entry.generation_id && job.state == "completed"
          })
          is Some(job) else {
          raise Unavailable
        }
        {
          entry_id: entry.id,
          generation_id: job.id,
          sha256: job.sha256,
          title: entry.title,
          display_name: entry.display_name,
          actor: entry.actor,
        }
      })
    rows.sort_by((a, b) => a.entry_id.compare(b.entry_id))
    let roster : VotingRoster = {
      version: state.revision + 1,
      digest: "",
      opens_ms: config.voting_opens_ms,
      closes_ms: config.voting_closes_ms,
      rows,
    }
    {
      ..state,
      revision: state.revision + 1,
      voting_rosters: [{ ..roster, digest: roster_hash(config, roster), }],
    }
  } else {
    state
  }
  if now < config.voting_closes_ms || !frozen.voting_settlements.is_empty() {
    return frozen
  }
  let roster = frozen.voting_rosters[0]
  let rows = live_counts(frozen, roster)
  let value : VotingSettlement = {
    version: frozen.revision + 1,
    digest: "",
    roster_digest: roster.digest,
    closed_ms: config.voting_closes_ms,
    rows,
    total_votes: rows.fold(init=0, (n, row) => n + row.votes),
  }
  {
    ..frozen,
    revision: frozen.revision + 1,
    voting_settlements: [{ ..value, digest: settlement_hash(config, value), }],
  }
}

///|
fn voting_projection(
  state : State,
  config : Config,
  now : UInt64,
  actor : String?,
) -> Json {
  let roster = state.voting_rosters.get(0)
  let settlement = state.voting_settlements.get(0)
  let phase = if settlement is Some(_) {
    "closed"
  } else if now < config.voting_opens_ms {
    "waiting"
  } else if now < config.voting_closes_ms {
    "open"
  } else {
    "closed"
  }
  let counts = match (settlement, roster) {
    (Some(value), _) => value.rows
    (_, Some(value)) => live_counts(state, value)
    _ => []
  }
  let selected = actor
    .map(id => last_choices(state).get(id).unwrap_or(""))
    .unwrap_or("")
  let can_vote = builtin(config) &&
    phase == "open" &&
    actor
    .map(id => {
      roster
      .map(value => {
        value.rows.any(row => row.actor != id && eligible(state, row.entry_id))
      })
      .unwrap_or(false)
    })
    .unwrap_or(false)
  {
    "mode": if builtin(config) {
      "builtin"
    } else {
      "external"
    },
    "phase": phase,
    "can_vote": can_vote,
    "my_entry_id": if eligible(state, selected) {
      selected
    } else {
      ""
    },
    "roster_version": roster.map(value => value.version).unwrap_or(0),
    "roster_digest": roster.map(value => value.digest).unwrap_or(""),
    "settled": settlement is Some(_),
    "settlement_version": settlement.map(value => value.version).unwrap_or(0),
    "settlement_digest": settlement.map(value => value.digest).unwrap_or(""),
    "counts": counts.map(row => {
      (
        {
          "entry_id": row.entry_id,
          "votes": row.votes,
          "rank": row.rank,
          "status": entry_status(state, row.entry_id),
          "eligible": row.eligible_at_close && eligible(state, row.entry_id),
        } : Json)
    }),
    "total_votes": counts.fold(init=0, (n, row) => n + row.votes),
    "rules": if builtin(config) {
      "过审作品参赛，大众投票决定一、二、三等奖。每个登录账户一票，截止前可改投或取消；不能投自己，截止前撤回的作品不计票。同票并列，涉及获奖名次时暂停分奖，由主办公布处理安排。每 4 秒更新。"
    } else {
      ""
    },
  }
}

///|
fn vote_transition(
  state : State,
  config : Config,
  action : String,
  payload : Json,
  now : UInt64,
  actor : String,
) -> State raise {
  guard builtin(config) else { raise Denied }
  let intent = text(payload, "intent", 128)
  let id = if action == "vote" { text(payload, "entry_id", 64) } else { "" }
  if state.vote_events
    .iter()
    .find_first(event => event.actor == actor && event.intent == intent)
    is Some(previous) {
    guard previous.entry_id == id else {
      raise Conflict("这次投票请求已经记录，请刷新后重试。")
    }
    return state
  }
  guard state.voting_settlements.is_empty() &&
    now >= config.voting_opens_ms &&
    now < config.voting_closes_ms else {
    raise Conflict("当前不在投票时间。")
  }
  guard state.voting_rosters.get(0) is Some(roster) else { raise Unavailable }
  if action == "vote" {
    guard roster.rows.iter().find_first(row => row.entry_id == id) is Some(row) &&
      eligible(state, id) else {
      raise Conflict("这件作品已不能参与投票。")
    }
    guard row.actor != actor else {
      raise Conflict(
        "不能给自己的作品投票，可以为其他创作者加油。",
      )
    }
  }
  guard state.vote_events.length() < 100000 else {
    raise Conflict("投票记录暂时已满，请联系主办。")
  }
  {
    ..state,
    revision: state.revision + 1,
    vote_events: state.vote_events +
    [{ actor, intent, entry_id: id, created_ms: now, }],
  }
}

///|
fn settlement_export(state : State, config : Config) -> Json raise {
  guard builtin(config) &&
    state.voting_settlements.get(0) is Some(value) &&
    state.voting_rosters.get(0) is Some(roster) else {
    raise Conflict("投票结束后才能导出结算。")
  }
  {
    "settlement": {
      "challenge_id": state.challenge_id,
      "roster_version": roster.version,
      "roster_digest": roster.digest,
      "version": value.version,
      "digest": value.digest,
      "closed_ms": value.closed_ms,
      "total_votes": value.total_votes,
      "rows": value.rows.map(count => {
        let row = roster.rows
          .iter()
          .find_first(row => row.entry_id == count.entry_id)
          .unwrap()
        let withdrawn = !eligible(state, row.entry_id)
        (
          {
            "entry_id": count.entry_id,
            "votes": count.votes,
            "rank": count.rank,
            "eligible_at_close": count.eligible_at_close,
            "withdrawn": withdrawn,
            "status": entry_status(state, row.entry_id),
            "title": if withdrawn {
              ""
            } else {
              row.title
            },
            "display_name": if withdrawn {
              ""
            } else {
              row.display_name
            },
            "generation_id": if withdrawn {
              ""
            } else {
              row.generation_id
            },
            "sha256": if withdrawn {
              ""
            } else {
              row.sha256
            },
          } : Json)
      }),
    },
  }
}
