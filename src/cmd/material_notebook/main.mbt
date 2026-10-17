///|
async fn input_json(path : String) -> Json {
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  let size = file.size()
  guard file.kind() == Regular && size >= 0L && size <= 1048576L else {
    fail("Input must be a regular JSON file of at most 1 MiB")
  }
  @json.parse(@utf8.decode(file.read_exactly_at(size.to_int(), position=0L)))
}

///|
async fn run() -> Unit {
  let usage = "Usage: material_notebook import <catalog.json> <draft-id> <selection.json>\n       material_notebook find <notebook.json> <literal-line>\n       material_notebook read <notebook.json> <book-id> <source-path>\n       material_notebook save <store-root> <catalog.json> <notebook.json> <recorded-at>\nOutput goes to stdout. Import/read/find are read-only. Edit question, owners and excerpt notes in the JSON notebook, then save a fresh unrun draft. Open it in Collaboration to edit, Prepare and export. See docs/MATERIAL_NOTEBOOK.md."
  match @env.args()[1:] {
    ["context", path, query, neighbors] => {
      let notebook : @contract.MaterialNotebook = @json.from_json(
        input_json(path),
      )
      println(
        notebook
        .find_context(query, @string.parse_int(neighbors))
        .to_json()
        .stringify(indent=2),
      )
    }
    ["revise", path, position, observation, challenge] => {
      let notebook : @contract.MaterialNotebook = @json.from_json(
        input_json(path),
      )
      println(
        notebook
        .revise_excerpt(@string.parse_int(position), observation, challenge)
        .to_json()
        .stringify(indent=2),
      )
    }
    ["select", path, book_id, source_path, first, last, observation, challenge] => {
      let notebook : @contract.MaterialNotebook = @json.from_json(
        input_json(path),
      )
      println(
        notebook
        .select_lines(
          book_id,
          source_path,
          @string.parse_int(first),
          @string.parse_int(last),
          observation,
          challenge,
        )
        .to_json()
        .stringify(indent=2),
      )
    }
    ["remove", path, position] => {
      let notebook : @contract.MaterialNotebook = @json.from_json(
        input_json(path),
      )
      println(
        notebook
        .remove_excerpt(@string.parse_int(position))
        .to_json()
        .stringify(indent=2),
      )
    }
    ["--help"] | ["-h"] => {
      println(usage)
      println(
        "       material_notebook context <notebook.json> <literal-line> <neighbor-lines>\nInspect 0–10 neighboring lines on each side of each literal match. The first 100 matches retain exact source identity and inclusive line ranges for select. Nothing is selected or saved.",
      )
      println(
        "       material_notebook revise <notebook.json> <one-based-excerpt> <observation> <challenge>\nRevise replaces authored notes only, retaining quote and source identity. Output goes to stdout; redirect to a NEW file, then use the ordinary save workflow.",
      )
      println(
        "       material_notebook select <notebook.json> <book-id> <source-path> <first-line> <last-line> <observation> <challenge>\n       material_notebook remove <notebook.json> <one-based-excerpt>\nSelect/remove write edited notebook JSON to stdout only. Redirect to a NEW file; redirecting to the input file truncates it before reading. Line ranges are inclusive and preserve CRLF. Save still verifies source bytes and requires a complete multi-Book inquiry.",
      )
    }
    ["import", catalog_path, draft_id, path] => {
      let selections : Array[@contract.MaterialSelection] = @json.from_json(
        input_json(path),
      )
      let store : @authoring.Store = { root: "", catalog_path, }
      let notebook = store.import_material(draft_id, selections)
      println(notebook.to_json().stringify(indent=2))
    }
    ["find", path, query] => {
      let notebook : @contract.MaterialNotebook = @json.from_json(
        input_json(path),
      )
      println(notebook.find(query).to_json().stringify(indent=2))
    }
    ["read", path, book_id, source_path] => {
      let notebook : @contract.MaterialNotebook = @json.from_json(
        input_json(path),
      )
      notebook.validate_pages()
      let pages = notebook.pages.filter(p => {
        p.book_id == book_id && p.source_path == source_path
      })
      guard pages.length() == 1 else {
        fail("Select an imported Book and source path")
      }
      @stdio.stdout.write(pages[0].text)
    }
    ["save", root, catalog_path, path, recorded_at] => {
      let notebook : @contract.MaterialNotebook = @json.from_json(
        input_json(path),
      )
      let store : @authoring.Store = { root, catalog_path, }
      let saved = store.save_material_notebook(notebook, recorded_at)
      println(saved.to_json().stringify(indent=2))
    }
    _ => fail(usage)
  }
}

///|
fn error_output(error : Error) -> String {
  let message = match error {
    @authoring.CollaborationError(message) => message
    Failure(message) => message
    _ => @authoring.error_message(error)
  }
  "material_notebook: " + message + "\n"
}

///|
async fn main {
  run() catch {
    error => {
      @stdio.stderr.write(error_output(error))
      @sys.exit(1)
    }
  }
}
