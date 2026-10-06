///|
fn native_repair_policy(commit_required : Bool) -> Json {
  let policy : Json = {
    "contract": "planbook.repair.native-policy.v1",
    "commit_requirement": if commit_required {
      "required"
    } else {
      "not_requested"
    },
    "commit_provenance": if commit_required {
      "saved_legacy_packet"
    } else {
      "new_native_task_no_commit_requested"
    },
    "required_validation_commands": if commit_required {
      planbook_repair_required_commands()
    } else {
      [
        "moon fmt", "moon info", "moon check --no-render", "moon test src/planbook_runtime/planbook_autonomy_wbtest.mbt src/live_autonomy_runtime/live_autonomy_wbtest.mbt --no-render",
        "moon test --no-render", "git diff --check",
      ]
    },
    "preserve_preexisting_unrelated_dirty_files": true,
    "commit_only_repair_owned_files": true,
    "push_requested": false,
    "push_status": "not_requested",
  }
  if !commit_required && policy is Object(fields) {
    let commands = match fields["required_validation_commands"] {
      Array(commands) => commands
      _ => []
    }
    let checks : Array[Json] = []
    for index, command in commands {
      checks.push({
        "id": "check-" + (index + 1).to_string(),
        "tool": "shell",
        "command": command,
        "cwd": ".",
        "exit_code": 0,
      })
    }
    fields["completion_policy"] = {
      "contract": "mooncode.completion-outcome.v1",
      "allowed_outcomes": ["mutation", "no_change"],
      "no_change_reason": "already_satisfied",
      "alternative_milestone_ids": ["implementation"],
      "required_checks": checks,
      "evidence_scope": "native_tool_journal",
      "acceptance_scope": "engineering_only",
      "no_change_receipt_contract": "planbook.repair.native_no_change_receipt.v1",
    }
  }
  policy
}

///|
async fn saved_repair_commit_required(
  workspace_root : String,
  criterion_id : String,
) -> Bool {
  // Never reinterpret or overwrite existing ACP packets. Their historical
  // engineering policy required a commit; migration preserves that requirement.
  @fs.exists(
    planbook_repair_packet_path_for_criterion(workspace_root, criterion_id),
  )
}

