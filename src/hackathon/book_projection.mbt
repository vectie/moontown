///|
async fn write_private_book_file(path : String, text : String) -> Unit {
  @support.ensure_parent_directory(path)
  @fs.write_file(
    path,
    text,
    create_mode=CreateOrTruncate,
    permission=0o600,
    sync=Full,
  )
  @fs.chmod(path, 0o600)
}

///|
async fn prepare_competition_book(root : String) -> Unit {
  if !@fs.exists(root) {
    @fs.mkdir(root, recursive=true, permission=0o700)
  }
  guard @fs.kind(root, follow_symlink=false) is Directory else {
    fail("competition book root must be a directory")
  }
  @fs.chmod(root, 0o700)
  for
    directory in [
      "wiki", "raw", "raw/contest-express", "wiki/reviews", "events",
    ] {
    let path = root + "/" + directory
    if !@fs.exists(path) {
      @fs.mkdir(path, recursive=true, permission=0o700)
    }
    guard @fs.kind(path, follow_symlink=false) is Directory else {
      fail("competition book directory must be a directory")
    }
    @fs.chmod(path, 0o700)
  }
}

///|
fn competition_brief_markdown(challenge : Challenge) -> String {
  [
    "# " + challenge.name,
    "",
    "Contest Express brief · benchmark v\{challenge.benchmark_version}",
    "",
    "## Mayor's topic",
    challenge.topic,
    "",
    "## Scope",
    challenge.scope,
    "",
    "## Possibility wiki",
    challenge.possibility_wiki,
    "",
    "## First person solution prompt",
    challenge.first_person_solution,
    "",
    "## Benchmark materials",
    challenge.benchmark_materials.map(item => "- " + item).join("\n"),
    "",
    "The ledger is authoritative. This MoonBook page is a reconstructable projection of versioned civic records.",
  ].join("\n")
}

///|
fn workspace_receipt_event(
  book_id : String,
  revision : Int,
  artifacts : Array[String],
) -> Json {
  @moonbook_contracts.ExecutableBookEvent::new(
    id="contest-revision-\{revision}",
    book_id~,
    result_id="contest-revision-\{revision}",
    summary="Contest Express ledger revision \{revision} projected into private MoonBook receipts.",
    artifacts~,
    event_type="contest.receipt.projected",
    accepted=false,
    requires_review=false,
    notify_town=false,
  ).to_json()
}

///|
async fn ensure_contest_worker_profile(root : String) -> Unit {
  let path = root + "/moonclaw.jobs.json"
  let existing = @support.read_json_file_or_empty_object(path)
  let profile : Json = {
    "family": "contest-express-review",
    "role": "worker",
    "priority": 145,
    "tags": ["civic", "contest-express", "benchmark", "review"],
    "match": {
      "all": ["civic", "contest-express"],
      "any": ["benchmark", "review", "submission"],
    },
    "steps": [
      {
        "id": "review_contest_receipts",
        "title": "Review Contest Express measured evidence",
        "kind": "job.analysis",
        "prompt_template": "Read wiki/reviews/contest-submissions.md and skills/civic-contest-coach/SKILL.md. Inspect the versioned Contest Express receipts. Report missing evidence, reproducibility gaps, conflicts, and qualification failures. Official measurements come from the configured benchmark worker. Return review recommendations; the assigned evaluator approves scores through Contest Express.",
        "metadata": {
          "preferred_skills": ["civic-contest-coach"],
          "enable_tools": true,
          "web_search": false,
          "timeout_ms": 300000,
          "board_lane": "Review",
          "board_order": 0,
          "role_runtime": {
            "planning_layer": "domain",
            "runtime_mode": "service",
            "tool_access": "workspace",
            "memory_scope": "domain",
            "allow_delegate": false,
            "allow_workspace_write": true,
            "allow_execution_tools": false,
            "output_contract": "wenyu.civic.contest_service.v1",
          },
        },
      },
    ],
  }
  write_private_book_file(
    path,
    @support.upsert_moonclaw_job_profile_json(
      existing, "contest-express-review", profile,
    ).stringify(indent=2),
  )
  write_private_book_file(
    root + "/skills/civic-contest-coach/SKILL.md",
    [
      "# Contest Express coaching and receipt review", "", "Use the existing Contest Express civic service contract. The Mayor owns event publication and lifecycle; the assigned evaluator signs official reviews. MoonBook holds private evidence and MoonClaw may propose review or coaching work.",
      "", "Read the immutable raw/contest-express revision receipts and wiki/reviews/contest-submissions.md. Match submission, track, benchmark version, configured metrics, qualification gates and SHA-256 evidence. Record conflicts, missing deliverables, and reproducibility gaps. Do not infer acceptance from a workspace update.",
      "", "The Town background worker runs only operator-registered benchmarks. Never execute participant-supplied scripts or fetch a URL as executable code. Worker receipts remain provisional until evaluator approval. A coaching recommendation cannot publish a score, enroll residents, resolve appeals, or finalize an event.",
    ].join("\n"),
  )
}

