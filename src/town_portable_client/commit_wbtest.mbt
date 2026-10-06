///|
async test "precommit stage failures clean only files owned by this download" {
  with_temp(root => {
    let view = fixture_view()
    for
      stage in [
        "package_synced", "binding_synced", "receipt_synced", "binding_exposed",
        "receipt_exposed",
      ] {
      try
        receive_download_impl(
          view,
          fixture_response(view),
          observed_reader(fixture_bytes),
          root + "/file",
          fixture_limits(),
          current => {
            if current == stage {
              raise ClientError("synthetic_stage_failure")
            }
          },
        )
      catch {
        ClientError("synthetic_stage_failure") => ()
      } noraise {
        _ => fail("expected stage failure")
      }
      assert_eq(@fs.readdir(root).length(), 0)
    }
  })
}

///|
async test "racing destinations at sidecar and package commit stay unchanged" {
  with_temp(root => {
    let view = fixture_view()
    for suffix in ["", ".binding.json", ".receipt.json"] {
      let output = root + "/file"
      try
        receive_download_impl(
          view,
          fixture_response(view),
          observed_reader(fixture_bytes),
          output,
          fixture_limits(),
          current => {
            if current == "receipt_synced" {
              @fs.write_file(
                output + suffix,
                "racing-existing",
                create_mode=CreateNew,
              )
            }
          },
        )
      catch {
        ClientError("download_failed") => ()
      } noraise {
        _ => fail("expected rename conflict")
      }
      assert_eq(@fs.read_file(output + suffix).text(), "racing-existing")
      assert_eq(@fs.readdir(root).length(), 1)
      @fs.remove(output + suffix)
    }
  })
}

///|
async test "cancellation before commit removes partials but cancellation after commit keeps verified output" {
  with_temp(root => {
    let view = fixture_view()
    for stage in ["package_synced", "committed"] {
      let output = root + "/" + stage
      let cancel : Ref[() -> Unit] = Ref(() => ())
      let reached = Ref(false)
      @async.with_task_group(group => {
        let task = group.spawn(
          () => {
            receive_download_impl(
              view,
              fixture_response(view),
              observed_reader(fixture_bytes),
              output,
              fixture_limits(),
              current => {
                if current == stage {
                  reached.val = true
                  (cancel.val)()
                  @async.pause()
                }
              },
            )
          },
          allow_failure=true,
        )
        cancel.val = () => task.cancel()
        try task.wait() catch {
          _ => ()
        } noraise {
          _ => ()
        }
      })
      assert_true(reached.val)
      if stage == "committed" {
        assert_eq(@fs.read_file(output).binary(), fixture_bytes)
        let binding : @marketplace.PortableListingBinding = @json.from_json(
          @fs.read_file(output + ".binding.json").json(),
        )
        assert_eq(binding, view.binding)
        assert_true(@fs.exists(output + ".receipt.json"))
        assert_eq(@fs.readdir(root).length(), 3)
      } else {
        assert_eq(@fs.readdir(root).length(), 0)
      }
    }
  })
}
