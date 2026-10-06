///|
/// The production adapter and socket-free tests use this exact response seam.
pub struct ResponseSink {
  start_response : async (Int, Map[String, String]) -> Unit
  write_bytes : async (Bytes) -> Unit
  end_response : async () -> Unit
  close_connection : () -> Unit
  mut started : Bool
  mut idle_timeout_ms : Int
}

///|
pub fn response_sink(
  start : async (Int, Map[String, String]) -> Unit,
  write : async (Bytes) -> Unit,
  finish : async () -> Unit,
  close : () -> Unit,
) -> ResponseSink {
  {
    start_response: start,
    write_bytes: write,
    end_response: finish,
    close_connection: close,
    started: false,
    idle_timeout_ms: 30000,
  }
}

///|
pub impl @io.Writer for ResponseSink with fn write_once(
  self,
  bytes,
  offset~,
  len~,
) {
  @async.with_timeout(self.idle_timeout_ms, () => {
    (self.write_bytes)(bytes[offset:offset + len].to_owned())
  })
  len
}

///|
async fn ResponseSink::start(
  self : ResponseSink,
  code : Int,
  headers : Map[String, String],
) -> Unit {
  self.started = true
  @async.with_timeout(self.idle_timeout_ms, () => {
    (self.start_response)(code, headers)
  })
}

///|
async fn ResponseSink::json(
  self : ResponseSink,
  code : Int,
  value : Json,
) -> Unit {
  let bytes = @utf8.encode(value.stringify())
  // Feature-local response bound matches the strict package index/client.
  // Never silently truncate owner grant history or exact recipient metadata.
  if bytes.length() > 8 * 1024 * 1024 {
    reject(503, "package_metadata_capacity")
  }
  self.start(code, {
    "content-type": "application/json; charset=utf-8",
    "content-length": bytes.length().to_string(),
    "cache-control": "private, no-store, no-transform",
    "x-content-type-options": "nosniff",
  })
  @async.with_timeout(self.idle_timeout_ms, () => (self.write_bytes)(bytes))
  @async.with_timeout(self.idle_timeout_ms, () => (self.end_response)())
}
