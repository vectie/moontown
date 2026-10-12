///|
async test "source picker lists registered IDs nested unicode binary and captures current bytes only at save" {
  let (store, root) = fixture()
  let catalog_before = @fs.read_file(root + "/catalog.json").binary()
  let water = root + "/books/water"
  @fs.write_file(
    water + "/raw/研究.txt",
    "unicode source",
    create_mode=CreateNew,
  )
  let listing = store.list_sources("water")
  assert_eq(listing.book_id, "water")
  assert_eq(listing.paths.length(), 2)
  assert_true(listing.paths.contains("raw/nested/source.bin"))
  assert_true(listing.paths.contains("raw/研究.txt"))
  assert_false(listing.truncated)
  assert_false(@fs.exists(root + "/state"))
  assert_eq(store.list_sources("mobility").paths, ["raw/nested/source.bin"])
  let bytes = b"changed after observation\x00\xff"
  @fs.write_file(water + "/raw/nested/source.bin", bytes)
  let draft = fixture_draft()
  let participants : Array[@contract.Participant] = []
  for p in draft.participants {
    participants.push({
      ..p,
      source_paths: store.list_sources(p.book_id).paths.filter(path => {
        path == "raw/nested/source.bin"
      }),
    })
  }
  let draft = { ..draft, participants, }
  let request : Request = {
    contract_version: "moontown.collaboration.request.v1",
    request_id: "save-picker",
    action: "save",
    draft_id: draft.draft_id,
    revision: "",
    new_draft_id: "",
    artifact_path: "",
    draft: Some(draft),
    payload: None,
  }
  let saved_reply = store.request(
    decode_request(request.to_json().stringify()),
    "2026-10-08T00:00:00Z",
  )
  assert_true(saved_reply.ok)
  let saved = saved_reply.saved.unwrap()
  let reopened_reply = store.request(
    { ..request, action: "load", revision: saved.revision, draft: None, },
    "now",
  )
  assert_eq(reopened_reply.saved, Some(saved))
  assert_eq(saved.sources[0].digest, digest(bytes))
  assert_eq(store.load(draft.draft_id, revision=saved.revision), saved)
  let captured = read_bytes(
    store.root +
    "/drafts/" +
    draft.draft_id +
    "/revisions/" +
    saved.revision +
    "/sources/water/raw/nested/source.bin",
    1048576,
  )
  assert_eq(captured, bytes)
  let unicode_draft = {
    ..@contract.empty_draft("unicode-picked"),
    participants: [
      { ..draft.participants[0], source_paths: ["raw/研究.txt"], },
    ],
  }
  let unicode_saved = store.save(unicode_draft, "", "now")
  assert_eq(unicode_saved.sources[0].source_path, "raw/研究.txt")
  assert_eq(unicode_saved.sources[0].digest, digest(b"unicode source"))
  assert_eq(store.load("unicode-picked"), unicode_saved)
  assert_eq(@fs.read_file(water + "/raw/nested/source.bin").binary(), bytes)
  assert_eq(
    @fs.read_file(root + "/books/mobility/raw/nested/source.bin").binary(),
    b"exact\x00source\xff\n",
  )
  assert_eq(@fs.read_file(root + "/catalog.json").binary(), catalog_before)
  @fs.remove(water + "/raw/nested/source.bin")
  assert_eq(store.load(draft.draft_id, revision=saved.revision), saved)
  try store.save(draft, saved.revision, "later") catch {
    _ => ()
  } noraise {
    _ => fail("disappeared source saved")
  }
  if @env.get_env_var("MOONTOWN_PICKER_EVIDENCE") is Some(path) {
    let evidence : Json = {
      "root": root,
      "listing": listing.to_json(),
      "saved": saved.to_json(),
      "captured_digest": digest(captured),
    }
    @fs.write_file(
      path,
      evidence.stringify(indent=2),
      create_mode=CreateOrTruncate,
    )
  } else {
    @fs.rmdir(root, recursive=true)
  }
}

