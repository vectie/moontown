///|
test "revise passage notes preserves evidence and feeds ordinary draft" {
  let notebook = notebook_fixture()
  let original = notebook.excerpts[0]
  let revised = notebook.revise_excerpt(
    1, "Alternative exposure explanation", "Compare irrigation logs",
  )
  assert_eq(revised.pages, notebook.pages)
  assert_eq(revised.question, notebook.question)
  assert_eq(revised.excerpts[0], {
    ..original,
    observation: "Alternative exposure explanation",
    challenge: "Compare irrigation logs",
  })
  assert_eq(revised.excerpts[1], notebook.excerpts[1])
  assert_eq(notebook.excerpts[0], original)
  let draft = revised.draft()
  assert_true(draft.question.contains("Alternative exposure explanation"))
  assert_true(draft.question.contains("Compare irrigation logs"))
  assert_eq(draft.participants.length(), 2)
}

///|
test "revise notes refuses nonexistent selection and blank notes" {
  let notebook = notebook_fixture()
  for position in [0, notebook.excerpts.length() + 1] {
    try notebook.revise_excerpt(position, "Observation", "Challenge") catch {
      _ => ()
    } noraise {
      _ => fail("position must exist")
    }
  }
  for (observation, challenge) in [(" ", "Challenge"), ("Observation", "\n")] {
    try notebook.revise_excerpt(1, observation, challenge) catch {
      _ => ()
    } noraise {
      _ => fail("notes must be nonblank")
    }
  }
}
