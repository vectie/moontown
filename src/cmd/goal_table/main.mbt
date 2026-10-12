///|
async fn read_source(path : String) -> Bytes {
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  let size = file.size()
  guard file.kind() == Regular && size >= 0L && size <= 1048576L else {
    fail("Input must be a regular file of at most 1 MiB")
  }
  file.read_exactly_at(size.to_int(), position=0L)
}

///|
async fn run() -> Unit {
  let usage = "Usage: goal_table export STANDING-GOALS.json csv|tsv\n       goal_table import GOALS.csv|GOALS.tsv\nRead an explicit file and write the complete converted snapshot/table to stdout. No live registry replacement, Book creation or daemon start. Text cells are JSON strings, including double quotes; missing target/last-run is null. All ten fields and row order are retained, including disabled state and due/run ticks. Import is a whole snapshot, not a merge; removed rows are absent from its output. Redirect only to a NEW file, never over the input or a live registry. See docs/GOAL_TABLE.md."
  let result = match @env.args()[1:] {
    ["--help"] | ["-h"] => {
      println(usage)
      return
    }
    ["export", path, format] => {
      let delimiter = match format {
        "csv" => ','
        "tsv" => '\t'
        _ => fail(usage)
      }
      @transfer.snapshot_to_table(read_source(path), delimiter)
    }
    ["import", path] => {
      let delimiter = match @table.table_delimiter(path, "") {
        Some(value) => value
        None => fail("Import filename must end in .csv or .tsv")
      }
      @transfer.table_to_snapshot(read_source(path), delimiter)
    }
    _ => fail(usage)
  }
  match result {
    Ok(output) => @stdio.stdout.write(output)
    Err(error) => fail(error)
  }
}

///|
async fn main {
  run() catch {
    error => {
      @stdio.stderr.write("goal_table: \{error}\n")
      @sys.exit(1)
    }
  }
}
