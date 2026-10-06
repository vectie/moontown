///|
struct NativeEditorFixture {
  root : String
  source_root : String
  course_root : String
  book_root : String
  snapshot_path : String
  catalog_path : String
  criterion : PlanbookCriterionStatus
}

///|
fn native_editor_selection(
  acceptance? : String = "The selected editor action works",
) -> String {
  (
    {
      "contract": "moontown.editor_feature_selection.v1",
      "selected_feature": "fixture-editor",
      "title": "Fixture Editor",
      "implementation_hint": "Implement the selected source behavior",
      "acceptance": [acceptance],
      "current_gap": "Synthetic fixture only",
    } : Json).stringify()
}

///|
async fn native_editor_fixture(
  criterion_id? : String = "editor-selected-feature-implementation",
  selection? : String = native_editor_selection(),
  omit_course_page? : String = "",
  existing_plan? : String,
) -> NativeEditorFixture {
  let root = @fs.realpath(@fsx.mkdtemp("/tmp/town-planbook-editor-producer-XXXXXX"))
  let source_root = root + "/source"
  let course_root = root + "/course"
  let book_root = root + "/planbook"
  @fs.mkdir(course_root)
  @fs.mkdir(book_root)
  native_editor_materialize_retained_source(source_root)
  let catalog_path = root + "/catalog.json"
  @moonbook.save_catalog_file(catalog_path, [
    @moonbook.BookCatalogEntry::new(
      id=default_planbook_book_id(),
      name="PlanBook fixture",
      purpose="Synthetic owner handoff",
      workspace_root=book_root,
      tags=["planbook"],
    ),
    @moonbook.BookCatalogEntry::new(
      id=@course_book.default_wenyu_course_book_id(),
      name="Course fixture",
      purpose="Captured inputs",
      workspace_root=course_root,
    ),
  ])
  for
    relative in [
      "wiki/course/beginner-course.md", "wiki/course/exercises.md", "wiki/course/progress-rubric.md",
    ] {
    if relative != omit_course_page {
      @support.write_text_file(
        course_root + "/" + relative,
        "Fixture course input: " + relative + "\n",
      )
    }
  }
  for relative in planbook_repair_context_pages() {
    if relative != @planbook_policy.repair_context_relative_path() &&
      relative != @planbook_policy.repair_plan_relative_path() {
      @support.write_text_file(
        book_root + "/" + relative,
        "Fixture generic context: " + relative + "\n",
      )
    }
  }
  if selection != "" {
    @support.write_text_file(
      book_root + "/raw/editor-pipeline/next-feature.json",
      selection,
    )
  }
  if existing_plan is Some(content) {
    @support.write_text_file(
      book_root + "/" + @native_work.editor_owner_plan_relative(),
      content,
    )
  }
  {
    root,
    source_root,
    course_root,
    book_root,
    snapshot_path: root + "/town.json",
    catalog_path,
    criterion: {
      id: criterion_id,
      plan_id: "2026-05-31-editor-mode-real-pipeline",
      title: "Editor fixture",
      owner: "moontown",
      satisfied: false,
      evidence: "Fixture-only source gap",
      next_action: "Implement captured editor requirement",
    },
  }
}

///|
async fn native_editor_materialize(
  fixture : NativeEditorFixture,
) -> PlanbookRepairTask {
  materialize_native_planbook_repair(
    fixture.criterion,
    fixture.snapshot_path,
    fixture.book_root,
    fixture.catalog_path,
    false,
    source_root_override=fixture.source_root,
  )
}

///|
async fn native_editor_saved(
  fixture : NativeEditorFixture,
  id : String,
) -> @native_work.Work {
  for
    work in @native_work.load(
      path=@native_work.path_for_snapshot(fixture.snapshot_path),
    ).work {
    if work.id == id {
      return work
    }
  }
  fail("fixture native work missing")
}

///|
fn native_editor_field(value : Json, key : String) -> Json {
  match value {
    Object(fields) => fields.get(key).unwrap_or(Json::null())
    _ => Json::null()
  }
}

///|
fn native_editor_text(value : Json, key : String) -> String {
  match native_editor_field(value, key) {
    String(value) => value
    _ => ""
  }
}

///|
fn native_editor_rows(value : Json, key : String) -> Array[Json] {
  match native_editor_field(value, key) {
    Array(value) => value
    _ => []
  }
}

///|
fn native_editor_spec(
  work : @native_work.Work,
) -> @native_work.EditorOwnerSpec raise {
  @json.from_json(
    native_editor_field(work.request.acceptance_policy, "editor_owner_output"),
  )
}

