///|
pub(all) struct OneoffReceipt {
  packet_id : String
  proposal_id : String
  run_id : String
  status : String
  workspace_dir : String?
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Explicit opt-in start, using the producer's durable idempotency boundary.
/// This never installs a civic scenario, a daemon, or a Book provider task.
pub async fn start_oneoff(
  packet_path : String,
  moonclaw_root~ : String,
  home~ : String,
  cwd~ : String,
  store_home~ : String,
) -> OneoffReceipt {
  let (command, args) = moonclaw_runtime_invocation(moonclaw_root, [
    "proposal", "oneoff", packet_path, "--json", "--home", home, "--cwd", cwd, "--store-home",
    store_home,
  ])
  @json.from_json(@integration.run_json(command, args))
}
