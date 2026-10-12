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
