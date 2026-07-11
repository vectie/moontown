///|
fn render_miniapp_command(args : Array[String]) -> String {
  match args {
    ["routes"] => render_miniapp_routes()
    ["serve"] => render_miniapp_serve_help()
    ["dev-login", user_id] =>
      @miniapp_local_backend.miniapp_local_backend_dev_login(
        @miniapp_local_backend.miniapp_local_backend_fixture_state(),
        user_id,
        now_ms=7000UL,
      ).body
    ["snapshot", user_id] => render_miniapp_snapshot(user_id)
    ["buildings", "search", user_id, query] =>
      render_miniapp_search(user_id, query)
    ["buildings", "create", user_id] => render_miniapp_create_building(user_id)
    ["buildings", "place", user_id] => render_miniapp_place_building(user_id)
    ["buildings", "share", user_id] => render_miniapp_share_building(user_id)
    ["buildings", "publish", user_id] =>
      render_miniapp_publish_building(user_id)
    ["buildings", "archive", user_id] =>
      render_miniapp_archive_building(user_id)
    ["agents", "create", user_id] => render_miniapp_create_agent(user_id)
    ["chat", "send", user_id] => render_miniapp_chat_send(user_id)
    ["runs", "cancel", user_id, run_id] =>
      render_miniapp_run_action(user_id, run_id, "cancel")
    ["runs", "retry", user_id, run_id] =>
      render_miniapp_run_action(user_id, run_id, "retry")
    ["reviews", "accept", user_id, run_id] =>
      render_miniapp_run_action(user_id, run_id, "accept")
    _ => render_miniapp_help()
  }
}

///|
fn render_miniapp_help() -> String {
  "MoonTown miniapp local backend\ncommands=routes serve dev-login <user> snapshot <user> buildings search <user> <query> buildings create <user> buildings place <user> buildings share <user> buildings publish <user> buildings archive <user> agents create <user> chat send <user> runs cancel|retry <user> <run> reviews accept <user> <run>"
}

///|
fn render_miniapp_serve_help() -> String {
  "kind=miniapp-serve command=node scripts/miniapp-local-backend.mjs --port 18191 --state .moontown/miniapp-local-backend-state.json backendBaseUrl=http://127.0.0.1:18191 smoke=node scripts/miniapp-local-backend.mjs --smoke --port 18191 reset=node scripts/miniapp-local-backend.mjs --port 18191 --reset-state"
}

///|
fn render_miniapp_routes() -> String {
  let routes = @miniapp_local_backend.miniapp_local_backend_routes()
  let lines : Array[String] = ["MoonTown miniapp local backend routes"]
  for route in routes {
    lines.push(
      "route=\{route.name} method=\{route.http_method} path=\{route.path} auth=\{route.auth_required}",
    )
  }
  lines.join("\n")
}

///|
fn render_miniapp_snapshot(user_id : String) -> String {
  match miniapp_cli_logged_in_state(user_id) {
    Some((state, session_id)) =>
      @miniapp_local_backend.miniapp_local_backend_snapshot(
        state,
        session_id,
        now_ms=7100UL,
      ).body
    None => "kind=snapshot ok=false reason=login-failed"
  }
}

///|
fn render_miniapp_search(user_id : String, query : String) -> String {
  match miniapp_cli_logged_in_state(user_id) {
    Some((state, session_id)) =>
      @miniapp_local_backend.miniapp_local_backend_search_buildings(
        state,
        session_id,
        query,
        now_ms=7200UL,
      ).body
    None => "kind=search-buildings ok=false reason=login-failed"
  }
}

///|
fn render_miniapp_create_building(user_id : String) -> String {
  match miniapp_cli_logged_in_state(user_id) {
    Some((state, session_id)) =>
      @miniapp_local_backend.miniapp_local_backend_create_building(
        state,
        session_id,
        {
          id: "cli-agent-lab",
          kind: @miniapp_contracts.AgentLab,
          title: "CLI Agent Lab",
          summary: "Local backend draft building created from CLI.",
          workspace_id: "workspace-\{user_id}",
          tags: ["agent", "local"],
          capabilities: ["query", "create-agent"],
          primary_book_id: "book-cli-agent-lab",
        },
        now_ms=7300UL,
      ).body
    None => "kind=create-building ok=false reason=login-failed"
  }
}

///|
fn render_miniapp_place_building(user_id : String) -> String {
  match miniapp_cli_logged_in_state(user_id) {
    Some((state, session_id)) =>
      @miniapp_local_backend.miniapp_local_backend_place_building(
        state,
        session_id,
        {
          id: "placement-cli-policy-hall",
          building_id: "policy-hall",
          layer_id: "layer-personal-\{user_id}",
          x: 12,
          y: 18,
          region_id: "cli",
          pinned: true,
        },
        now_ms=7400UL,
      ).body
    None => "kind=place-building ok=false reason=login-failed"
  }
}

