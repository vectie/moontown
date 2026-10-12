///|
/// Host-owned runtime configuration; never accepted from a browser request.
pub(all) struct OneoffRuntime {
  moonclaw_root : String
  home : String
  profile : String
  profile_config_path : String?
} derive(Debug, Eq, ToJson, FromJson)

///|
struct WorkInput {
  book_id : String
  packet_id : String
  proposal_id : String
  run_id : String
  workspace : String
  packet_path : String
  packet_digest : String
  inputs : Array[@contract.Artifact]
} derive(Debug, Eq, ToJson, FromJson)

///|
struct WorkIntent {
  contract_version : String
  draft_id : String
  revision : String
  source_digest : String
  runtime : OneoffRuntime
  store_home : String
  participants : Array[WorkInput]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn Store::work_root(self : Store, saved : @contract.SavedDraft) -> String raise {
  self.draft_root(saved.draft.draft_id) +
  "/" +
  revision_prefix(saved) +
  "oneoff"
}

///|
fn text_bytes(bytes : Bytes) -> String raise {
  let text = @utf8.decode(bytes)
  guard @utf8.encode(text) == bytes else {
    raise CollaborationError(
      "Produced evidence is not exact UTF-8 text; retain the run and inspect it in Claw",
    )
  }
  text
}

///|
async fn Store::work_intent(
  self : Store,
  saved : @contract.SavedDraft,
) -> WorkIntent {
  let root = self.work_root(saved)
  let json = @json.parse(text_bytes(read_bytes(root + "/intent.json", 2097152)))
  let intent : WorkIntent = @json.from_json(json)
  guard intent.to_json() == json &&
    intent.contract_version == "moontown.oneoff-intent.v1" &&
    intent.draft_id == saved.draft.draft_id &&
    intent.revision == saved.revision &&
    intent.store_home == root + "/runtime" &&
    intent.source_digest == digest(source_packet(saved)) &&
    intent.participants.length() == saved.draft.participants.length() else {
    raise CollaborationError(
      "One-off intent does not match the captured collaboration",
    )
  }
  for p in intent.participants {
    guard saved.draft.participants.any(selected => selected.book_id == p.book_id) &&
      p.workspace == root + "/workspaces/" + p.book_id &&
      p.packet_path == root + "/packets/" + p.book_id + ".json" &&
      p.proposal_id == "oneoff-" + p.packet_id &&
      p.run_id == "run-oneoff-" + p.packet_id &&
      digest(read_bytes(p.packet_path, 2097152)) == p.packet_digest else {
      raise CollaborationError("One-off packet identity changed")
    }
    for input in p.inputs {
      guard @contract.safe_source_path(input.path) else {
        raise CollaborationError("Unsafe frozen input")
      }
      let path = p.workspace + "/" + input.path
      directory(path[:path.rev_find("/").unwrap()].to_owned(), false)
      let bytes = read_bytes(path, 1048576)
      guard digest(bytes) == input.digest && bytes.length() == input.size_bytes else {
        raise CollaborationError(
          "Frozen participant input changed; original work has not been replaced",
        )
      }
    }
  }
  intent
}

///|
async fn Store::create_work_intent(
  self : Store,
  saved : @contract.SavedDraft,
  runtime : OneoffRuntime,
) -> WorkIntent {
  guard runtime.home.has_prefix("/") &&
    !runtime.profile.trim().is_empty() &&
    !runtime.moonclaw_root.trim().is_empty() else {
    raise CollaborationError(
      "Configure an installed MoonClaw runtime, absolute home and a bounded one-off analysis profile",
    )
  }
  let root = self.work_root(saved)
  let inputs : Array[WorkInput] = []
  directory(runtime.home, false)
  let profile_path = runtime.profile_config_path.unwrap_or(
    runtime.home + "/moonclaw.jobs.json",
  )
  let profile_bytes = read_bytes(profile_path, 1048576) catch {
    _ =>
      raise CollaborationError(
        "Point profile_config_path to the existing moonclaw.jobs.json containing the selected runtime profile. Fix setup and retry this prepared question; no work was started",
      )
  }
  validate_initial_profile(profile_bytes, runtime.profile)
  for p in saved.draft.participants {
    let workspace = root + "/workspaces/" + p.book_id
    let artifacts : Array[@contract.Artifact] = []
    let supplied_sources : Array[Json] = []
    let files : Array[(String, Bytes)] = [
      ("input/brief.md", @utf8.encode(participant_brief(saved, p))),
      ("moonclaw.jobs.json", profile_bytes),
      (
        "skills/oneoff/SKILL.md",
        @utf8.encode(
          "# Captured-source one-off contribution\nUse only the captured input files. Cite their exact paths, distinguish observations from interpretation, preserve contradictions and missing evidence. Return one UTF-8 contribution. Do not schedule work, dispatch child agents, update Books or record human approval.\n",
        ),
      ),
    ]
    for source in saved.sources.filter(s => s.book_id == p.book_id) {
      let bytes = read_bytes(
        self.draft_root(saved.draft.draft_id) +
        "/" +
        revision_prefix(saved) +
        source.artifact_ref,
        1048576,
      )
      files.push(("input/" + source.artifact_ref, bytes))
      let text = @utf8.decode(bytes)
      supplied_sources.push({
        "source": source.to_json(),
        "encoding": if @utf8.encode(text) == bytes {
          "utf-8"
        } else {
          "hex"
        },
        "content": if @utf8.encode(text) == bytes {
          text
        } else {
          @crypto.bytes_to_hex_string(bytes)
        },
      })
    }
    for (path, bytes) in files {
      write_bytes(workspace + "/" + path, bytes)
      artifacts.push({
        path,
        digest: digest(bytes),
        size_bytes: bytes.length(),
      })
    }
    let key = "town-" +
      digest(@utf8.encode(saved.revision + "/" + p.book_id))[7:].to_owned()
    let bundle = @moonbook.oneoff_context(
      p.book_id,
      workspace,
      key,
      participant_brief(saved, p) +
      "\nWork once using the exact captured source payloads below. Return the contribution as UTF-8 text with source paths and uncertainties. Binary content is explicitly hex; report any interpretation limitations. Do not claim human approval. Any configured tools remain subject to the existing runtime role, workspace scope and execution authority.\n" +
      supplied_sources.to_json().stringify(indent=2),
      artifacts.filter(a => a.path.has_prefix("input/")).map(a => a.path),
    )
    let packet = @moonclaw.proposal_packet_from_bundle(
      bundle,
      saved.draft.title + " / " + p.book_id,
      "One-off captured-source contribution",
      runtime.profile,
      packet_id=Some(key),
    )
    let packet_path = root + "/packets/" + p.book_id + ".json"
    let packet_bytes = @utf8.encode(packet.to_json().stringify(indent=2))
    guard packet_bytes.length() <= 2097152 else {
      raise CollaborationError(
        "Exact participant input exceeds the bounded 2 MiB one-off request. Narrow the source selection; nothing was dispatched",
      )
    }
    write_bytes(packet_path, packet_bytes)
    inputs.push({
      book_id: p.book_id,
      packet_id: key,
      proposal_id: "oneoff-" + key,
      run_id: "run-oneoff-" + key,
      workspace,
      packet_path,
      packet_digest: digest(packet_bytes),
      inputs: artifacts,
    })
  }
  let intent : WorkIntent = {
    contract_version: "moontown.oneoff-intent.v1",
    draft_id: saved.draft.draft_id,
    revision: saved.revision,
    source_digest: digest(source_packet(saved)),
    runtime,
    store_home: root + "/runtime",
    participants: inputs,
  }
  write_bytes(
    root + "/intent.json",
    @utf8.encode(intent.to_json().stringify(indent=2)),
  )
  intent
}

///|
/// Validate the same bytes that will be frozen, before any participant packet,
/// runtime profile copy or launch intent exists. Mirrors the producer's
/// jobs.profiles object/id-or-family selection without imposing a new profile.
fn validate_initial_profile(bytes : Bytes, selected : String) -> Unit raise {
  let json = @json.parse(text_bytes(bytes)) catch {
    _ =>
      raise CollaborationError(
        "Runtime profile JSON is invalid. Fix setup and retry the same prepared question; no work was started",
      )
  }
  guard json is { "jobs": { "profiles": Object(profiles), .. }, .. } else {
    raise CollaborationError(
      "Runtime profile configuration needs jobs.profiles. Fix setup and retry the same prepared question; no work was started",
    )
  }
  let matches : Array[Json] = []
  for id, profile in profiles {
    if id == selected ||
      (profile is { "family": String(family), .. } && family == selected) {
      matches.push(profile)
    }
  }
  guard matches.length() == 1 && matches[0] is Object(profile) else {
    raise CollaborationError(
      "Selected runtime profile is missing, invalid or ambiguous. Fix setup and retry the same prepared question; no work was started",
    )
  }
  if profile.get("steps") is Some(steps) {
    guard steps is Array(steps) &&
      steps.all(step => {
        step
        is {
          "id": String(id),
          "title": String(title),
          "kind": String(kind),
          ..
        } &&
        !id.is_empty() &&
        !title.is_empty() &&
        !kind.is_empty()
      }) else {
      raise CollaborationError(
        "Selected runtime profile has malformed steps. Fix setup and retry the same prepared question; no work was started",
      )
    }
  }
}
