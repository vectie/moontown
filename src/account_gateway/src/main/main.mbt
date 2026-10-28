///|
fn required(name : String) -> String raise {
  guard @env.get_env_var(name) is Some(value) && !value.is_empty() else {
    fail("Missing gateway deployment setting: " + name)
  }
  value
}

///|
/// Trusted platform process, never installed in a tenant workspace or GPU node.
async fn main {
  try {
    guard required("LUNANEXA_WEBIDE_CLIENT_ID") == "moontown" &&
      required("MOONTOWN_ACCOUNT_PROVIDER") == "lunanexa" else {
      fail("Unsupported account gateway profile")
    }
    let public_origin = required("LUNANEXA_WEBIDE_PUBLIC_ORIGIN")
    guard required("MOONTOWN_IDENTITY_ORIGIN") == public_origin &&
      required("MOONTOWN_IDENTITY_PREFIX") == "/user" &&
      @account_identity.Client::new(
        endpoint=required("MOONTOWN_IDENTITY_ENDPOINT"),
        host=required("MOONTOWN_IDENTITY_HOST"),
        origin=public_origin,
        prefix="/user",
      )
      is Some(client) else {
      fail("Identity and workspace origins must agree")
    }
    if @env.args() is [_, "--check-identity"] {
      // Deployment preflight only: no real account, controller grant, workspace
      // provisioning, or Kubernetes credential is needed for this probe.
      let authority = required("MOONTOWN_IDENTITY_HOST").split(":").to_array()
      let port = if authority.length() == 2 {
        @string.parse_int(authority[1])
      } else {
        443
      }
      let address = @async.with_timeout(5000, () => {
        @socket.Addr::resolve(authority[0].to_owned(), port~)
      })
      println(
        "Credential-free identity probe destination: " + address.to_string(),
      )
      let mut ready = false
      for attempt in 0..<5 {
        let status = client.probe() catch {
          error => {
            eprintln("Credential-free identity transport probe: \{Repr(error)}")
            0
          }
        }
        if status == 401 {
          ready = true
          break
        }
        if status != 0 {
          eprintln("Invalid-session probe HTTP status \{status}")
        }
        if attempt < 4 {
          @async.sleep(1500)
        }
      }
      guard ready else { fail("Invalid-session probe did not return 401") }
      println("Identity HTTPS authority reachable; invalid session rejected")
      return
    }
    let identity : BrowserIdentity = {
      flights: {},
      resolve: cookie => client.resolve(identity_cookies(cookie)),
    }
    if @env.get_env_var("MOONTOWN_GATEWAY_MODE") == Some("public") {
      run_public_platform(identity)
      return
    }
    let config : @host.HostConfig = @json.from_json(
      @json.parse(@fs.read_file(required("LUNANEXA_WEBIDE_CONFIG_FILE")).text()),
    )
    let container : @host.ExclusiveContainer = @json.from_json(
      @json.parse(
        @fs.read_file(required("LUNANEXA_WEBIDE_CONTAINER_FILE")).text(),
      ),
    )
    guard !container.gpu &&
      @env.get_env_var("LUNANEXA_WEBIDE_REQUIRE_EXCLUSIVE") != Some("true") else {
      fail(
        "Account gateway requires the existing personal CPU workspace profile",
      )
    }
    let host = @host.WorkspaceHost::new(config)
    let bridge = @webide.Bridge::new(
      {
        client_id: "moontown",
        public_origin,
        maximum_sessions: 512,
        maximum_request_bytes: 67108864,
        maximum_socket_message_bytes: 16777216,
        request_timeout_ms: 300000,
        authorization_interval_ms: 5000,
      },
      code => host.redeem("moontown", code),
      grant => host.authorize(grant),
      (id, grant) => host.provision(id, grant, container~),
      public_base_path=@env.get_env_var("MOONTOWN_WORKSPACE_BASE").unwrap_or(
        "/moontown",
      ),
      stop=Some(id => host.stop(id)),
      authorize_browser=Some((grant, cookie) => {
        identity.authorize(grant, cookie)
      }),
      handle_authorized=Some((grant, request, conn) => {
        identity.handle(grant, request, conn)
      }),
    )
    let server = @http.Server(
      @socket.Addr::parse(required("LUNANEXA_WEBIDE_BIND")),
    )
    defer server.close()
    @async.with_task_group(group => {
      group.spawn_bg(() => {
        while true {
          host.reconcile(client_id="moontown") catch {
            _ => eprintln("Workspace reconciliation will retry")
          }
          @async.sleep(30000)
        }
      })
      server.run_forever(
        (request, body, conn) => bridge.handle(request, body, conn),
        max_connections=1024,
        allow_failure=true,
      )
    })
  } catch {
    _ => {
      eprintln(
        "Account gateway stopped; verify deployment configuration and connectivity",
      )
      @sys.exit(1)
    }
  }
}
