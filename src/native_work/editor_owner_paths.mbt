///|
/// Resolve an owner-selected relative path without traversing symlinks. This
/// helper does not grant worker access or derive ownership from output text.
pub async fn editor_owner_file(root : String, relative : String) -> String {
  guard relative != "" &&
    !relative.has_prefix("/") &&
    !relative.contains("\\") &&
    !relative.contains("\n") &&
    !relative.split("/").any(part => part == ".." || part == "." || part == "") else {
    fail("editor_owner_path_invalid")
  }
  guard @fs.kind(root, follow_symlink=false) is Directory &&
    @fs.realpath(root) == root else {
    fail("editor_owner_root_not_canonical")
  }
  let parts = relative.split("/").to_array()
  let mut path = root
  for index, part in parts {
    path += "/" + part.to_owned()
    let kind = Some(@fs.kind(path, follow_symlink=false)) catch { _ => None }
    if kind is Some(SymLink) || (kind is Some(_) && @fs.realpath(path) != path) {
      fail("editor_owner_path_not_canonical: " + relative)
    }
    if index < parts.length() - 1 && kind is Some(_) && kind != Some(Directory) {
      fail("editor_owner_parent_not_directory: " + relative)
    }
  }
  path
}

///|
pub async fn editor_owner_fingerprint(
  root : String,
  relative : String,
) -> String {
  let path = editor_owner_file(root, relative)
  if !@fs.exists(path) {
    return "absent"
  }
  guard @fs.kind(path, follow_symlink=false) is Regular else {
    fail("editor_owner_output_not_regular: " + relative)
  }
  digest(@fs.read_file(path).text())
}

///|
fn editor_owner_directory(work_id : String) -> String raise {
  guard work_id.has_prefix("town-work-") && work_id.length() == 42 else {
    fail("editor_owner_work_id_invalid")
  }
  for character in work_id[10:].to_owned() {
    guard character is ('0'..='9' | 'a'..='f') else {
      fail("editor_owner_work_id_invalid")
    }
  }
  "raw/editor-pipeline/native/" + work_id
}

///|
fn editor_engineering_receipt(receipt : Json) -> Json {
  let copied : Map[String, Json] = Map([])
  if receipt is Object(fields) {
    for key, value in fields {
      if key != "owner_application" {
        copied[key] = value
      }
    }
  }
  Json::object(copied)
}

///|
pub fn editor_owner_pending(work : Work) -> Bool {
  work.state == "completed" &&
  editor_owner_opted_in(work.request) &&
  text(field(work.receipt, "owner_application"), "status") != "applied"
}

///|
pub fn owner_status(work : Work) -> String {
  if editor_owner_pending(work) {
    "waiting_owner_output"
  } else {
    work.state
  }
}

///|
fn editor_with_application(
  work : Work,
  status : String,
  blocker : String,
  receipt : Json,
) -> Work {
  let engineering = editor_engineering_receipt(work.receipt)
  if engineering is Object(fields) {
    fields["owner_application"] = {
      "contract": "planbook.editor.owner-application-status.v1",
      "status": status,
      "blocker": blocker,
      "receipt": receipt,
    }
  }
  { ..work, receipt: engineering, blocked_reason: blocker, }
}
