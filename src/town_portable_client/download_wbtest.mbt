///|
async test "receive exact binary stream atomically and unchanged v1 sidecars" {
  with_temp(root => {
    let view = fixture_view()
    let output = root + "/received.moonbook-agent"
    let reader = observed_reader(fixture_bytes, hidden_path=output)
    let result = receive_download(
      view,
      fixture_response(view),
      reader,
      output,
      limits=fixture_limits(),
    )
    assert_eq(@fs.read_file(result.package_path).binary(), fixture_bytes)
    let binding : @marketplace.PortableListingBinding = @json.from_json(
      @fs.read_file(result.binding_path).json(),
    )
    assert_eq(binding, view.binding)
    let receipt : @transfer.PackageByteReceipt = @json.from_json(
      @fs.read_file(result.receipt_path).json(),
    )
    assert_eq(Some(receipt), view.receipt)
    assert_eq(@fs.readdir(root).length(), 3)
    assert_true(reader.reads.val > 2)
  })
}

///|
async test "truncated overlong wrong digest interrupted and slow streams leave nothing" {
  with_temp(root => {
    let view = fixture_view()
    for variant in 0..<5 {
      let output = root + "/rejected-\{variant}"
      let reader = match variant {
        0 =>
          observed_reader(
            fixture_bytes[:fixture_bytes.length() - 1].to_owned(),
            hidden_path=output,
          )
        1 => observed_reader(fixture_bytes + b"!", hidden_path=output)
        2 => observed_reader(b"abcdefghijkl", hidden_path=output)
        3 => observed_reader(fixture_bytes, hidden_path=output, fail_after=4)
        _ => observed_reader(fixture_bytes, hidden_path=output, delay_ms=20)
      }
      let limits = {
        ..fixture_limits(),
        idle_timeout_ms: if variant == 4 {
          1
        } else {
          30000
        },
      }
      try
        receive_download(view, fixture_response(view), reader, output, limits~)
      catch {
        ClientError(_) => ()
        _ => fail("unexpected error")
      } noraise {
        _ => fail("expected rejected download")
      }
      assert_eq(@fs.readdir(root).length(), 0)
    }
  })
}

///|
async test "bad headers redirects partial response encoding and metadata are rejected before reading" {
  with_temp(root => {
    let view = fixture_view()
    for
      header in [
        ("content-length", "999999999999999999999999"),
        ("content-length", "12, 12"),
        ("content-length", "-1"),
        ("content-length", "0"),
        ("content-type", "text/plain"),
        ("content-encoding", "gzip"),
        ("transfer-encoding", "chunked"),
        ("x-town-package-id", "pkg-wrong"),
        ("x-town-binding-digest", hash_bytes(b"wrong")),
        ("x-town-package-sha256", hash_bytes(b"wrong")),
        ("content-range", "bytes 0-1/12"),
        ("cache-control", "public"),
        ("content-disposition", "attachment; filename=\"unsafe\r\nX: value\""),
      ] {
      let headers = fixture_headers(view)
      headers[header.0] = header.1
      let reader = observed_reader(fixture_bytes)
      try
        receive_download(
          view,
          { ..fixture_response(view), headers, },
          reader,
          root + "/file",
          limits=fixture_limits(),
        )
      catch {
        ClientError(_) => ()
        _ => fail("unexpected error")
      } noraise {
        _ => fail("expected header rejection")
      }
      assert_eq(reader.reads.val, 0)
    }
    for code in [206, 301, 302, 307, 308, 401, 403, 500] {
      let reader = observed_reader(fixture_bytes)
      try
        receive_download(
          view,
          { ..fixture_response(view), code, },
          reader,
          root + "/file",
          limits=fixture_limits(),
        )
      catch {
        ClientError(_) => ()
        _ => fail("unexpected error")
      } noraise {
        _ => fail("expected status rejection")
      }
      assert_eq(reader.reads.val, 0)
    }
    let receipt = view.receipt.unwrap()
    for
      bad in [
        { ..view, receipt: None, },
        {
          ..view,
          receipt: Some({ ..receipt, package_sha256: hash_bytes(b"wrong"), }),
        },
        { ..view, binding: { ..view.binding, listing_id: "other", }, },
        { ..view, package_id: "pkg-wrong", },
        { ..view, status: "withdrawn", },
      ] {
      let reader = observed_reader(fixture_bytes)
      try
        receive_download(
          bad,
          fixture_response(view),
          reader,
          root + "/file",
          limits=fixture_limits(),
        )
      catch {
        ClientError(_) => ()
        _ => fail("unexpected error")
      } noraise {
        _ => fail("expected metadata rejection")
      }
      assert_eq(reader.reads.val, 0)
    }
    assert_eq(@fs.readdir(root).length(), 0)
  })
}

///|
async test "existing package sidecar and dangling symlink are never overwritten" {
  with_temp(root => {
    let view = fixture_view()
    for suffix in ["", ".binding.json", ".receipt.json"] {
      let path = root + "/file"
      @fs.write_file(path + suffix, "keep", create_mode=CreateNew)
      let reader = observed_reader(fixture_bytes)
      try
        receive_download(
          view,
          fixture_response(view),
          reader,
          path,
          limits=fixture_limits(),
        )
      catch {
        ClientError("output_already_exists") => ()
        _ => fail("unexpected error")
      } noraise {
        _ => fail("expected no overwrite")
      }
      assert_eq(@fs.read_file(path + suffix).text(), "keep")
      assert_eq(reader.reads.val, 0)
      @fs.remove(path + suffix)
    }
    @fs.symlink(target=root + "/absent", root + "/file")
    try
      receive_download(
        view,
        fixture_response(view),
        observed_reader(fixture_bytes),
        root + "/file",
        limits=fixture_limits(),
      )
    catch {
      ClientError("output_already_exists") => ()
      _ => fail("unexpected error")
    } noraise {
      _ => fail("expected symlink rejection")
    }
    assert_eq(@fs.kind(root + "/file", follow_symlink=false), SymLink)
  })
}
