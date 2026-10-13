///|
fn qualification_failure_reasons(
  track : CompetitionTrack,
  metrics : Array[MetricValue],
) -> Array[String] {
  let failures : Array[String] = []
  for gate in track.gates {
    guard metrics.iter().find_first(m => m.metric_id == gate.metric_id)
      is Some(metric) else {
      failures.push(
        gate.label + ": required metric " + gate.metric_id + " is missing",
      )
      continue
    }
    let failed = (gate.comparison == "gte" && metric.value < gate.threshold) ||
      (gate.comparison == "lte" && metric.value > gate.threshold)
    if failed {
      let unit = match
        track.metrics.iter().find_first(m => m.id == gate.metric_id) {
        Some(rule) => if rule.unit.is_empty() { "" } else { " " + rule.unit }
        None => ""
      }
      failures.push(
        gate.label +
        ": " +
        gate.metric_id +
        " measured " +
        metric.value.to_string() +
        unit +
        "; requires " +
        (if gate.comparison == "gte" { "at least " } else { "at most " }) +
        gate.threshold.to_string() +
        unit,
      )
    }
  }
  failures
}

///|
fn metric_score(
  track : CompetitionTrack,
  metrics : Array[MetricValue],
) -> Double? {
  let mut total = 0.0
  let mut weights = 0.0
  for rule in track.metrics {
    guard metrics.iter().find_first(m => m.metric_id == rule.id) is Some(metric) &&
      valid_metric_number(metric.value) &&
      (rule.direction != "min" || metric.value > 0.0) &&
      rule.baseline > 0.0 &&
      rule.weight > 0.0 else {
      return None
    }
    let ratio = if rule.direction == "min" {
      rule.baseline / metric.value
    } else {
      metric.value / rule.baseline
    }
    total += ratio * rule.weight
    weights += rule.weight
  }
  guard weights > 0.0 else { return None }
  guard qualification_failure_reasons(track, metrics).is_empty() else {
    return None
  }
  let score = total / weights * 100.0
  if score == score && score < 1.0e300 {
    Some(score)
  } else {
    None
  }
}

///|
/// Only human-approved current-version receipts rank. Equal scores favor the
/// earlier review, then the stable team ID, so polling cannot shuffle ties.
pub fn competition_leaderboard(
  state : HackathonState,
  challenge_id : String,
  track_id : String,
) -> Array[CompetitionBoardEntry] {
  let entries : Array[CompetitionBoardEntry] = []
  guard state.programs.iter().find_first(p => p.challenge_id == challenge_id)
    is Some(program) &&
    program.state != "draft" &&
    state.challenges.iter().find_first(c => c.id == challenge_id)
    is Some(challenge) &&
    challenge.published &&
    program.tracks.iter().find_first(t => t.id == track_id) is Some(track) else {
    return entries
  }
  for team in state.teams {
    if team.challenge_id != challenge_id {
      continue
    }
    let mut best : CompetitionBoardEntry? = None
    for submission in state.submissions {
      if submission.team_id != team.id {
        continue
      }
      guard state.submission_packages
        .iter()
        .find_first(p => p.submission_id == submission.id)
        is Some(package) &&
        package.track_id == track_id else {
        continue
      }
      let candidate : CompetitionBoardEntry? = if track.scoring_mode == "rubric" {
        let mut latest : Evaluation? = None
        for review in state.evaluations {
          if review.submission_id == submission.id &&
            review.benchmark_version == challenge.benchmark_version {
            latest = Some(review)
          }
        }
        match latest {
          Some(review) =>
            Some({
              rank: 0,
              team_id: team.id,
              team_name: team.name,
              submission_id: submission.id,
              score: review.total.to_double(),
              metrics: [],
              reviewed_ms: review.evaluated_ms,
              status: if program.state == "final" {
                "final"
              } else {
                "provisional"
              },
            })
          None => None
        }
      } else {
        let mut latest : BenchmarkRun? = None
        for run in state.benchmark_runs {
          if run.submission_id == submission.id &&
            run.benchmark_version == challenge.benchmark_version &&
            ["approved", "rejected"].contains(run.state) {
            latest = Some(run)
          }
        }
        match latest {
          Some(run) if run.state == "approved" =>
            match metric_score(track, run.metrics) {
              Some(score) =>
                Some({
                  rank: 0,
                  team_id: team.id,
                  team_name: team.name,
                  submission_id: submission.id,
                  score,
                  metrics: run.metrics,
                  reviewed_ms: run.finished_ms,
                  status: if program.state == "final" {
                    "final"
                  } else {
                    "provisional"
                  },
                })
              None => None
            }
          _ => None
        }
      }
      if candidate is Some(entry) &&
        (
          best is None ||
          (
            best is Some(current) &&
            (
              entry.score > current.score ||
              (
                entry.score == current.score &&
                entry.reviewed_ms < current.reviewed_ms
              )
            )
          )
        ) {
        best = Some(entry)
      }
    }
    if best is Some(entry) {
      entries.push(entry)
    }
  }
  entries.sort_by((a, b) => {
    if a.score != b.score {
      b.score.compare(a.score)
    } else if a.reviewed_ms != b.reviewed_ms {
      a.reviewed_ms.compare(b.reviewed_ms)
    } else {
      a.team_id.compare(b.team_id)
    }
  })
  for i in 0..<entries.length() {
    entries[i] = { ..entries[i], rank: i + 1, }
  }
  entries
}

///|
pub fn competition_finalization_ready(
  state : HackathonState,
  challenge_id : String,
) -> Bool {
  guard state.challenges.iter().find_first(c => c.id == challenge_id)
    is Some(challenge) &&
    state.programs.iter().find_first(p => p.challenge_id == challenge_id)
    is Some(program) else {
    return false
  }
  if state.appeals.any(a => {
      a.state == "open" &&
      state.submissions.any(s => {
        s.id == a.submission_id && s.challenge_id == challenge_id
      })
    }) {
    return false
  }
  if state.benchmark_runs.any(r => {
      (
        ["queued", "running"].contains(r.state) ||
        (
          r.state == "review" &&
          r.benchmark_version == challenge.benchmark_version
        )
      ) &&
      state.submissions.any(s => {
        s.id == r.submission_id && s.challenge_id == challenge_id
      })
    }) {
    return false
  }
  for submission in state.submissions {
    if submission.challenge_id != challenge_id {
      continue
    }
    // Earlier packages stay as receipts. The latest package for every team
    // must have a decision, including a rejection, before publication freezes.
    if state.submissions.any(s => {
        s.team_id == submission.team_id &&
        s.challenge_id == challenge_id &&
        s.version > submission.version
      }) {
      continue
    }
    guard state.submission_packages
      .iter()
      .find_first(p => p.submission_id == submission.id)
      is Some(package) &&
      program.tracks.iter().find_first(t => t.id == package.track_id)
      is Some(track) else {
      return false
    }
    if track.scoring_mode == "rubric" {
      if !state.evaluations.any(e => {
          e.submission_id == submission.id &&
          e.benchmark_version == challenge.benchmark_version
        }) {
        return false
      }
    } else if !state.benchmark_runs.any(r => {
        r.submission_id == submission.id &&
        r.benchmark_version == challenge.benchmark_version &&
        ["approved", "rejected"].contains(r.state)
      }) {
      return false
    }
  }
  true
}
