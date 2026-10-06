///|
test "all exact commands require session stdin and fixed arguments" {
  for
    pair in [
      ("list", []),
      ("upload", ["file", "listing", "binding"]),
      ("download", ["pkg", "binding", "new-file"]),
      ("preview-share", ["pkg", "binding", "recipient", "grant", "123"]),
      ("share", ["pkg", "binding", "recipient", "grant", "123"]),
      ("revoke", ["grant"]),
      ("withdraw", ["pkg", "binding"]),
    ] {
    let args = ["--base-url", "https://town.example", "--session-stdin", pair.0]
    args.append(pair.1)
    let command = parse_args(args)
    assert_eq(command.name, pair.0)
    assert_eq(command.args, pair.1)
  }
  for
    args in [
      ["--base-url", "https://town.example", "list"],
      ["--base-url", "https://town.example", "--session", "secret", "list"],
      ["--base-url", "https://town.example", "--session-stdin", "list", "extra"],
      ["--base-url", "https://town.example", "--session-stdin", "install"],
    ] {
    try parse_args(args) catch {
      _ => ()
    } noraise {
      _ => fail("expected rejection")
    }
  }
}

///|
test "expiry is exact decimal uint64" {
  assert_eq(expiry_arg("123"), 123UL)
  for value in ["", "-1", "+1", "1.2", " 123", "18446744073709551616"] {
    try expiry_arg(value) catch {
      _ => ()
    } noraise {
      _ => fail("expected rejection")
    }
  }
}
