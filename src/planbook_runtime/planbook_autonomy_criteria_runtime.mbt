///|
async fn planbook_semantic_review_criterion(
  snapshot_path : String,
  book_catalog_path : String,
) -> PlanbookCriterionStatus {
  let audit = @book_quality_runtime.inspect_book_quality(
    book_catalog_path~,
    snapshot_path~,
  )
  let ready = audit.scores.any(fn(score) { score.semantic_score is Some(_) })
  planbook_criterion(
    "semantic-ai-review-results",
    "2026-05-29-book-quality-upgrade",
    "AI semantic review results are written back to durable review-result files",
    "moonbook+moonclaw",
    ready,
    if ready {
      "at least one durable AI review result exists under book-quality/ai-review-results"
    } else {
      "no durable AI review result file found under book-quality/ai-review-results"
    },
    "dispatch MoonClaw reviewers through the book-quality review packets and persist accepted review results",
  )
}

///|
async fn planbook_runtime_book_quality_coverage_criterion(
  snapshot_path : String,
  book_catalog_path : String,
) -> PlanbookCriterionStatus {
  let audit = @book_quality_runtime.inspect_book_quality(
    book_catalog_path~,
    snapshot_path~,
  )
  match @storage.load_snapshot_file(snapshot_path) {
    Some(snapshot) => {
      let missing : Array[String] = []
      let active_runtime_books : Array[@moonbook.BookCatalogEntry] = []
      for book in snapshot.town.books {
        let entry = @book_quality_runtime.book_quality_catalog_entry_from_runtime_book(
          book,
        )
        if @book_quality.catalog_entry_active(
            entry.id,
            entry.name,
            entry.purpose,
            entry.tags,
          ) {
          active_runtime_books.push(entry)
          if !audit.scores.any(fn(score) { score.book_id == book.id }) {
            missing.push(book.id)
          }
        }
      }
      let ready = missing.is_empty()
      planbook_criterion(
        "runtime-books-in-quality-audit",
        "2026-05-29-book-quality-upgrade",
        "Active live runtime books are included in MoonBook quality audit",
        "moontown+moonbook",
        ready,
        if ready {
          "quality audit covers \{active_runtime_books.length()} active live runtime book(s), excluding archived/internal/smoke artifacts, and \{audit.total} total managed book(s)"
        } else {
          "quality audit is missing active live runtime book(s): \{missing.join(", ")}"
        },
        "merge active saved town snapshot books into the book-quality audit without mutating the curated MoonBook catalog; keep smoke/archive artifacts out of product-quality accounting",
      )
    }
    None =>
      planbook_criterion(
        "runtime-books-in-quality-audit",
        "2026-05-29-book-quality-upgrade",
        "Active live runtime books are included in MoonBook quality audit",
        "moontown+moonbook",
        false,
        "no saved town snapshot exists at \{snapshot_path}",
        "start the town daemon or create a saved snapshot before judging runtime book quality coverage",
      )
  }
}

///|
async fn planbook_validation_criterion(
  snapshot_path : String,
) -> PlanbookCriterionStatus {
  let base = planbook_autonomy_base_dir(snapshot_path)
  let path = "\{base}/planbook/latest-validation.md"
  let text = @support.read_text_or_empty(path)
  let ready = planbook_validation_evidence_ready(text)
  planbook_criterion(
    "validation-evidence",
    "2026-05-29-book-quality-upgrade",
    "Latest implementation validation is recorded beside the PlanBook status",
    "moontown",
    ready,
    if ready {
      "`planbook/latest-validation.md` contains a passing planbook.validation.v1 contract"
    } else {
      "latest validation evidence is missing or does not satisfy planbook.validation.v1"
    },
    "run validation, then write `.moontown/planbook/latest-validation.md` with `moon run src/cmd/main -- planbook validation`",
  )
}

///|
async fn planbook_runtime_recovery_criterion(
  snapshot_path : String,
) -> PlanbookCriterionStatus {
  let unresolved = planbook_unresolved_runtime_failures(snapshot_path)
  let ready = unresolved.count == 0
  planbook_criterion(
    "live-runtime-recovery",
    "2026-05-30-live-autonomy-self-healing",
    "Live runtime failures are visible to PlanBook repair",
    "moontown+moonclaw",
    ready,
    if ready {
      "no failed or stale executions remain in the saved town snapshot"
    } else {
      "\{unresolved.count} failed/stale executions remain: \{unresolved.sample}"
    },
    "classify the failed executions, repair Moontown dispatch/reconciliation when local, or return a precise MoonClaw ownership blocker",
  )
}

///|
async fn planbook_civic_service_reconciliation_criterion(
  book_catalog_path : String,
) -> PlanbookCriterionStatus {
  let portfolio = @civic_runtime.inspect_wenyu_civic_services(
    book_catalog_path~,
  )
  let ready = portfolio.total > 0 &&
    portfolio.operable_count == portfolio.total &&
    portfolio.proven_count == portfolio.total &&
    portfolio.blocked_count == 0 &&
    portfolio.missing_count == 0
  planbook_criterion(
    "civic-service-result-reconciliation",
    "2026-05-31-live-autonomy-spine",
    "Civic protocol outputs reconcile into MoonBook service results",
    "moontown+moonbook",
    ready,
    if ready {
      "\{portfolio.proven_count}/\{portfolio.total} civic services have current service-result proof with 0 blocked and 0 missing"
    } else {
      "\{portfolio.proven_count}/\{portfolio.total} civic services have service-result proof; blocked=\{portfolio.blocked_count}; missing=\{portfolio.missing_count}; operable=\{portfolio.operable_count}"
    },
    "run `moon run src/cmd/main -- civic reconcile`; if still open, inspect protocol ledgers and MoonBook persistence for the missing civic service",
  )
}

///|
priv struct PlanbookRuntimeFailureSummary {
  count : Int
  sample : String
}

///|
async fn planbook_unresolved_runtime_failures(
  snapshot_path : String,
) -> PlanbookRuntimeFailureSummary {
  match @storage.load_snapshot_file(snapshot_path) {
    Some(snapshot) => {
      let samples : Array[String] = []
      let mut count = 0
      for execution in snapshot.town.executions {
        if execution.status == @core.TaskExecutionStatus::Failed ||
          execution.status == @core.TaskExecutionStatus::Stale {
          count += 1
          if samples.length() < 3 {
            samples.push("\{execution.book_id}/\{execution.task_id}")
          }
        }
      }
      {
        count,
        sample: if samples.is_empty() {
          "none"
        } else {
          samples.join(", ")
        },
      }
    }
    None => { count: 0, sample: "no saved snapshot" }
  }
}
