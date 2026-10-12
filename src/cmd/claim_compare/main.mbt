///|
async fn read_source(path : String, limit : Int) -> Bytes {
  guard @fs.kind(path) == Regular else {
    fail("Input must be a regular file: " + path)
  }
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  let size = file.size()
  guard file.kind() == Regular && size >= 0L && size <= limit.to_int64() else {
    fail("Input must be a regular file within its byte limit: " + path)
  }
  file.read_exactly_at(size.to_int(), position=0L)
}

///|
async fn run() -> Unit {
  let usage = "Usage: claim_compare CLAIMS.csv|CLAIMS.tsv SOURCE_DIRECTORY json|markdown\nCompare explicit cross-book values backed by exact local source quotes. Columns: claim_id,book_id,topic,context,value,source_path,quote. Source paths are relative to SOURCE_DIRECTORY. Groups use exact topic/context; different_values is not semantic contradiction detection. Reads only selected regular UTF-8 files, never writes Books or runs providers. Use a stable local snapshot and redirect only to a new output file. See docs/CLAIM_COMPARISON.md."
  match @env.args()[1:] {
    ["--help"] | ["-h"] => println(usage)
    [table_path, source_root, format] => {
      guard format == "json" || format == "markdown" else { fail(usage) }
      let delimiter = match @table.table_delimiter(table_path, "") {
        Some(value) => value
        None => fail("Claim table filename must end in .csv or .tsv")
      }
      let table = read_source(table_path, 1048576)
      let paths = match @claims.source_paths(table, delimiter) {
        Ok(value) => value
        Err(error) => fail(error)
      }
      let root = @fs.realpath(source_root)
      guard @fs.kind(root) == Directory else {
        fail("Source root must be a directory")
      }
      let prefix = if root == "/" { root } else { root + "/" }
      let sources : Map[String, Bytes] = {}
      let mut total = 0
      for path in paths {
        let resolved = @fs.realpath(prefix + path)
        guard resolved.has_prefix(prefix) else {
          fail("Source resolves outside selected directory: " + path)
        }
        let bytes = read_source(resolved, 262144)
        total += bytes.length()
        guard total <= 8 * 1048576 else {
          fail("Sources exceed 8 MiB in total")
        }
        sources[path] = bytes
      }
      match @claims.report(table, delimiter, sources, format~) {
        Ok(output) => @stdio.stdout.write(output)
        Err(error) => fail(error)
      }
    }
    _ => fail(usage)
  }
}

///|
async fn main {
  run() catch {
    error => {
      @stdio.stderr.write("claim_compare: \{error}\n")
      @sys.exit(1)
    }
  }
}
