///|
fn public_entry(entry : Entry, state : State) -> Json {
  let job = state.generations
    .iter()
    .find_first(job => job.id == entry.generation_id)
    .unwrap()
  {
    "id": entry.id,
    "generation_id": job.id,
    "title": entry.title,
    "display_name": entry.display_name,
    "sha256": job.sha256,
    "submitted_ms": entry.submitted_ms,
  }
}

///|
fn snapshot(
  state : State,
  config : Config,
  now : UInt64,
  actor : String?,
  operator : Bool,
) -> Json {
  let approved = state.entries.filter(entry => entry.state == "approved")
  let own = state.generations.filter(job => actor == Some(job.actor))
  let mine = state.entries.filter(entry => actor == Some(entry.actor))
  let queue = if operator {
    state.entries.filter(entry => entry.state == "pending")
  } else {
    []
  }
  {
    "server_ms": now,
    "event": {
      "id": config.brief.id,
      "name": config.brief.name,
      "topic": config.brief.topic,
      "scope": config.brief.scope,
      "possibility_wiki": config.brief.possibility_wiki,
      "first_person_solution": config.brief.first_person_solution,
      "opens_ms": config.opens_ms,
      "deadline_ms": config.brief.deadline_ms,
      "voting_opens_ms": config.voting_opens_ms,
      "voting_closes_ms": config.voting_closes_ms,
      "awards_ms": config.awards_ms,
      "participant_quota": config.participant_quota,
      "provider_ready": !config.provider_origin.is_empty(),
    },
    "revision": state.revision,
    "event_remaining": (config.event_quota - state.generations.length()).max(0),
    "viewer": { "account_id": actor.unwrap_or(""), "operator": operator },
    "gallery": approved.map(entry => public_entry(entry, state)),
    "generations": own.map(job => {
      (
        {
          "id": job.id,
          "prompt": job.prompt,
          "state": job.state,
          "created_ms": job.created_ms,
          "sha256": job.sha256,
          "reason": job.reason,
        } : Json)
    }),
    "entries": mine.map(entry => entry.to_json()),
    "review_queue": queue.map(entry => {
      "entry": entry.to_json(),
      "generation": state.generations
      .iter()
      .find_first(job => job.id == entry.generation_id)
      .unwrap()
      .to_json(),
    }),
    "reconcile_queue": if operator {
      state.generations
      .filter(job => job.state == "needs_reconcile")
      .map(job => job.to_json())
    } else {
      []
    },
    "award_drafts": if operator {
      state.awards.map(award => {
        (
          {
            "entry_id": award.entry_id,
            "prize": award.prize,
            "reason": award.reason,
          } : Json)
      })
    } else {
      []
    },
    "remaining": (config.participant_quota -
    own.filter(job => job.state != "failed").length()).max(0),
    "voting_url": if now >= config.voting_opens_ms &&
      now < config.voting_closes_ms {
      if state.voting_url == "preview" {
        "./coffee-vote-preview.html"
      } else {
        state.voting_url
      }
    } else {
      ""
    },
    "configured_voting_url": if operator {
      state.voting_url
    } else {
      ""
    },
    "voting_preview": state.voting_url == "preview",
    "awards": if state.results_published && now >= config.awards_ms {
      state.awards.map(award => {
        (
          {
            "entry_id": award.entry_id,
            "prize": award.prize,
            "reason": award.reason,
          } : Json)
      })
    } else {
      []
    },
  }
}

