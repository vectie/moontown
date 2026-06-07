///|
async fn preseed_reference_style_inputs(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
) -> Unit {
  let report_path = optional_env_text("MOONTOWN_REFERENCE_REPORT_PATH")
  let visual_path = optional_env_text("MOONTOWN_REFERENCE_IMAGE_PATH")
  let source_hints_path = optional_env_text(
    "MOONTOWN_REFERENCE_SOURCE_HINTS_PATH",
  )
  if report_path is None && visual_path is None && source_hints_path is None {
    return
  }
  let root = @moonbook.workspace_root(entry)
  let bootstrap_root = "\{root}/raw/bootstrap"
  let mut copied_report = false
  let mut copied_report_lines = 0
  let mut copied_source_hints = false
  let mut copied_source_hint_lines = 0
  match report_path {
    Some(path) =>
      match read_optional_text(path) {
        Some(text) => {
          write_text_file("\{bootstrap_root}/REFERENCE_OUTPUT.md", text)
          copied_report = true
          copied_report_lines = count_reference_lines(text)
        }
        None => ()
      }
    None => ()
  }
  match visual_path {
    Some(path) =>
      write_text_file("\{bootstrap_root}/REFERENCE_VISUAL_PATH.txt", path)
    None => ()
  }
  match source_hints_path {
    Some(path) =>
      match read_optional_text(path) {
        Some(text) => {
          write_text_file("\{bootstrap_root}/REFERENCE_SOURCE_HINTS.md", text)
          copied_source_hints = true
          copied_source_hint_lines = count_reference_lines(text)
        }
        None => ()
      }
    None => ()
  }
  write_text_file(
    "\{bootstrap_root}/REFERENCE_STYLE.md",
    reference_style_seed_text(
      entry, objective, report_path, visual_path, source_hints_path, copied_report,
      copied_report_lines, copied_source_hints, copied_source_hint_lines,
    ),
  )
}

///|
fn optional_env_text(key : String) -> String? {
  match @sys.get_env_var(key) {
    Some(value) => {
      let trimmed = value.trim().to_owned()
      if trimmed.is_empty() {
        None
      } else {
        Some(trimmed)
      }
    }
    None => None
  }
}

///|
fn reference_style_seed_text(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  report_path : String?,
  visual_path : String?,
  source_hints_path : String?,
  copied_report : Bool,
  copied_report_lines : Int,
  copied_source_hints : Bool,
  copied_source_hint_lines : Int,
) -> String {
  let report_line = match report_path {
    Some(path) =>
      if copied_report {
        "- Reference report copied from `\{path}` to `raw/bootstrap/REFERENCE_OUTPUT.md` (\{copied_report_lines} lines)."
      } else {
        "- Reference report requested at `\{path}`, but the file could not be read."
      }
    None => "- No reference report path was supplied."
  }
  let visual_line = match visual_path {
    Some(path) => "- Reference visual path supplied: `\{path}`."
    None => "- No reference visual path was supplied."
  }
  let source_hint_line = match source_hints_path {
    Some(path) =>
      if copied_source_hints {
        "- Reference source hints copied from `\{path}` to `raw/bootstrap/REFERENCE_SOURCE_HINTS.md` (\{copied_source_hint_lines} lines)."
      } else {
        "- Reference source hints requested at `\{path}`, but the file could not be read."
      }
    None => "- No reference source hints path was supplied."
  }
  let target_line = if copied_report && copied_report_lines >= 200 {
    let target = (copied_report_lines * 60 + 99) / 100
    "- Reference-matched minimum: when enough screened sources exist, `raw/bootstrap/deep-report.md` should reach at least \{target} lines (60% of the reference report), and repair passes should target at least 30 lines above that minimum to avoid brittle near-misses."
  } else {
    "- No numeric reference-length minimum applies."
  }
  [
    "# Reference Style Seed",
    "",
    "This file is a style and quality seed for `\{entry.id}`. It is not domain evidence.",
    "",
    "## Objective",
    "",
    objective,
    "",
    "## Supplied References",
    "",
    report_line,
    target_line,
    visual_line,
    source_hint_line,
    "",
    "## Usage Rules",
    "",
    "- Use `raw/bootstrap/REFERENCE_OUTPUT.md` only to infer depth, organization, evidence density, visual/table expectations, and reader-facing quality.",
    "- Do not copy the reference report's factual claims into the new topic unless independent screened evidence supports them.",
    "- Use the reference report's route names, comparison axes, diagrams, and section taxonomy as hypotheses or search leads when they are relevant to the user's objective. Verify every adopted route independently before using it as evidence.",
    "- Use `raw/bootstrap/REFERENCE_SOURCE_HINTS.md`, when present, only as a lead sheet. Fetch, screen, include, reject, or mark each lead blocked before it can influence synthesis.",
    "- Match the reference's ambition and approximate length class: long-form thesis-first analysis, numbered sections, source-backed claims, comparison tables, roadmap or maturity logic, and a final evidence/limits section.",
    "- If the reference is in Chinese, keep Chinese as the default report language unless the user goal clearly asks for another language.",
    "- If a reference visual is supplied, use it as a cue for the kind of analytical visualization to create, such as a comparison matrix or radar-style score table. Do not treat the image as source evidence unless its underlying data is independently verified.",
  ].join("\n")
}

///|
fn count_reference_lines(text : String) -> Int {
  if text.is_empty() {
    return 0
  }
  let mut count = 0
  for _ in text.split("\n") {
    count += 1
  }
  count
}