///|
async fn materialize_competition_books(
  state : HackathonState,
  ledger_path : String,
) -> Int {
  let base = ledger_path + ".books"
  if !@fs.exists(base) {
    @fs.mkdir(base, recursive=true, permission=0o700)
  }
  guard @fs.kind(base, follow_symlink=false) is Directory else {
    fail("competition books must be a directory")
  }
  @fs.chmod(base, 0o700)
  let catalog : Array[@moonbook.BookCatalogEntry] = []
  for challenge in state.challenges {
    guard valid_id(challenge.id) else { fail("invalid book identity") }
    let book_id = "contest-event-" + challenge.id
    let root = base + "/" + book_id
    prepare_competition_book(root)
    let entry = @moonbook.BookCatalogEntry::new(
      id=book_id,
      name=challenge.name,
      purpose="Contest Express brief, benchmark, and official review receipts.",
      workspace_root=root,
      tags=["civic", "contest-express", "competition", challenge.id],
      skills=["civic-contest-coach"],
    )
    catalog.push(entry)
    write_private_book_file(
      root + "/moonbook.catalog.json",
      entry.to_json().stringify(indent=2),
    )
    write_private_book_file(
      root + "/wiki/index.md",
      "# " +
      challenge.name +
      "\n\n- [Contest brief](contest-brief.md)\n- [Review queue](reviews/contest-submissions.md)\n",
    )
    write_private_book_file(
      root + "/wiki/contest-brief.md",
      competition_brief_markdown(challenge),
    )
    let revision_path = "raw/contest-express/revision-\{state.revision}.json"
    let submissions = state.submissions.filter(s => {
      s.challenge_id == challenge.id
    })
    let submission_ids = submissions.map(s => s.id)
    let receipt : Json = {
      "schema": "moontown.contest-express.book-receipt.v1",
      "revision": state.revision,
      "brief": challenge,
      "brief_history": state.challenge_history.filter(c => c.id == challenge.id),
      "program": competition_program(state, challenge.id),
      "program_history": state.program_history.filter(p => {
        p.challenge_id == challenge.id
      }),
      "submissions": submissions,
      "packages": state.submission_packages.filter(p => {
        submission_ids.contains(p.submission_id)
      }),
      "evaluations": state.evaluations.filter(e => {
        submission_ids.contains(e.submission_id)
      }),
      "benchmark_runs": state.benchmark_runs.filter(run => {
        submission_ids.contains(run.submission_id)
      }),
      "appeals": state.appeals.filter(appeal => {
        submission_ids.contains(appeal.submission_id)
      }),
    }
    write_private_book_file(
      root + "/" + revision_path,
      receipt.stringify(indent=2),
    )
    write_private_book_file(
      root + "/events/contest-revision-\{state.revision}.json",
      workspace_receipt_event(book_id, state.revision, [revision_path]).stringify(
        indent=2,
      ),
    )
    let queue = submissions.map(submission => {
      let reviewed = state.evaluations.any(e => {
          e.submission_id == submission.id &&
          e.benchmark_version == challenge.benchmark_version
        }) ||
        state.benchmark_runs.any(run => {
          run.submission_id == submission.id &&
          run.benchmark_version == challenge.benchmark_version &&
          (run.state == "approved" || run.state == "rejected")
        })
      "- \{submission.id} · team \{submission.team_id} · version \{submission.version} · " +
      (if reviewed { "reviewed" } else { "pending review" })
    })
    write_private_book_file(
      root + "/wiki/reviews/contest-submissions.md",
      "# Contest Express review queue\n\n" + queue.join("\n"),
    )
    ensure_contest_worker_profile(root)
  }
  for team in state.teams {
    guard valid_id(team.id) && valid_id(team.challenge_id) else {
      fail("invalid book identity")
    }
    let book_id = "contest-team-" + team.id
    let root = base + "/" + book_id
    prepare_competition_book(root)
    let entry = @moonbook.BookCatalogEntry::new(
      id=book_id,
      name=team.name,
      purpose="Private team research, submissions, feedback, and appeal receipts.",
      workspace_root=root,
      tags=["civic", "contest-express", "team", team.challenge_id],
      skills=["civic-contest-coach"],
    )
    catalog.push(entry)
    write_private_book_file(
      root + "/moonbook.catalog.json",
      entry.to_json().stringify(indent=2),
    )
    if !@fs.exists(root + "/wiki/index.md") {
      write_private_book_file(
        root + "/wiki/index.md",
        "# " +
        team.name +
        "\n\nPrivate Contest Express team workspace. Keep research and drafts here. Accepted submissions and feedback are recorded in raw/contest-express.\n",
      )
    }
    let submission_ids = state.submissions
      .filter(s => s.team_id == team.id)
      .map(s => s.id)
    let receipt : Json = {
      "schema": "moontown.contest-express.team-receipt.v1",
      "revision": state.revision,
      "team": team,
      "profile": state.team_profiles
      .iter()
      .find_first(p => p.team_id == team.id),
      "invitations": state.invitations.filter(i => i.team_id == team.id),
      "submissions": state.submissions.filter(s => s.team_id == team.id),
      "packages": state.submission_packages.filter(p => {
        submission_ids.contains(p.submission_id)
      }),
      "evaluations": state.evaluations.filter(e => {
        submission_ids.contains(e.submission_id)
      }),
      "benchmark_runs": state.benchmark_runs.filter(run => {
        submission_ids.contains(run.submission_id)
      }),
      "appeals": state.appeals.filter(appeal => {
        submission_ids.contains(appeal.submission_id)
      }),
    }
    let revision_path = "raw/contest-express/revision-\{state.revision}.json"
    write_private_book_file(
      root + "/" + revision_path,
      receipt.stringify(indent=2),
    )
    write_private_book_file(
      root + "/events/contest-revision-\{state.revision}.json",
      workspace_receipt_event(book_id, state.revision, [revision_path]).stringify(
        indent=2,
      ),
    )
  }
  write_private_book_file(
    ledger_path + ".moonbooks.json",
    catalog.to_json().stringify(indent=2),
  )
  catalog.length()
}

///|
/// Projection failures remain visible and retryable without rolling back an
/// already committed competition receipt or pretending that the book synced.
pub async fn reconcile_competition_workspaces(
  state : HackathonState,
  path? : String = default_hackathon_path(),
) -> Json noraise {
  let status : Json = try {
    let count = materialize_competition_books(state, path)
    {
      "ready": true,
      "synced_revision": state.revision,
      "book_count": count,
      "message": "Private MoonBook receipts are current",
    }
  } catch {
    _ =>
      {
        "ready": false,
        "synced_revision": -1,
        "book_count": 0,
        "message": "Competition receipt committed; private MoonBook projection needs retry",
      }
  }
  write_private_book_file(
    path + ".workspace-sync.json",
    status.stringify(indent=2),
  ) catch {
    _ => ()
  }
  status
}

///|
pub async fn competition_workspace_sync_status(
  path? : String = default_hackathon_path(),
) -> Json noraise {
  @json.parse(@fs.read_file(path + ".workspace-sync.json").text()) catch {
    _ =>
      {
        "ready": false,
        "synced_revision": -1,
        "book_count": 0,
        "message": "Private MoonBook receipts have not been reconciled",
      }
  }
}
