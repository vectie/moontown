///|
pub fn pack_version() -> String {
  "0.1.0"
}

///|
pub fn adapter_id() -> String {
  "moontown-civic-synthesis-v1"
}

///|
pub fn operation_id() -> String {
  "civic.communication.synthesize"
}

///|
pub fn operation_ref() -> String {
  "moontown/\{operation_id()}@\{pack_version()}"
}

///|
pub fn input_schema_ref() -> String {
  "moontown/civic-communication-handoff@1.0.0"
}

///|
pub fn output_schema_ref() -> String {
  "moontown/civic-synthesis-result@1.0.0"
}

///|
pub fn capability_json(healthy? : Bool = false) -> Json {
  {
    "adapter_id": adapter_id(),
    "product_id": "moontown",
    "protocol": "moonflow.adapter.v2",
    "operations": [operation_ref()],
    "authority_classes": ["workspace-mutation"],
    "input_contracts": [input_schema_ref()],
    "output_contracts": [output_schema_ref()],
    "claim_ceiling": "execution-result",
    "healthy": healthy,
    "supports_cancel": false,
    "supports_reconcile": true,
  }
}

///|
struct FlowRequest {
  request_id : String
  run_id : String
  work_item_id : String
  attempt_id : String
  idempotency_key : String
  product_id : String
  operation : String
  requested_authority : String
  input_contracts : Array[String]
  output_contracts : Array[String]
  required_claim : String
  input_digest : String
  input_artifacts : Array[String]
  timeout_ms : Int
  created_at : String
} derive(Debug, Eq)

///|
fn json_object(value : Json, label : String) -> Map[String, Json] raise {
  match value {
    Object(fields) => fields
    _ => fail("MoonTown Flow adapter requires \{label} to be an object")
  }
}

///|
fn json_string_field(fields : Map[String, Json], name : String) -> String raise {
  match fields.get(name) {
    Some(String(value)) if !value.trim().is_empty() => value
    _ => fail("MoonTown Flow adapter requires \{name}")
  }
}

///|
fn json_int_field(fields : Map[String, Json], name : String) -> Int raise {
  match fields.get(name) {
    Some(Number(value, ..)) => value.to_int()
    _ => fail("MoonTown Flow adapter requires integer \{name}")
  }
}

///|
fn json_strings_field(
  fields : Map[String, Json],
  name : String,
) -> Array[String] raise {
  guard fields.get(name) is Some(Array(values)) else {
    fail("MoonTown Flow adapter requires array \{name}")
  }
  values.map(value => {
    match value {
      String(text) if !text.trim().is_empty() => text
      _ => fail("MoonTown Flow adapter requires non-empty strings in \{name}")
    }
  })
}

///|
fn safe_path_segment(value : String) -> Bool {
  if value.trim().is_empty() {
    return false
  }
  for ch in value {
    if !((ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '-' ||
      ch == '_' ||
      ch == '.') {
      return false
    }
  }
  value != "." && value != ".."
}

///|
fn decode_flow_request(value : Json) -> FlowRequest raise {
  let fields = json_object(value, "request")
  let request = {
    request_id: json_string_field(fields, "request_id"),
    run_id: json_string_field(fields, "run_id"),
    work_item_id: json_string_field(fields, "work_item_id"),
    attempt_id: json_string_field(fields, "attempt_id"),
    idempotency_key: json_string_field(fields, "idempotency_key"),
    product_id: json_string_field(fields, "product_id"),
    operation: json_string_field(fields, "operation"),
    requested_authority: json_string_field(fields, "requested_authority"),
    input_contracts: json_strings_field(fields, "input_contracts"),
    output_contracts: json_strings_field(fields, "output_contracts"),
    required_claim: json_string_field(fields, "required_claim"),
    input_digest: json_string_field(fields, "input_digest"),
    input_artifacts: json_strings_field(fields, "input_artifacts"),
    timeout_ms: json_int_field(fields, "timeout_ms"),
    created_at: json_string_field(fields, "created_at"),
  }
  validate_flow_request(request)
  request
}

///|
fn validate_flow_request(request : FlowRequest) -> Unit raise {
  if request.product_id != "moontown" || request.operation != operation_ref() {
    fail(
      "MoonTown Flow adapter owns only the versioned operation `\{operation_ref()}`",
    )
  }
  if request.requested_authority != "workspace-mutation" {
    fail("MoonTown civic synthesis requires workspace-mutation authority")
  }
  if request.required_claim != "execution-result" {
    fail("MoonTown civic synthesis claim ceiling is execution-result")
  }
  if request.input_contracts != [input_schema_ref()] ||
    request.output_contracts != [output_schema_ref()] {
    fail("MoonTown Flow request schema identities do not match the pack")
  }
  if !safe_path_segment(request.run_id) ||
    !safe_path_segment(request.work_item_id) ||
    !safe_path_segment(request.attempt_id) {
    fail(
      "MoonTown Flow run, work item and attempt ids must be safe path segments",
    )
  }
  if !request.input_digest.has_prefix("sha256:") ||
    request.input_digest.length() != 71 {
    fail("MoonTown Flow input_digest must be sha256")
  }
  if request.input_artifacts.is_empty() || request.timeout_ms <= 0 {
    fail(
      "MoonTown Flow request requires input artifacts and a positive timeout",
    )
  }
}

///|
fn adapter_run_base(request : FlowRequest) -> String {
  ".moonsuite/products/moontown/runs/\{request.run_id}/\{request.work_item_id}/\{request.attempt_id}"
}

///|
fn native_receipt_ref(request : FlowRequest) -> String {
  "\{adapter_run_base(request)}/native-execution-receipt.json"
}

///|
fn synthesis_result_ref(request : FlowRequest) -> String {
  "\{adapter_run_base(request)}/civic-synthesis-result.json"
}
