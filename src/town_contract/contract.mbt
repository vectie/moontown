///|
pub fn schema_version() -> String {
  "moontown.api.v1"
}

///|
pub fn desktop_contract_path() -> String {
  "/api/contract"
}

///|
pub fn desktop_standing_watch_path() -> String {
  "/api/operator-requests"
}

///|
pub fn desktop_evidence_book_path() -> String {
  "/api/book-template-requests"
}

///|
pub fn desktop_research_handoff_path() -> String {
  "/api/research-handoffs/inspect"
}

///|
pub fn desktop_research_handoff_start_path() -> String {
  "/api/research-handoffs/start"
}

///|
pub fn desktop_research_handoff_reconcile_path() -> String {
  "/api/research-handoffs/reconcile"
}

///|
pub fn desktop_moonflow_research_start_path() -> String {
  "/api/research-handoffs/moonflow/start"
}

///|
pub fn desktop_moonflow_research_reconcile_path() -> String {
  "/api/research-handoffs/moonflow/reconcile"
}

///|
pub fn miniapp_contract_path() -> String {
  "/miniapp/contract"
}

///|
pub fn miniapp_health_path() -> String {
  "/miniapp/health"
}

///|
pub fn miniapp_snapshot_path() -> String {
  "/miniapp/town/snapshot"
}

///|
pub fn miniapp_standing_watch_path() -> String {
  "/miniapp/research/watches"
}

///|
pub fn miniapp_evidence_book_path() -> String {
  "/miniapp/research/evidence-books"
}

///|
fn endpoint(
  id : String,
  http_method : String,
  path : String,
  capability : String,
) -> Json {
  { "id": id, "method": http_method, "path": path, "capability": capability }
}

///|
pub fn desktop_contract() -> Json {
  {
    "schema": schema_version(),
    "audience": "trusted-local-operator",
    "transport": "localhost",
    "endpoints": [
      endpoint("contract", "GET", desktop_contract_path(), "contract.read"),
      endpoint(
        "submit-standing-watch",
        "POST",
        desktop_standing_watch_path(),
        "research.watch.submit",
      ),
      endpoint(
        "queue-evidence-book",
        "POST",
        desktop_evidence_book_path(),
        "research.evidence-book.queue",
      ),
      endpoint(
        "inspect-research-handoff",
        "POST",
        desktop_research_handoff_path(),
        "civic.communication.handoff.inspect",
      ),
      endpoint(
        "start-research-handoff",
        "POST",
        desktop_research_handoff_start_path(),
        "civic.communication.handoff.execute",
      ),
      endpoint(
        "reconcile-research-handoff",
        "POST",
        desktop_research_handoff_reconcile_path(),
        "civic.communication.handoff.reconcile",
      ),
      endpoint(
        "start-moonflow-research-handoff",
        "POST",
        desktop_moonflow_research_start_path(),
        "civic.communication.moonflow.execute",
      ),
      endpoint(
        "reconcile-moonflow-research-handoff",
        "POST",
        desktop_moonflow_research_reconcile_path(),
        "civic.communication.moonflow.reconcile",
      ),
    ],
  }
}

///|
pub fn miniapp_contract() -> Json {
  {
    "schema": schema_version(),
    "audience": "authenticated-miniapp-user",
    "transport": "https-or-local-dev",
    "sessionHeader": "x-miniapp-session",
    "endpoints": [
      endpoint("health", "GET", miniapp_health_path(), "health.read"),
      endpoint("contract", "GET", miniapp_contract_path(), "contract.read"),
      endpoint(
        "load-town-snapshot",
        "GET",
        miniapp_snapshot_path(),
        "town.snapshot.read",
      ),
      endpoint(
        "submit-standing-watch",
        "POST",
        miniapp_standing_watch_path(),
        "research.watch.submit",
      ),
      endpoint(
        "queue-evidence-book",
        "POST",
        miniapp_evidence_book_path(),
        "research.evidence-book.queue",
      ),
    ],
  }
}
