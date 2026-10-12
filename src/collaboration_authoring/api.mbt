///|
pub(all) struct Request {
  contract_version : String
  request_id : String
  action : String
  draft_id : String
  revision : String
  new_draft_id : String
  artifact_path : String
  draft : @contract.Draft?
  payload : Json?
} derive(Debug, ToJson, FromJson)

///|
pub fn decode_request(raw : String) -> Request raise {
  guard @utf8.encode(raw).length() <= 131072 else {
    raise CollaborationError("Request too large")
  }
  let json = @json.parse(raw)
  // Derived optional record fields use absence for None. Browser envelopes
  // also send explicit null for unused fields; normalize those two fields
  // without changing non-null payloads or accepting a malformed draft.
  let normalized = match json {
    Object(fields) => {
      let fields = fields.copy()
      for name in ["draft", "payload"] {
        if fields.get(name) is Some(Null) {
          ignore(fields.remove(name))
        }
      }
      Json::object(fields)
    }
    _ => json
  }
  let request : Request = @json.from_json(normalized)
  guard request.contract_version == "moontown.collaboration.request.v1" &&
    @contract.safe_id(request.request_id) else {
    raise CollaborationError("Invalid collaboration request")
  }
  request
}

///|
pub fn error_message(error : Error) -> String {
  match error {
    CollaborationError(message) => message
    _ =>
      "Collaboration storage or input is unavailable. Reopen the draft and retry."
  }
}

///|
pub async fn Store::request(
  self : Store,
  request : Request,
  recorded_at : String,
) -> @contract.Reply {
  let reply : @contract.Reply = {
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
    match request.action {
      "source-list" => {
        guard request.payload is Some({ "book_id": String(book_id), .. }) else {
          raise CollaborationError("Choose a registered Book ID")
        }
        { ..reply, source_listing: Some(self.list_sources(book_id)), }
      }
      "outcome-list" => { ..reply, outcomes: self.list_outcomes(), }
      "outcome-inspect" => {
        let key = outcome_request_key(request)
        { ..reply, outcome: Some(self.inspect_outcome(key)), }
      }
      "list" => {
        let drafts = self.list()
        let books = self.books() catch { _ => [] }
        {
          ..reply,
          drafts,
          books,
          error: if books.is_empty() {
            "No readable existing Books are registered. Incomplete drafts can still be saved."
          } else {
            ""
          },
        }
      }
      "save" => {
        guard request.draft is Some(draft) && draft.draft_id == request.draft_id else {
          raise CollaborationError("Draft identity does not match the request")
        }
        {
          ..reply,
          saved: Some(self.save(draft, request.revision, recorded_at)),
        }
      }
      "load" =>
        {
          ..reply,
          saved: Some(self.load(request.draft_id, revision=request.revision)),
        }
      "reuse" =>
        {
          ..reply,
          saved: Some(
            self.reuse(
              request.draft_id,
              request.revision,
              request.new_draft_id,
              recorded_at,
            ),
          ),
        }
      "prepare" =>
        {
          ..reply,
          prepared: Some(self.prepare(request.draft_id, request.revision)),
        }
      _ => raise CollaborationError("Unknown collaboration action")
    }
  } catch {
    error => { ..reply, ok: false, error: error_message(error), }
  }
}
