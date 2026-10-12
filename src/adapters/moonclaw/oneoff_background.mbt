///|
/// A single orphan process, never a daemon or recurring schedule. Duplicate
/// processes reconcile under the producer's durable per-packet execution lock.
pub async fn launch_oneoff(
  packet_path : String,
  moonclaw_root~ : String,
  home~ : String,
  cwd~ : String,
  log_prefix~ : String,
  store_home~ : String,
) -> Int {
  let (command, args) = moonclaw_runtime_invocation(moonclaw_root, [
    "proposal", "oneoff", packet_path, "--json", "--home", home, "--cwd", cwd, "--store-home",
    store_home,
  ])
  let stdout = @process.redirect_to_file(
    log_prefix + ".stdout",
    append=true,
    create_mode=OpenOrCreate,
    permission=0o600,
  )
  let stderr = @process.redirect_to_file(
    log_prefix + ".stderr",
    append=true,
    create_mode=OpenOrCreate,
    permission=0o600,
  )
  @process.spawn_orphan(command, args, stdout~, stderr~)
}
