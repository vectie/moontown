///|
fn notebook_fixture() -> @collaboration_contract.MaterialNotebook {
  let pages : Array[@collaboration_contract.MaterialPage] = [
    "water", "forest", "energy",
  ].map(id => {
    book_id: id,
    book_title: id,
    source_path: "raw/notes.md",
    digest: "sha256:0000000000000000000000000000000000000000000000000000000000000000",
    size_bytes: 24,
    text: "# Observation\nDry soil.\n",
  })
  {
    ..@collaboration_contract.empty_material_notebook("dry-soil", pages),
    title: "Explore dry soil",
    question: "Could shade explain the dry soil?",
    falsifier: "Compare shaded and exposed sensors after the same rainfall.",
    dissent: "Irrigation timing could explain the pattern.",
    assumptions: "The sites have comparable sensors.",
    reviewer_id: "alex",
    reviewer_name: "Alex",
    objection_reviewer_id: "sam",
    objection_reviewer_name: "Sam",
    excerpts: ["water", "forest"].map(id => {
      book_id: id,
      source_path: "raw/notes.md",
      quote: "Dry soil.",
      observation: "A local observation worth comparing.",
      challenge: "Check whether the periods and conditions are comparable.",
    }),
  }
}

///|
fn reject_notebook(
  notebook : @collaboration_contract.MaterialNotebook,
) -> Unit raise {
  try notebook.draft() catch {
    _ => ()
  } noraise {
    _ => fail("expected refusal")
  }
}

///|
test "material notebook starts blank and creates a sourced two Book inquiry" {
  let notebook = notebook_fixture()
  let empty = @collaboration_contract.empty_material_notebook(
    "new",
    notebook.pages,
  )
  assert_true(empty.excerpts.is_empty())
  assert_eq(empty.question, "")
  reject_notebook(empty)
  let draft = notebook.draft()
  assert_eq(draft.participants.length(), 2)
  assert_false(draft.participants.any(p => p.book_id == "energy"))
  assert_eq(draft.participants[0].source_paths, ["raw/notes.md"])
  assert_true(draft.question.contains("exact_quote"))
  assert_true(draft.question.contains(notebook.falsifier))
  assert_true(draft.question.contains("no schedule"))
  assert_true(draft.objection.contains(notebook.dissent))
}

///|
test "literal search keeps Book path digest line and truthful truncation" {
  let notebook = notebook_fixture()
  let hits = notebook.find("Dry")
  assert_eq(hits.matched_lines, 3)
  assert_eq(hits.matches[0].line_number, 2)
  assert_eq(hits.matches[0].text, "Dry soil.")
  assert_false(hits.truncated)
  assert_eq(notebook.find("dry").matched_lines, 0)
  assert_true(hits.case_sensitive)
  let lines : Array[String] = []
  for _ in 0..<110 {
    lines.push("Dry")
  }
  let text = lines.join("\n")
  let many = {
    ..notebook,
    pages: [{ ..notebook.pages[0], text, size_bytes: 439, }],
  }
  let result = many.find("Dry")
  assert_eq(result.matched_lines, 110)
  assert_eq(result.matches.length(), 100)
  assert_true(result.truncated)
  try notebook.find("") catch {
    _ => ()
  } noraise {
    _ => fail("empty search")
  }
}

///|
test "material passage selection rejects invented duplicate and single Book evidence" {
  let notebook = notebook_fixture()
  let first = notebook.excerpts[0]
  reject_notebook({ ..notebook, excerpts: [first, first], })
  reject_notebook({
    ..notebook,
    excerpts: [{ ..first, quote: "Invented", }, notebook.excerpts[1]],
  })
  reject_notebook({
    ..notebook,
    excerpts: [{ ..first, book_id: "unknown", }, notebook.excerpts[1]],
  })
  reject_notebook({
    ..notebook,
    excerpts: [{ ..first, challenge: "", }, notebook.excerpts[1]],
  })
  reject_notebook({ ..notebook, excerpts: [{ ..first, quote: "Dry", }, first], })
  reject_notebook({
    ..notebook,
    excerpts: [{ ..first, observation: "", }, notebook.excerpts[1]],
  })
}

///|
test "multiple distinct excerpts share one captured source path" {
  let notebook = notebook_fixture()
  let extra = { ..notebook.excerpts[0], quote: "Observation", }
  let draft = { ..notebook, excerpts: notebook.excerpts + [extra], }.draft()
  assert_eq(draft.participants[0].source_paths, ["raw/notes.md"])
  assert_eq(draft.participants.length(), 2)
}

///|
test "material notebook refuses unsafe pages missing owners and silent schema upgrades" {
  let notebook = notebook_fixture()
  reject_notebook({ ..notebook, contract_version: "v2", })
  reject_notebook({ ..notebook, pages: notebook.pages + [notebook.pages[0]], })
  reject_notebook({
    ..notebook,
    pages: [{ ..notebook.pages[0], source_path: "../private", }],
  })
  reject_notebook({
    ..notebook,
    pages: [{ ..notebook.pages[0], size_bytes: 0, }],
  })
  reject_notebook({ ..notebook, reviewer_id: "town-composer", })
  reject_notebook({ ..notebook, objection_reviewer_id: "alex", })
  reject_notebook({ ..notebook, falsifier: "", })
}