///|
fn transition(
  state : State,
  config : Config,
  action : String,
  payload : Json,
  now : UInt64,
  actor : String,
  operator : Bool,
) -> State raise {
  guard !actor.is_empty() else { raise Denied }
  let next = { ..state, revision: state.revision + 1, }
  match action {
    "resolve-failed" => {
      guard operator && payload is { "confirmed_no_output": True, .. } else {
        raise Denied
      }
      let id = text(payload, "generation_id", 64)
      let reason = text(payload, "reason", 1000)
      guard state.generations.any(job => {
        job.id == id && job.state == "needs_reconcile"
      }) else {
        raise Conflict("生成状态已变化。")
      }
      {
        ..next,
        generations: state.generations.map(job => {
          if job.id == id {
            {
              ..job,
              state: "failed",
              reason: "主办已核对：本次未完成，次数已退回。",
              provider_id: "checked-by:" + actor + ":" + reason,
            }
          } else {
            job
          }
        }),
      }
    }
    "generate" => {
      guard now >= config.opens_ms && now < config.brief.deadline_ms else {
        raise Conflict("本期创作已截止。")
      }
      guard !config.provider_origin.is_empty() else { raise Unavailable }
      let prompt = text(payload, "prompt", 2000)
      let intent = text(payload, "intent", 128)
      let id = hash(config.brief.id + ":" + actor + ":" + intent)
      if state.generations.iter().find_first(job => job.id == id) is Some(job) {
        guard job.prompt == prompt else {
          raise Conflict("这次请求已保存，请刷新查看。")
        }
        return state
      }
      guard state.generations.length() < config.event_quota else {
        raise Conflict("本期创作名额已用完。")
      }
      let own = state.generations.filter(job => {
        job.actor == actor && job.state != "failed"
      })
      guard own.length() < config.participant_quota else {
        raise Conflict("你的本期生成次数已用完。")
      }
      guard !own.any(job => {
        ["queued", "running", "dispatching", "needs_reconcile"].contains(
          job.state,
        )
      }) else {
        raise Conflict(
          "还有一张作品正在处理中，请先查看结果。",
        )
      }
      {
        ..next,
        generations: state.generations +
        [
          {
            id,
            actor,
            intent,
            prompt,
            state: "queued",
            created_ms: now,
            started_ms: 0UL,
            finished_ms: 0UL,
            sha256: "",
            reason: "",
            provider_id: "",
          },
        ],
      }
    }
    "submit" => {
      guard now >= config.opens_ms && now < config.brief.deadline_ms else {
        raise Conflict("本期投稿已截止。")
      }
      guard payload is { "consent": True, .. } else {
        raise Invalid("参赛前请同意公开展示这张作品。")
      }
      let job_id = text(payload, "generation_id", 64)
      guard state.generations
        .iter()
        .find_first(job => {
          job.id == job_id && job.actor == actor && job.state == "completed"
        })
        is Some(_) else {
        raise Denied
      }
      let title = text(payload, "title", 60)
      let display_name = text(payload, "display_name", 40)
      if state.entries
        .iter()
        .find_first(entry => {
          entry.actor == actor &&
          entry.generation_id == job_id &&
          ["pending", "approved"].contains(entry.state)
        })
        is Some(_) {
        return state
      }
      let entries = state.entries.map(entry => {
        if entry.actor == actor && ["pending", "approved"].contains(entry.state) {
          { ..entry, state: "superseded", }
        } else {
          entry
        }
      })
      entries.push({
        id: hash(job_id + ":" + state.revision.to_string()),
        generation_id: job_id,
        actor,
        display_name,
        title,
        state: "pending",
        submitted_ms: now,
        reviewed_ms: 0UL,
        reviewer: "",
        reason: "",
      })
      { ..next, entries, }
    }
    "approve" | "reject" | "withdraw" => {
      let id = text(payload, "entry_id", 64)
      guard state.entries.iter().find_first(entry => entry.id == id)
        is Some(entry) else {
        raise Invalid("投稿不存在。")
      }
      if action == "withdraw" {
        guard entry.actor == actor else { raise Denied }
      } else {
        guard operator && entry.state == "pending" else { raise Denied }
      }
      if action == "approve" {
        guard entry.actor != actor else {
          raise Conflict("请由另一位主办审核自己的作品。")
        }
        guard now < config.voting_opens_ms else {
          raise Conflict("投票已开始，本期作品名单已锁定。")
        }
      }
      let reason = text(payload, "reason", 1000, optional=action != "reject")
      let value = {
        ..entry,
        state: if action == "approve" {
          "approved"
        } else if action == "reject" {
          "rejected"
        } else {
          "withdrawn"
        },
        reason,
        reviewer: actor,
        reviewed_ms: now,
      }
      {
        ..next,
        entries: state.entries.map(entry => {
          if entry.id == id {
            value
          } else {
            entry
          }
        }),
      }
    }
    "set-voting-url" => {
      guard operator && now < config.voting_opens_ms else { raise Denied }
      let url = text(payload, "url", 1000)
      guard (url == "preview" || url.has_prefix("https://docs.qq.com/")) &&
        !url.contains("\n") &&
        !url.contains("\r") else {
        raise Invalid("请填写腾讯文档的 HTTPS 投票链接。")
      }
      { ..next, voting_url: url, }
    }
    "award" => {
      guard operator &&
        now >= config.voting_closes_ms &&
        !state.results_published else {
        raise Denied
      }
      let id = text(payload, "entry_id", 64)
      let prize = text(payload, "prize", 40)
      guard ["creative", "popular", "coffee"].contains(prize) &&
        state.entries.any(entry => entry.id == id && entry.state == "approved") else {
        raise Invalid("请检查奖项和过审作品。")
      }
      let awards = state.awards.filter(award => award.prize != prize)
      guard !awards.any(award => award.entry_id == id) else {
        raise Conflict("每件作品最多领取一个奖项。")
      }
      awards.push({
        entry_id: id,
        prize,
        reason: text(payload, "reason", 1000),
        recorded_ms: now,
        operator: actor,
      })
      { ..next, awards, }
    }
    "publish-results" => {
      guard operator && now >= config.awards_ms && state.awards.length() == 3 else {
        raise Denied
      }
      guard state.awards.all(award => {
        state.entries.any(entry => {
          entry.id == award.entry_id && entry.state == "approved"
        })
      }) else {
        raise Conflict("获奖作品状态已变化，请重新核对。")
      }
      { ..next, results_published: true, }
    }
    _ => raise Invalid("操作不存在。")
  }
}

///|
pub async fn execute(
  action : String,
  payload : Json,
  now : UInt64,
  actor : String?,
  operator : Bool,
  path : String,
  config_path : String,
) -> Json {
  let config = load_config(config_path)
  let file = lock(path)
  defer file.close()
  defer file.unlock()
  let state = read(path, config)
  if action == "snapshot" {
    return snapshot(state, config, now, actor, operator)
  }
  let next = transition(
    state,
    config,
    action,
    payload,
    now,
    actor.unwrap_or(""),
    operator,
  )
  if next.revision != state.revision {
    save(path, next)
  }
  snapshot(next, config, now, actor, operator)
}

///|
pub async fn image(
  id : String,
  actor : String?,
  path : String,
  config_path : String,
  operator~ : Bool = false,
) -> Bytes {
  guard identifier(id) else { raise Denied }
  let config = load_config(config_path)
  let file = lock(path)
  defer file.close()
  defer file.unlock()
  let state = read(path, config)
  guard state.generations.any(job => {
    job.id == id &&
    job.state == "completed" &&
    (
      operator ||
      actor == Some(job.actor) ||
      state.entries.any(entry => {
        entry.generation_id == id && entry.state == "approved"
      })
    )
  }) else {
    raise Denied
  }
  let target = path + ".images/" + id + ".png"
  guard @fs.kind(target, follow_symlink=false) is Regular else {
    raise Unavailable
  }
  @fs.read_file(target).binary()
}
