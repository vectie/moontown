///|
fn supervisor_worker_model_valid(model : String) -> Bool {
  model == "gpt-5.6-sol" ||
  (model.trim() == model && model.has_prefix("moongate/") && model.length() > 9)
}

///|
fn supervisor_activation_model(
  payload : SupervisorProfileActivationPayload,
) -> String {
  supervisor_activation_binding_string(payload, "model")
}

///|
fn supervisor_activation_binding_string(
  payload : SupervisorProfileActivationPayload,
  key : String,
) -> String {
  match payload.runtime_binding {
    Object(fields) => json_string(fields, key)
    _ => ""
  }
}

///| The authenticated Desk transport supplies the live MoonClaw route projection.

///|
/// Town remains the only writer and binds its exact choice before authorization.
fn resolve_supervisor_activation_model(
  payload : SupervisorProfileActivationPayload,
  route : Json,
) -> SupervisorProfileActivationPayload raise {
  guard payload.runtime_binding is Object(original) else {
    fail("activation runtime binding must be an object")
  }
  let model = json_string(original, "model")
  if model != "" {
    if !supervisor_worker_model_valid(model) {
      fail("persisted supervisor model selector is invalid")
    }
    return payload
  }
  guard route is Object(fields) &&
    json_string(fields, "contract") == "moonclaw.moongate-route.v1" else {
    fail(
      "model_route_required: start or configure MoonGate, then retry the saved activation",
    )
  }
  let requested = json_string(original, "requested_model")
  let selected = if requested == "" {
    if !(fields.get("ready") is Some(True)) {
      fail(
        "model_route_required: configure a live MoonGate default model, then retry the saved activation",
      )
    }
    json_string(fields, "default_model")
  } else {
    requested
  }
  let catalog_ready = fields
    .get("catalog_ready")
    .unwrap_or(fields.get("ready").unwrap_or(false.to_json()))
    is True
  if !catalog_ready ||
    !selected.has_prefix("moongate/") ||
    !supervisor_worker_model_valid(selected) ||
    !json_array(fields, "models").any(model => {
      match model {
        Object(item) => json_string(item, "name") == selected
        _ => false
      }
    }) {
    fail(
      "model_route_required: the exact selected MoonGate model is unavailable; restore that route and retry",
    )
  }
  let binding = original.copy()
  binding["model"] = selected.to_json()
  binding["model_resolution"] = (if requested == "" {
    "configured_default"
  } else {
    "explicit"
  }).to_json()
  { ..payload, runtime_binding: Json::object(binding), }
}