///|
fn native_editor_client(
  request : @native_work.Request,
  posted : Array[String],
  journal : Array[Json],
  receipts : Array[Json],
  models : Array[String],
  calls : Array[String],
) -> @native_code_control.Client {
  @native_code_control.Client::new(
    owner_workspace=request.owner_workspace,
    instance_id="editor-fixture-instance",
    config_path="/fixture-only/never-read/control.json",
    request=async fn(method, route, body) {
      calls.push(method + " " + route)
      if route == "/v1/code/capabilities" {
        return Ok({
          "model_workspace_contract": "mooncode.model-workspace.v1",
          "completion_outcome_contract": "mooncode.completion-outcome.v1",
        })
      }
      if route == "/v1/moongate-route" {
        return Ok({
          "contract": "moonclaw.moongate-route.v1",
          "ready": true,
          "default_model": models[0],
          "models": [{ "name": models[0] }],
        })
      }
      if method == "POST" {
        posted.push(body)
        let command = @json.parse(body)
        return Ok({
          "accepted": true,
          "session_id": native_editor_text(command, "session_id"),
          "command_id": native_editor_text(
            native_editor_field(command, "packet"),
            "command_id",
          ),
          "book_root": request.execution_root,
        })
      }
      if posted.is_empty() {
        return Err("native_not_found")
      }
      let command = @json.parse(posted[0])
      let projection : Json = {
        "protocol": "mooncode.v1",
        "owner": "moonclaw",
        "session_id": native_editor_text(command, "session_id"),
        "book_root": request.execution_root,
      }
      guard projection is Object(fields) else {
        fail("fixture projection missing")
      }
      if route.contains("runtime-claim") {
        fields[if receipts.is_empty() {
          "claimed_commands"
        } else {
          "delivered_commands"
        }] = [
          {
            "command_id": native_editor_text(
              native_editor_field(command, "packet"),
              "command_id",
            ),
            "command": command,
            "receipt": if receipts.is_empty() {
              Json::null()
            } else {
              receipts[0]
            },
          },
        ]
      } else if route.contains("runtime-events") {
        fields["events"] = journal.to_json()
        fields["event_count"] = journal.length().to_json()
      }
      Ok(projection)
    },
  )
}

///|
fn native_editor_event(
  work : @native_work.Work,
  tool : String,
  sequence : Int,
  metadata : Json,
) -> Json {
  let reservation = work.reservation.unwrap()
  {
    "id": "fixture-event-" + sequence.to_string(),
    "journal_sequence": sequence.to_string(),
    "source": "moonclaw-native-tool-exec",
    "protocol": "mooncode.v1",
    "session_id": reservation.session_id,
    "command_id": reservation.command_id,
    "book_root": reservation.execution_root,
    "tool": tool,
    "tool_result": {
      "tool": tool,
      "ok": true,
      "is_error": false,
      "metadata": metadata,
    },
  }
}

///|
fn native_editor_fingerprint(content : String) -> String {
  "present:" +
  @base64.encode(Bytes::from_array(@crypto.sha256(@utf8.encode(content))))
}

///|
/// Injected journal and provider completion are fixture evidence only. The
/// production sync performs actual file/Git observations and owner writes; no
/// compiler, shell validation command, or live provider is run by this helper.
async fn native_editor_finish_fixture(
  running : @native_work.Work,
  journal : Array[Json],
  receipts : Array[Json],
  omit_command? : String = "",
) -> String {
  let source_path = running.request.execution_root + "/source.mbt"
  let before = @fs.read_file(source_path).text()
  let code = "///|\npub fn editor_fixture_answer() -> Int {\n  42\n}\n"
  @support.write_text_file(source_path, code)
  journal.push(
    native_editor_event(running, "checkpoint", 1, {
      "accepted": true,
      "all_done": false,
      "fixture_injected": true,
      "checkpoint": {
        "milestones": [{ "id": "implementation", "status": "pending" }],
      },
    }),
  )
  journal.push(
    native_editor_event(running, "write", 2, {
      "path": "source.mbt",
      "changed": true,
      "before_fingerprint": native_editor_fingerprint(before),
      "after_fingerprint": native_editor_fingerprint(code),
      "fixture_injected": true,
    }),
  )
  // Do not replace or shorten the production policy to accommodate a fixture.
  for
    index, required in native_editor_rows(
      running.request.acceptance_policy,
      "required_validation_commands",
    ) {
    guard required is String(command) else {
      fail("frozen command must be a string")
    }
    if command == omit_command {
      continue
    }
    journal.push(
      native_editor_event(running, "shell", index + 3, {
        "cmd": command,
        "cwd": ".",
        "exit_code": 0,
        "run_id": "fixture-only-run-" + index.to_string(),
        "approval_id": "fixture-only-approval-" + index.to_string(),
        "execution_sandbox_policy": "grant-bound",
        "sandbox_evidence": {
          "command_digest": @native_work.digest(command),
          "cleanup_verified": true,
          "fixture_injected": true,
          "actual_compiler_execution": false,
        },
      }),
    )
  }
  journal.push(
    native_editor_event(running, "checkpoint", 90, {
      "accepted": true,
      "all_done": true,
      "fixture_injected": true,
      "checkpoint": {
        "milestones": [{ "id": "implementation", "status": "done" }],
      },
    }),
  )
  let spec = native_editor_spec(running)
  let answer = (
    {
      "contract": "planbook.editor.native-result.v1",
      "work_id": running.id,
      "book_id": running.request.book_id,
      "criterion_id": spec.criterion_id,
      "selected_feature": spec.selected_feature,
      "selection_digest": spec.selection_digest,
      "outcome": "implemented",
      "summary": "Synthetic source mutation with injected fixture validation evidence",
      "acceptance_evidence": spec.acceptance.map(acceptance => {
        (
          {
            "acceptance": acceptance,
            "explanation": "Fixture-only observation; no compiler or live provider execution claimed",
          } : Json)
      }),
      "residual_risks": [
        "All required validation journal entries are synthetic fixture evidence",
      ],
    } : Json).stringify()
  let reservation = running.reservation.unwrap()
  receipts.push({
    "protocol": "mooncode.v1",
    "owner": "moonclaw",
    "status": "runtime-completed",
    "journal_sequence": "100",
    "session_id": reservation.session_id,
    "command_id": reservation.command_id,
    "book_root": reservation.execution_root,
    "command": @json.parse(reservation.request_body),
    "execution": {
      "tool_results": [
        {
          "tool": "finish",
          "accepted": true,
          "result": { "is_error": false, "metadata": { "answer": answer } },
        },
      ],
    },
  })
  answer
}

