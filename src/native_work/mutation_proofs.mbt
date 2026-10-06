///|
fn fort_fingerprint(entry : Json) -> String {
  if entry == Json::null() {
    return "absent"
  }
  let hash = text(entry, "fingerprint")
  if hash.length() != 64 {
    return ""
  }
  let bytes = @hex.decode(hash) catch { _ => return "" }
  "present:" + @base64.encode(bytes)
}

///|
fn mutation_proofs(
  tool : String,
  metadata : Json,
  baseline_files : Json,
  final_files : Json,
) -> Array[Json] {
  let proofs : Array[Json] = []
  if ["write", "edit", "apply_patch"].contains(tool) &&
    field(metadata, "changed") != false.to_json() {
    let files = rows(metadata, "files")
    for item in (if files.is_empty() { [metadata] } else { files }) {
      if field(item, "changed") == false.to_json() {
        continue
      }
      proofs.push({
        "path": if text(item, "file_path") != "" {
          text(item, "file_path")
        } else {
          text(item, "path")
        },
        "before_fingerprint": text(item, "before_fingerprint"),
        "after_fingerprint": text(item, "after_fingerprint"),
      })
    }
  }
  if ["shell", "moon_cmd"].contains(tool) &&
    text(metadata, "execution_sandbox_policy") == "grant-bound" {
    for change in rows(field(metadata, "sandbox_evidence"), "changes") {
      let path = text(change, "relative_path")
      // Scratch-only build outputs are not authored source. Source attribution
      // additionally requires owner-observed membership and exact final bytes.
      if field(baseline_files, path) == Json::null() &&
        field(final_files, path) == Json::null() {
        continue
      }
      proofs.push({
        "path": path,
        "before_fingerprint": fort_fingerprint(field(change, "before")),
        "after_fingerprint": fort_fingerprint(field(change, "after")),
      })
    }
  }
  proofs
}

///|
/// Recognize definite Git mutation attempts, including ordinary global options
/// and direct commands in a shell sequence. This is not a general shell audit:
/// unknown scripts, aliases and expansions remain unverified, not forbidden.
/// Their absence can never establish that no publication occurred.
fn observed_forbidden_git_operation(command : String) -> Bool {
  let segments : Array[Array[String]] = []
  let mut words : Array[String] = []
  let mut word = ""
  let mut quote = ' '
  let mut escaped = false
  for character in command {
    if escaped {
      word += character.to_string()
      escaped = false
    } else if character == '\\' && quote != '\'' {
      escaped = true
    } else if quote != ' ' {
      if character == quote {
        quote = ' '
      } else {
        word += character.to_string()
      }
    } else if character == '\'' || character == '"' {
      quote = character
    } else if [';', '&', '|', '\n', '\r'].contains(character) {
      if word != "" {
        words.push(word)
        word = ""
      }
      segments.push(words)
      words = []
    } else if character == ' ' || character == '\t' {
      if word != "" {
        words.push(word)
        word = ""
      }
    } else {
      word += character.to_string()
    }
  }
  if word != "" {
    words.push(word)
  }
  segments.push(words)
  for parts in segments {
    let executable = parts.get(0).unwrap_or("")
    if executable != "git" && !executable.has_suffix("/git") {
      continue
    }
    let mut index = 1
    while index < parts.length() {
      let part = parts[index]
      if ["-C", "-c", "--git-dir", "--work-tree", "--namespace", "--config-env"].contains(
          part,
        ) {
        index += 2
      } else if part.has_prefix("-") {
        index += 1
      } else {
        if ["push", "commit", "add"].contains(part) {
          return true
        }
        break
      }
    }
  }
  false
}