///|
async test "source picker rejects hidden symlink oversized nonregular and root drift with save revalidation" {
  let (store, root) = fixture()
  let water = root + "/books/water"
  @fs.write_file(water + "/.secret", "hidden", create_mode=CreateNew)
  @fs.mkdir(water + "/.private")
  @fs.write_file(water + "/.private/data", "hidden", create_mode=CreateNew)
  @fs.symlink(target=water + "/raw/nested/source.bin", water + "/link")
  @fs.symlink(target=water + "/raw", water + "/linked-dir")
  @fs.write_file(
    water + "/large",
    Bytes::make(1048577, b'x'),
    create_mode=CreateNew,
  )
  let listing = store.list_sources("water")
  assert_eq(listing.paths, ["raw/nested/source.bin"])
  assert_eq(listing.excluded_entries, 5)
  for id in ["../water", "/tmp", "unknown"] {
    try store.list_sources(id) catch {
      _ => ()
    } noraise {
      _ => fail("unregistered source root accepted")
    }
  }
  @fs.rename(water + "/raw", water + "/old-raw")
  @fs.symlink(target=water + "/old-raw", water + "/raw")
  try store.save(fixture_draft(), "", "now") catch {
    _ => ()
  } noraise {
    _ => fail("changed parent symlink saved")
  }
  @fs.rename(water, root + "/moved-water")
  @fs.symlink(target=root + "/moved-water", water)
  try store.list_sources("water") catch {
    _ => ()
  } noraise {
    _ => fail("symlink root listed")
  }
  try store.save(fixture_draft(), "", "now") catch {
    _ => ()
  } noraise {
    _ => fail("symlink root saved")
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "source picker explains unreadable directories and bounded depth and entry scans" {
  let (store, root) = fixture()
  let water = root + "/books/water"
  @fs.mkdir(water + "/unreadable")
  @fs.write_file(
    water + "/unreadable/private.txt",
    "not readable",
    create_mode=CreateNew,
  )
  @fs.chmod(water + "/unreadable", 0)
  let unreadable = store.list_sources("water")
  @fs.chmod(water + "/unreadable", 0o700)
  assert_eq(unreadable.unreadable_entries, 1)
  assert_true(unreadable.detail.contains("Listing incomplete"))
  let mut nested = water
  for _ in 0..<9 {
    nested += "/deep"
    @fs.mkdir(nested)
  }
  @fs.write_file(nested + "/beyond.txt", "outside depth", create_mode=CreateNew)
  let depth = store.list_sources("water")
  assert_true(depth.truncated)
  assert_false(depth.paths.any(path => path.contains("beyond.txt")))
  for n in 0..<2050 {
    @fs.write_file(
      water + "/.hidden-" + n.to_string(),
      "x",
      create_mode=CreateNew,
    )
  }
  let bounded = store.list_sources("water")
  assert_eq(bounded.scanned_entries, 2048)
  assert_true(bounded.truncated)
  @fs.rmdir(root, recursive=true)
}

///|
async test "source picker bounds observations and preserves incomplete draft save" {
  let (store, root) = fixture()
  for n in 0..<270 {
    @fs.write_file(
      root + "/books/water/file-" + n.to_string(),
      "x",
      create_mode=CreateNew,
    )
  }
  let listing = store.list_sources("water")
  assert_eq(listing.paths.length(), 256)
  assert_true(listing.truncated)
  assert_true(listing.detail.contains("truncated"))
  assert_true(listing.scanned_entries <= 2048)
  let incomplete = store.save(@contract.empty_draft("incomplete"), "", "now")
  assert_true(incomplete.sources.is_empty())
  assert_eq(store.load("incomplete"), incomplete)
  @fs.rmdir(root, recursive=true)
}

///|
async test "source picker request uses payload Book ID only and duplicate titles remain distinct" {
  let (store, root) = fixture()
  let entries = @moonbook.load_catalog_file(store.catalog_path).unwrap()
  @fs.write_file(
    store.catalog_path,
    entries
    .map(book => {
      @moonbook.BookCatalogEntry::new(
        id=book.id,
        name="Same Book",
        purpose="fixture",
        workspace_root=book.workspace_root,
      )
    })
    .to_json()
    .stringify(),
  )
  for id in ["water", "mobility"] {
    let raw : Json = {
      "contract_version": "moontown.collaboration.request.v1",
      "request_id": "picker",
      "action": "source-list",
      "draft_id": "/untrusted/root",
      "revision": "",
      "new_draft_id": "",
      "artifact_path": "/untrusted/root",
      "draft": Json::null(),
      "payload": { "book_id": id, "root": "/untrusted/root" },
    }
    let reply = store.request(decode_request(raw.stringify()), "now")
    assert_true(reply.ok)
    assert_eq(reply.source_listing.unwrap().book_id, id)
    assert_false(reply.to_json().stringify().contains(root))
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "source picker observation cannot bypass capture count and total byte limits" {
  let (store, root) = fixture()
  let water = root + "/books/water"
  for i in 0..<17 {
    @fs.write_file(water + "/file-" + i.to_string(), "x", create_mode=CreateNew)
  }
  let listed = store.list_sources("water")
  let participant = fixture_draft().participants[0]
  let too_many = {
    ..fixture_draft(),
    participants: [
      {
        ..participant,
        source_paths: listed.paths.filter(path => path.has_prefix("file-")),
      },
    ],
  }
  try store.save(too_many, "", "now") catch {
    error => assert_true(error_message(error).contains("at most 16"))
  } noraise {
    _ => fail("source count limit bypassed")
  }
  let paths = Array::makei(9, i => "large-" + i.to_string())
  for path in paths {
    @fs.write_file(
      water + "/" + path,
      Bytes::make(1048576, b'x'),
      create_mode=CreateNew,
    )
  }
  assert_true(store.list_sources("water").paths.contains("large-8"))
  let too_large = {
    ..fixture_draft(),
    participants: [{ ..participant, source_paths: paths, }],
  }
  try store.save(too_large, "", "now") catch {
    error => assert_true(error_message(error).contains("8 MiB"))
  } noraise {
    _ => fail("total capture byte limit bypassed")
  }
  assert_false(@fs.exists(root + "/state/drafts/river-question/current"))
  @fs.rmdir(root, recursive=true)
}
