///|
pub async fn Store::request_oneoff(
  self : Store,
  request : Request,
  runtime : OneoffRuntime?,
  actor_id : String?,
  timestamp : String,
  observed_at : Int,
) -> @contract.Reply {
  let base : @contract.Reply = {
    contract_version: "moontown.collaboration.reply.v1",
    request_id: request.request_id,
    action: request.action,
    ok: true,
    error: "",
    books: [],
    drafts: [],
    saved: None,
    prepared: None,
    work: None,
    outcomes: [],
    outcome: None,
    source_listing: None,
  }
  try {
    if request.action == "oneoff-followup" {
      let (saved, work) = self.read_locked(() => {
        let saved = self.load_revision(request.draft_id, request.revision)
        let retained = self.retained_work(saved)
        let versions = self.retained_review_versions(saved)
        let history = self.outcome_history(
          saved,
          retained,
          versions[versions.length() - 1],
        )
        (saved, history.work)
      })
      let draft = match
        @contract.collective_followup(
          saved,
          work,
          request.payload.unwrap_or(Json::null()),
        ) {
        Ok(draft) => draft
        Err(error) => raise CollaborationError(error)
      }
      // Same authored request plus exact current sources is retry-safe through
      // save's existing optimistic fresh-ID guard. Never inherit work/reviews.
      return { ..base, saved: Some(self.save(draft, "", timestamp)), }
    }
    let work = match request.action {
      "oneoff-start" => {
        guard runtime is Some(config) else {
          raise CollaborationError(
            "One-off runtime is not configured. Set MOONTOWN_COLLABORATION_RUNTIME_JSON to a host-owned MoonClaw root/home/profile configuration, and configure that analysis profile and model in MoonClaw. Drafts remain usable",
          )
        }
        self.start_oneoff(
          request.draft_id,
          request.revision,
          config,
          background=true,
        )
      }
      "oneoff-read" => self.read_oneoff(request.draft_id, request.revision)
      "oneoff-decide" =>
        self.decide_oneoff(
          request.draft_id,
          request.revision,
          actor_id,
          request.payload.unwrap_or(Json::null()),
          timestamp,
        )
      "oneoff-book" =>
        self.submit_oneoff(
          request.draft_id,
          request.revision,
          request.payload.unwrap_or(Json::null()),
          observed_at,
        )
      "oneoff-read-book" =>
        self.refresh_oneoff_book(request.draft_id, request.revision)
      _ => raise CollaborationError("Unknown one-off action")
    }
    {
      ..base,
      work: Some({
        ..work,
        operator_id: actor_id.unwrap_or(""),
        detail: work.detail +
        (if runtime is None && work.status == "not_started" {
          " Runtime is not configured; host setup is required before Start."
        } else {
          ""
        }),
      }),
    }
  } catch {
    error => { ..base, ok: false, error: error_message(error), }
  }
}
