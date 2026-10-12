///|
fn column_position(value : String, count : Int) -> Int raise {
  let position = @string.parse_int(value) catch { _ => 0 }
  if position < 1 || position > count {
    fail("Column positions must be valid 1-based source indices")
  }
  position - 1
}

///|
async fn run() -> Unit {
  let usage = "Usage: table_view <input.csv|input.tsv> <all|filter-column> <contains|exact> <query> <source|sort-column> <asc|desc> <all|1,2,...>\nColumn positions are 1-based; duplicate/blank labels are addressed by position. Filtering and sorting use ASCII-only case folding: A/a match, but é/É stay distinct. Sorting uses UTF-16 text order, never numeric/date/locale collation. Output is derived CSV with a first source_data_row column and formula-neutralized cells. Source files are never changed."
  match @env.args()[1:] {
    ["--help"] | ["-h"] => println(usage)
    [path, filter, mode, query, sort, order, projection] => {
      if (mode != "contains" && mode != "exact") ||
        (order != "asc" && order != "desc") {
        fail(usage)
      }
      let delimiter = match @table.table_delimiter(path, "") {
        Some(d) => d
        None => fail("Input filename must end in .csv or .tsv")
      }
      let source = @fs.read_file(path).text()
      let table = match @table.parse_data_table(source, delimiter) {
        Ok(t) => t
        Err(e) => fail(e)
      }
      let column = if filter == "all" {
        None
      } else {
        Some(column_position(filter, table.headers.length()))
      }
      let sort_column = if sort == "source" {
        None
      } else {
        Some(column_position(sort, table.headers.length()))
      }
      let columns = if projection == "all" {
        table.headers.mapi((i, _) => i)
      } else {
        let positions : Array[Int] = []
        for p in projection.split(",") {
          positions.push(column_position(p.to_owned(), table.headers.length()))
        }
        positions
      }
      let rows = match
        table.view_rows(
          query,
          column?,
          exact=mode == "exact",
          sort_column?,
          descending=order == "desc",
        ) {
        Ok(r) => r
        Err(e) => fail(e)
      }
      let csv = match table.view_csv(rows, columns) {
        Ok(c) => c
        Err(e) => fail(e)
      }
      @stdio.stdout.write(csv)
    }
    _ => fail(usage)
  }
}

///|
async fn main {
  run() catch {
    error => {
      @stdio.stderr.write("table_view: \{error}\n")
      @sys.exit(1)
    }
  }
}