///|
fn render_miniapp_share_building(user_id : String) -> String {
  match miniapp_cli_logged_in_state(user_id) {
    Some((state, session_id)) => {
      let created = @miniapp_local_backend.miniapp_local_backend_create_building(
        state,
        session_id,
        {
          id: "cli-shared-lab",
          kind: @miniapp_contracts.AgentLab,
          title: "CLI Shared Lab",
          summary: "Local backend building shared from CLI.",
          workspace_id: "workspace-\{user_id}",
          tags: ["agent", "shared", "local"],
          capabilities: ["query", "create-agent"],
          primary_book_id: "book-cli-shared-lab",
        },
        now_ms=7440UL,
      )
      if created.ok {
        @miniapp_local_backend.miniapp_local_backend_share_building(
          created.state,
          session_id,
          "cli-shared-lab",
          "user-b",
          now_ms=7445UL,
        ).body
      } else {
        created.body
      }
    }
    None => "kind=share-building ok=false reason=login-failed"
  }
}

///|
fn render_miniapp_publish_building(user_id : String) -> String {
  match miniapp_cli_logged_in_state(user_id) {
    Some((state, session_id)) => {
      let created = @miniapp_local_backend.miniapp_local_backend_create_building(
        state,
        session_id,
        {
          id: "cli-published-lab",
          kind: @miniapp_contracts.AgentLab,
          title: "CLI Published Lab",
          summary: "Local backend building published from CLI.",
          workspace_id: "workspace-\{user_id}",
          tags: ["agent", "published", "local"],
          capabilities: ["query", "create-agent"],
          primary_book_id: "book-cli-published-lab",
        },
        now_ms=7450UL,
      )
      if created.ok {
        @miniapp_local_backend.miniapp_local_backend_publish_building(
          created.state,
          session_id,
          "cli-published-lab",
          now_ms=7460UL,
        ).body
      } else {
        created.body
      }
    }
    None => "kind=publish-building ok=false reason=login-failed"
  }
}

///|
fn render_miniapp_archive_building(user_id : String) -> String {
  match miniapp_cli_logged_in_state(user_id) {
    Some((state, session_id)) => {
      let created = @miniapp_local_backend.miniapp_local_backend_create_building(
        state,
        session_id,
        {
          id: "cli-archived-lab",
          kind: @miniapp_contracts.AgentLab,
          title: "CLI Archived Lab",
          summary: "Local backend building archived from CLI.",
          workspace_id: "workspace-\{user_id}",
          tags: ["agent", "archived", "local"],
          capabilities: ["query", "create-agent"],
          primary_book_id: "book-cli-archived-lab",
        },
        now_ms=7465UL,
      )
      if created.ok {
        @miniapp_local_backend.miniapp_local_backend_archive_building(
          created.state,
          session_id,
          "cli-archived-lab",
          now_ms=7470UL,
        ).body
      } else {
        created.body
      }
    }
    None => "kind=archive-building ok=false reason=login-failed"
  }
}

///|
fn render_miniapp_create_agent(user_id : String) -> String {
  match miniapp_cli_logged_in_state(user_id) {
    Some((state, session_id)) =>
      @miniapp_local_backend.miniapp_local_backend_create_agent(
        state,
        session_id,
        {
          id: "agent-cli",
          display_name: "CLI Agent",
          owner_kind: @miniapp_contracts.UserOwner,
          owner_id: user_id,
          building_id: Some("private-lab"),
          capabilities: ["answer"],
        },
        now_ms=7500UL,
      ).body
    None => "kind=create-agent ok=false reason=login-failed"
  }
}

///|
fn render_miniapp_chat_send(user_id : String) -> String {
  match miniapp_cli_logged_in_state(user_id) {
    Some((state, session_id)) =>
      @miniapp_local_backend.miniapp_local_backend_chat_send(
        state,
        session_id,
        {
          message_id: "msg-cli-chat",
          run_id: "run-cli-chat",
          thread_id: "thread-private-lab",
          building_id: "private-lab",
          agent_id: None,
          body: "Ask from CLI.",
          answer_summary: "CLI answer waiting for review.",
        },
        now_ms=7600UL,
      ).body
    None => "kind=chat-send ok=false reason=login-failed"
  }
}

///|
fn render_miniapp_run_action(
  user_id : String,
  run_id : String,
  action : String,
) -> String {
  match miniapp_cli_logged_in_state(user_id) {
    Some((state, session_id)) => {
      let draft : @miniapp_agents.MiniappRunActionDraft = {
        run_id,
        summary: "CLI \{action} for \{run_id}.",
      }
      if action == "cancel" {
        @miniapp_local_backend.miniapp_local_backend_cancel_run(
          state,
          session_id,
          draft,
          now_ms=7700UL,
        ).body
      } else if action == "retry" {
        @miniapp_local_backend.miniapp_local_backend_retry_run(
          state,
          session_id,
          draft,
          now_ms=7800UL,
        ).body
      } else {
        @miniapp_local_backend.miniapp_local_backend_accept_run(
          state,
          session_id,
          draft,
          now_ms=7900UL,
        ).body
      }
    }
    None => "kind=\{action}-run ok=false reason=login-failed"
  }
}

///|
fn miniapp_cli_logged_in_state(
  user_id : String,
) -> (@miniapp_local_backend.MiniappLocalBackendState, String)? {
  let login = @miniapp_local_backend.miniapp_local_backend_dev_login(
    @miniapp_local_backend.miniapp_local_backend_fixture_state(),
    user_id,
    now_ms=7000UL,
  )
  match login.session_id {
    Some(session_id) => Some((login.state, session_id))
    None => None
  }
}
