///|
async fn execute(command : Command, client : @client.PortableClient) -> Json {
  let args = command.args
  match command.name {
    "list" => { "packages": client.list().to_json() }
    "upload" =>
      client
      .upload(args[0], args[1], @client.read_binding_file(args[2]))
      .to_json()
    "download" =>
      client
      .download(args[0], @client.read_binding_file(args[1]), args[2])
      .to_json()
    "withdraw" =>
      client.withdraw(args[0], @client.read_binding_file(args[1])).to_json()
    "revoke" => client.revoke(args[0]).to_json()
    "preview-share" | "share" => {
      let binding = @client.read_binding_file(args[1])
      if args[0] != @transfer.package_id(binding.binding_digest) {
        raise @client.ClientError("package_identity_mismatch")
      }
      let draft : @transfer.GrantDraft = {
        package_id: args[0],
        binding_digest: binding.binding_digest,
        grantee_principal_id: args[2],
        grant_id: args[3],
        expires_at_ms: expiry_arg(args[4]),
      }
      if command.name == "preview-share" {
        client.preview_share(draft)
      } else {
        client.share(draft).to_json()
      }
    }
    _ => raise @client.ClientError("unknown_command")
  }
}

///|
async fn main {
  let args = @env.args()[1:].to_owned()
  if args == ["--help"] || args.is_empty() {
    @stdio.stdout.write(usage + "\n")
    return
  }
  try {
    let command = parse_args(args)
    // Validate the origin before reading a session. Merely constructing this
    // exchange never opens a socket; only an explicit command uses it.
    let exchange = @client.native_exchange(command.base_url)
    let session = @client.read_session(@stdio.stdin)
    let client = @client.PortableClient::new(() => session, exchange)
    let result = execute(command, client)
    @stdio.stdout.write(result.stringify(indent=2) + "\n")
  } catch {
    @client.ClientError(reason) => {
      @stdio.stderr.write("portable_transfer: " + reason + "\n")
      // Stable failure only; neither argv nor caught filesystem/transport errors
      // are printed. Raising makes unsuccessful commands exit nonzero.
      raise @client.ClientError("command_failed")
    }
    _ => {
      @stdio.stderr.write("portable_transfer: command_failed\n")
      raise @client.ClientError("command_failed")
    }
  }
}
