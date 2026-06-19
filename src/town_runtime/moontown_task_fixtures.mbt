///|
fn goal_for_book(entry : @moonbook.BookCatalogEntry) -> String {
  match entry.id {
    "coding" =>
      "Plan next coding revisions, review the protocol, and keep harness memory healthy."
    "finance" =>
      "Refresh finance memory, review the ledger workflow, and prepare the next brief."
    _ => "Maintain the book and produce a keeper-ready domain summary."
  }
}

///|
fn fixture_book_tasks(
  entry : @moonbook.BookCatalogEntry,
) -> Array[@moonbook.BookTask] {
  let goal = goal_for_book(entry)
  match entry.id {
    "coding" =>
      [
        @moonbook.BookTask::new(
          id="goal-plan-next-coding-review",
          goal=Some(goal),
          title="Review pending book updates",
          kind="review",
          prompt="Review pending changes for the goal inside \{entry.name}: \{goal}",
          priority=100,
          requires_review=false,
          target_pages=["wiki/reviews/pending.md", "wiki/reviews/approved.md"],
          required_role=Some(Reviewer),
        ),
        @moonbook.BookTask::new(
          id="goal-plan-next-coding-planning",
          goal=Some(goal),
          title="Refresh local planning surfaces",
          kind="planning",
          prompt="Plan the next book-local revisions for the goal inside \{entry.name}: \{goal}",
          priority=95,
          requires_review=true,
          target_pages=[
            "wiki/synthesis/maintenance-plan.md", "wiki/synthesis/map.md",
          ],
          required_role=Some(Planner),
        ),
      ]
    "finance" =>
      [
        @moonbook.BookTask::new(
          id="goal-refresh-finance-memory-review",
          goal=Some(goal),
          title="Review pending book updates",
          kind="review",
          prompt="Review pending changes for the goal inside \{entry.name}: \{goal}",
          priority=100,
          requires_review=false,
          target_pages=["wiki/reviews/pending.md", "wiki/reviews/approved.md"],
          required_role=Some(Reviewer),
        ),
        @moonbook.BookTask::new(
          id="goal-refresh-finance-memory-analysis",
          goal=Some(goal),
          title="Produce domain-local task result",
          kind="analysis",
          prompt="Use the durable wiki and keeper memory in \{entry.name} without leaking to other books: \{goal}",
          priority=85,
          requires_review=true,
          target_pages=["wiki/index.md", "wiki/log.md", "keeper/INSIGHTS.md"],
          required_role=Some(MemoryKeeper),
        ),
      ]
    _ =>
      [
        @moonbook.BookTask::new(
          id="goal-\{entry.id}-analysis",
          goal=Some(goal),
          title="Produce domain-local task result",
          kind="analysis",
          prompt="Maintain the isolated book state for \{entry.name}: \{goal}",
          priority=80,
          requires_review=true,
          target_pages=["wiki/index.md", "wiki/log.md"],
          required_role=Some(Harness),
        ),
      ]
  }
}

///|
fn desired_task_count(entry : @moonbook.BookCatalogEntry) -> Int {
  match entry.id {
    "coding" => 2
    "finance" => 2
    _ => 1
  }
}