///|
async fn materialize_native_planbook_repair(
  criterion : PlanbookCriterionStatus,
  snapshot_path : String,
  workspace_root : String,
  catalog_path : String,
  dispatch : Bool,
  source_root_override? : String,
) -> PlanbookRepairTask {
  let path = @native_work.path_for_snapshot(snapshot_path)
  let existing = @native_work.load(path~)
  let key = "planbook_repair:" + default_planbook_book_id() + ":" + criterion.id
  let mut pending : @native_work.Work? = None
  for work in existing.work {
    if work.request.kind == "planbook_repair" &&
      work.request.book_root == workspace_root &&
      (
        !@native_work.terminal(work.state) ||
        @native_work.editor_owner_pending(work)
      ) {
      pending = Some(work)
    }
  }
  let work = match pending {
    Some(work) => work
    None => {
      let (binding, blocker) = match
        @native_work.source_binding(
          match source_root_override {
            Some(root) => Some(root)
            None => @env.get_env_var("MOONTOWN_WORKSPACE_ROOT")
          },
        ) {
        Ok(binding) => (binding, "")
        Err(reason) => (Json::null(), reason)
      }
      let commit_required = saved_repair_commit_required(
        workspace_root,
        criterion.id,
      )
      let mut policy = native_repair_policy(commit_required)
      let mut editor_blocker = ""
      let editor = if @native_work.editor_owner_enabled(criterion.id) {
        Some(
          prepare_native_editor_owner(
            criterion.id,
            workspace_root,
            catalog_path,
          ),
        ) catch {
          error => {
            editor_blocker = error.to_string()
            None
          }
        }
      } else {
        None
      }
      if editor is Some(spec) {
        policy = native_editor_policy(policy, spec)
      }
      let key = match editor {
        Some(spec) =>
          key +
          ":editor-owner-v1" +
          (if spec.selection_digest == "" {
            ""
          } else {
            ":" + spec.selection_digest
          })
        None => key
      }
      let source = @native_work.source_root(binding)
      let raw_hints = @planbook_policy.repair_target_files_for_criterion(
        criterion.id,
        source,
        "<external-course-owner>",
        "<external-plan-owner>",
        "<external-feature-owner>",
      )
      let hints = raw_hints.filter(path => {
        if editor is None {
          return true
        }
        // Only these exact, classified inputs/outputs were captured above.
        ![
          "<external-course-owner>/wiki/course/beginner-course.md", "<external-course-owner>/wiki/course/exercises.md",
          "<external-course-owner>/wiki/course/progress-rubric.md", "<external-plan-owner>",
          "<external-feature-owner>",
        ].contains(path)
      })
      let context : Array[String] = [
        planbook_repair_request_header(criterion),
        "Native acceptance policy:\n" + policy.stringify(indent=2),
        "Apply and validate only the criterion's source repair. Preserve unrelated dirty and staged work. Never push. " +
        (if commit_required {
          "This saved task requires a repair-owned-path commit; do not use an all-files commit."
        } else {
          "No commit was requested; leave the validated repair uncommitted."
        }),
        "Run each required validation as a separate native shell call from the source root, matching the frozen tool, command and cwd exactly. Run formatting and interface generation first, then rerun the full required command set, including fmt/info, after the last source mutation. Use checkpoint in the first batch and emit an accepted all-done checkpoint after final checks before finish. " +
        (if editor is Some(_) {
          "Return the owner-issued editor finish JSON bound to this work; do not write Book result pages. MoonTown owns output storage. "
        } else {
          "Return repair_decision: accepted for a validated source mutation; do not write Book result pages. MoonTown owns output storage. "
        }) +
        (if commit_required {
          "This saved commit-required policy does not allow no_change; explain any blocker for operator cancellation."
        } else {
          "The frozen completion_policy allows an engineering-only no_change proposal with reason already_satisfied. Use identical structured completion_outcome/no_change fields on the final checkpoint and finish, reference each required-check event, and resolve only the named implementation milestone as already_satisfied. Your observation does not certify original-task or customer acceptance; those remain unevaluated. No net source, index or HEAD change is permitted for this outcome."
        }) +
        " Never manufacture a mutation merely to finish.",
        "Native repair skill: inspect the captured criterion and source with read/read_skill/moon_ide; apply the smallest useful source change with write/edit/apply_patch; inspect the focused diff; validate the final source state; explain limitations precisely. Use the existing operator-configured native execution sandbox and approval lifecycle for process tools. Do not push or mutate Git history/index. Engineering validation records the runtime's actual sandbox assurance; it does not certify absence of publication. Target paths are inspection hints, not the writable scope:\n" +
        hints.join("\n"),
      ]
      let mut input_blocker = blocker
      if editor_blocker != "" && input_blocker == "" {
        input_blocker = editor_blocker
      }
      if editor is Some(spec) {
        context.push(native_editor_context(spec))
      }
      if hints.any(path => path.has_prefix("<external-")) && input_blocker == "" {
        input_blocker = "native_owner_output_application_required: criterion includes Book/course outputs outside the source root"
      }
      for relative in planbook_repair_context_pages() {
        if relative == @planbook_policy.repair_context_relative_path() {
          context.push(planbook_repair_context_header(criterion))
          continue
        }
        if relative == @planbook_policy.repair_plan_relative_path() {
          context.push(
            "Plan criterion: " + criterion.to_json().stringify(indent=2),
          )
          continue
        }
        if relative.has_prefix("/") ||
          relative.split("/").any(part => part == "..") {
          input_blocker = "repair_context_path_invalid"
          continue
        }
        let file = workspace_root + "/" + relative
        if !@fs.exists(file) {
          if input_blocker == "" {
            input_blocker = "repair_context_missing: " + relative
          }
          continue
        }
        if @fs.kind(file, follow_symlink=false) != Regular ||
          @fs.realpath(file) != file {
          input_blocker = "repair_context_not_canonical: " + relative
          continue
        }
        let content = @fs.read_file(file).text()
        context.push(
          "Context " +
          relative +
          " sha256=" +
          @native_work.digest(content) +
          "\n" +
          content,
        )
      }
      let prompt = context.join("\n\n")
      @native_work.enqueue(
        {
          kind: "planbook_repair",
          work_key: key,
          generation: 0,
          owner_workspace: @storage.moontown_active_workspace_root(),
          book_id: default_planbook_book_id(),
          book_root: workspace_root,
          book_type: "planbook",
          catalog_path,
          execution_root: @native_work.source_root(binding),
          source_binding: binding,
          criterion_id: criterion.id,
          model_request: "",
          prompt,
          input_blocker,
          input_digest: @native_work.digest(prompt),
          output_contract: if editor is Some(_) {
            "planbook.editor.native-result.v1"
          } else {
            "planbook.repair.native_patch_receipt.v1"
          },
          result_path: planbook_repair_result_path_for_workspace(workspace_root),
          acceptance_policy: policy,
          created_at_ms: @env.now(),
        },
        path~,
      )
    }
  }
  let work = if dispatch {
    @native_work.sync(work.id, @env.now(), path~)
  } else {
    work
  }
  let packet_path = workspace_root + "/raw/planbook/" + work.id + ".native.json"
  if !@fs.exists(packet_path) {
    @support.write_text_file(
      packet_path,
      work.request.to_json().stringify(indent=2),
    )
  }
  {
    id: work.id,
    criterion_id: work.request.criterion_id,
    title: if work.request.criterion_id == criterion.id {
      criterion.title
    } else {
      "Existing native repair: " + work.request.criterion_id
    },
    status: @native_work.owner_status(work),
    owner: criterion.owner,
    workspace_root,
    packet_path,
    proposal_id: None,
    run_id: None,
    summary: @native_work.summary(work),
    validation_command: planbook_repair_validation_command(),
    generated_at_ms: work.request.created_at_ms,
  }
}

///|
async fn pending_native_planbook_repair(
  snapshot_path : String,
  workspace_root : String,
  dispatch : Bool,
) -> PlanbookRepairTask? {
  let path = @native_work.path_for_snapshot(snapshot_path)
  if !@fs.exists(path) {
    return None
  }
  for pending in @native_work.load(path~).work {
    if pending.request.kind != "planbook_repair" ||
      pending.request.book_root != workspace_root ||
      (
        @native_work.terminal(pending.state) &&
        !@native_work.editor_owner_pending(pending)
      ) {
      continue
    }
    let work = if dispatch {
      @native_work.sync(pending.id, @env.now(), path~)
    } else {
      pending
    }
    return Some({
      id: work.id,
      criterion_id: work.request.criterion_id,
      title: "Native repair: " + work.request.criterion_id,
      status: @native_work.owner_status(work),
      owner: "moontown",
      workspace_root,
      packet_path: workspace_root + "/raw/planbook/" + work.id + ".native.json",
      proposal_id: None,
      run_id: None,
      summary: @native_work.summary(work),
      validation_command: planbook_repair_validation_command(),
      generated_at_ms: work.request.created_at_ms,
    })
  }
  None
}