///|
// Exact bytes retained from native_work/wenyu_retained_fixture_wbtest.mbt.
// This source fixture needs no git init, add, commit, config mutation or download.
async fn native_editor_materialize_retained_source(
  destination : String,
) -> Unit {
  let files : Array[(String, String)] = [
    ("moon.mod", "bmFtZSA9ICJ2ZWN0aWUvbW9vbnRvd24iCg=="),
    ("source.mbt", "YmVmb3JlCg=="),
    ("notes.txt", "b3JpZ2luYWwgbm90ZXMK"),
    (".git/HEAD", "cmVmOiByZWZzL2hlYWRzL21hc3Rlcgo="),
    (
      ".git/index", "RElSQwAAAAIAAAADasBJHA3yLjBqwEkcDfIuMAAAACcABf3SAACBpAAAA+gAAAPoAAAAGW7vmNieIVEn8r6IB+wWjppZF1lFAAhtb29uLm1vZAAAasBJHA4Ed/FqwEkcDgR38QAAACcABf3XAACBpAAAA+gAAAPoAAAAD52NyAfQkad8e7I+ur5cnGDsx7OIAAlub3Rlcy50eHQAasBJHA31TlBqwEkcDfVOUAAAACcABf3UAACBpAAAA+gAAAPoAAAAB5C+HzBWxPRx+XeihJe41LOSxVoCAApzb3VyY2UubWJ0AAAAAAAAAABUUkVFAAAAGQAzIDAKQt6kyx44vCUbWgB5+z9XPBKEwMz59wx+W6JKhSnU8KXL8fJIWO1NBw==",
    ),
    (
      ".git/config", "W2NvcmVdCglyZXBvc2l0b3J5Zm9ybWF0dmVyc2lvbiA9IDAKCWZpbGVtb2RlID0gdHJ1ZQoJYmFyZSA9IGZhbHNlCglsb2dhbGxyZWZ1cGRhdGVzID0gdHJ1ZQo=",
    ),
    (
      ".git/refs/heads/master", "ZmRkNjUwNzA4YmIwNDlkZDIxZjFiNzY3MjUyODdkY2JmOWU0MmFmNAo=",
    ),
    (
      ".git/objects/fd/d650708bb049dd21f1b76725287dcbf9e42af4", "eAGdjUsOwiAUAF1zCi6gefwEEmNceY/H6yOSQNsgNT2+Rm/gbjYzQ0trZUjl3WF0Zmn1xGgpKTYhkXYqOQTwMSeTnTekdLAERAK38Vi6vJd9bJ3lJf/gxju2tfKpzC+sZbp+0hFiODtt5RE8gKDvcvBfskj45FpmFm98qzqN",
    ),
    (
      ".git/objects/42/dea4cb1e38bc251b5a0079fb3f573c1284c0cc", "eAErKUpNVTA0NGQwNDAwMzFRyM3Pz9PLzU9hyHs/48Y8xUD1T/s62N+I9c2KFI90harJyy9JLdYrqShhmNt7gv3CxOU11Zvsdu2LmZPw5vjmDqii4vzSouRUvdykEoYJ++QNwo58KfxZvqhl+o4rmycdjWICAKZDMY0=",
    ),
    (
      ".git/objects/90/be1f3056c4f471f977a28497b8d4b392c55a02", "eAFLyslPUjBnSEpNyy9K5QIAIm8EdA==",
    ),
    (
      ".git/objects/9d/8dc807d091a77c7bb23ebabe5c9c60ecc7b388", "eAFLyslPUjA0ZcgvykzPzEvMUcjLL0kt5gIAXFMHzg==",
    ),
    (
      ".git/objects/6e/ef98d89e215127f2be8807ec168e9a59175945", "eAFLyslPUjAyZchLzE1VsFVQKktNLslM1c/Nz88ryS/PU+ICALGxCsM=",
    ),
  ]
  for (relative, encoded) in files {
    let path = destination + "/" + relative
    @support.ensure_parent_directory(path)
    @fs.write_file(path, @base64.decode(encoded), create_mode=CreateNew)
  }
}
