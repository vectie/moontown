///|
let usage : String =
  #|portable_transfer --base-url ORIGIN --session-stdin COMMAND [ARGS]
  #|  upload FILE LISTING_ID BINDING_JSON
  #|  list
  #|  preview-share PACKAGE_ID BINDING_JSON RECIPIENT_ID GRANT_ID EXPIRES_AT_MS
  #|  share PACKAGE_ID BINDING_JSON RECIPIENT_ID GRANT_ID EXPIRES_AT_MS
  #|  revoke GRANT_ID
  #|  download PACKAGE_ID BINDING_JSON NEW_OUTPUT_FILE
  #|  withdraw PACKAGE_ID BINDING_JSON
  #|Read the existing Town session from stdin through EOF. Never pass it in argv.
  #|Download creates NEW_OUTPUT_FILE.binding.json and .receipt.json as well.
  #|Preview discloses the entire package, including learning and identity files.
  #|Sharing grants the entire exact package to the named same-tenant recipient.
  #|No command imports, installs or executes a Book or any output.

///|
struct Command {
  base_url : String
  name : String
  args : Array[String]
} derive(Debug, Eq)

///|
fn parse_args(args : Array[String]) -> Command raise {
  guard args.length() >= 4 &&
    args[0] == "--base-url" &&
    args[2] == "--session-stdin" else {
    raise @client.ClientError("usage_error")
  }
  let name = args[3]
  let count = match name {
    "upload" | "download" => 3
    "list" => 0
    "preview-share" | "share" => 5
    "revoke" => 1
    "withdraw" => 2
    _ => raise @client.ClientError("unknown_command")
  }
  if args.length() != count + 4 ||
    args.any(value => {
      value.has_prefix("--session=") ||
      value == "--session" ||
      value == "--token"
    }) {
    raise @client.ClientError("usage_error")
  }
  { base_url: args[1], name, args: args[4:].to_owned(), }
}

///|
fn expiry_arg(value : String) -> UInt64 raise {
  if value.is_empty() || value.iter().any(c => c < '0' || c > '9') {
    raise @client.ClientError("invalid_expiry")
  }
  @string.parse_uint64(value) catch {
    _ => raise @client.ClientError("invalid_expiry")
  }
}
