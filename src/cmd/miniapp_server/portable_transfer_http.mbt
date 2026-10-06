///|
/// Thin real-connection adapter. All auth, streaming and lifecycle behavior is
/// in the same injected core exercised by socket-free native acceptance tests.
async fn handle_portable_transfer_request(
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
) -> Bool {
  if !@town_portable_http.is_transfer_path(request.path) {
    return false
  }
  let limits = @town_portable_transfer.default_limits()
  let service : @town_portable_http.TransferService = {
    accounts: account_application(),
    marketplace: marketplace_application(),
    store: @town_portable_transfer.portable_store(
      @storage.moontown_product_state_dir() + "/marketplace/portable-packages",
      limits~,
    ),
    limits,
    now: () => @env.now(),
  }
  let sink = @town_portable_http.response_sink(
    (code, headers) => {
      conn.send_response(
        code,
        if code < 400 {
          "OK"
        } else {
          "Error"
        },
        extra_headers=headers,
      )
    },
    bytes => conn.write(bytes),
    () => conn.end_response(),
    () => conn.close(),
  )
  service.handle(request, body, sink)
}
