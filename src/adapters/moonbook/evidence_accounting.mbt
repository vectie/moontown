///|
struct EvidenceAccounting {
  total_count : Int
  domain_count : Int
  operational_count : Int
} derive(Debug, Eq)

///|
async fn evidence_accounting_for_workspace(
  root : String,
  fallback_total~ : Int,
) -> EvidenceAccounting {
  let evidence_path = @path.Path(root)
    .join(@path.Path("wiki/synthesis/evidence.md"))
    .to_string()
  if !(@fs.exists(evidence_path) catch { _ => false }) {
    return {
      total_count: fallback_total,
      domain_count: fallback_total,
      operational_count: 0,
    }
  }
  evidence_accounting_from_text(
    @fs.read_file(evidence_path).text() catch {
      _ => ""
    },
  )
}

///|
fn evidence_accounting_from_text(content : String) -> EvidenceAccounting {
  let blocks = evidence_record_blocks(content)
  let mut operational_count = 0
  for block in blocks {
    if evidence_block_is_operational(block) {
      operational_count += 1
    }
  }
  {
    total_count: blocks.length(),
    domain_count: blocks.length() - operational_count,
    operational_count,
  }
}

///|
fn evidence_record_blocks(content : String) -> Array[String] {
  let blocks : Array[String] = []
  let mut current = ""
  let mut active = false
  for raw in content.split("\n") {
    let line = raw.to_owned()
    if line.has_prefix("### ") {
      if active {
        blocks.push(current)
      }
      current = line + "\n"
      active = true
    } else if active {
      current = current + line + "\n"
    }
  }
  if active {
    blocks.push(current)
  }
  blocks
}

///|
fn evidence_block_is_operational(block : String) -> Bool {
  let lower = block.to_lower()
  if evidence_block_is_standing_watch(lower) {
    return !standing_watch_block_has_domain_delta(block)
  }
  lower.contains("workflow completed workspace=") &&
  lower.contains("/moonclaw-jobs/run-") &&
  !lower.contains("accepted_facts_count:") &&
  !lower.contains("wiki_pages_changed_count:")
}

///|
fn evidence_block_is_standing_watch(lower_block : String) -> Bool {
  lower_block.contains("standing-watch") ||
  lower_block.contains("standing watch") ||
  lower_block.contains("standing_goal_decision") ||
  lower_block.contains("next_check_hint")
}

///|
fn standing_watch_block_has_domain_delta(block : String) -> Bool {
  let decision = summary_field(block, "standing_goal_decision").to_lower()
  let accepted_facts = summary_field_int(block, "accepted_facts_count")
  let changed_pages = summary_field_int(block, "wiki_pages_changed_count")
  let book_changed = summary_field(block, "book_changed").to_lower()
  (decision == "update" || decision == "needs_review") &&
  (accepted_facts > 0 || changed_pages > 0 || book_changed == "yes")
}

///|
fn summary_field(content : String, key : String) -> String {
  let prefix = key.to_lower() + ":"
  for raw in content.split("\n") {
    let mut line = raw.trim().to_owned()
    if line.has_prefix("- ") {
      line = line[2:].trim().to_owned()
    }
    if line.to_lower().has_prefix("summary:") {
      line = line[8:].trim().to_owned()
    }
    if line.to_lower().has_prefix(prefix) {
      return line[prefix.length():].trim().trim(chars="`").to_owned()
    }
  }
  ""
}

///|
fn summary_field_int(content : String, key : String) -> Int {
  match first_non_negative_int(summary_field(content, key)) {
    Some(value) => value
    None => 0
  }
}

///|
fn first_non_negative_int(text : String) -> Int? {
  let mut seen = false
  let mut value = 0
  for char in text {
    if char >= '0' && char <= '9' {
      value = value * 10 + (char.to_int() - '0'.to_int())
      seen = true
    } else if seen {
      return Some(value)
    }
  }
  if seen {
    Some(value)
  } else {
    None
  }
}

///|
fn append_evidence_accounting_summary(
  summary : String,
  accounting : EvidenceAccounting,
) -> String {
  let extra = "domain_evidence=\{accounting.domain_count} operational_evidence=\{accounting.operational_count} total_evidence=\{accounting.total_count}"
  if summary.contains("domain_evidence=") {
    summary
  } else if summary.is_empty() {
    extra
  } else {
    summary + " " + extra
  }
}
