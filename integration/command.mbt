///|
pub struct CompletedCommand {
  command : String
  args : Array[String]
  status : Int
  stdout : String
  stderr : String
} derive(Show, Eq, ToJson)

///|
pub suberror CommandFailed {
  CommandFailed(CompletedCommand)
} derive(ToJson)

///|
pub impl Show for CommandFailed with output(
  self : CommandFailed,
  logger : &Logger,
) -> Unit {
  let CommandFailed(command) = self
  logger.write_string("Command ")
  logger.write_string(render_command(command.command, command.args).escape())
  logger.write_string(" failed with status ")
  command.status.output(logger)
  if !command.stdout.trim().is_blank() {
    logger.write_string(".\nstdout:\n")
    logger.write_string(command.stdout.trim().to_string())
  }
  if !command.stderr.trim().is_blank() {
    logger.write_string(".\nstderr:\n")
    logger.write_string(command.stderr.trim().to_string())
  }
}

///|
pub fn render_command(command : String, args : Array[String]) -> String {
  let builder = StringBuilder::new()
  builder.write_string(command)
  for arg in args {
    builder.write_char(' ')
    builder.write_string(arg)
  }
  builder.to_string()
}

///|
pub async fn run(
  command : String,
  args : Array[String],
  cwd? : String? = None,
) -> CompletedCommand {
  @async.with_task_group(group => {
    fn redirect_output() raise {
      let (pipe, output) = @process.read_from_process()
      let task = group.spawn(() => {
        defer pipe.close()
        @encoding/utf8.decode_lossy(pipe.read_all().binary())
      })
      (task, output)
    }

    let stdout = redirect_output()
    let stderr = redirect_output()
    let status = @process.run(
      command,
      args,
      cwd?=cwd.map(cwd => cwd),
      stdout=stdout.1,
      stderr=stderr.1,
    )
    { command, args, status, stdout: stdout.0.wait(), stderr: stderr.0.wait() }
  })
}

///|
pub async fn run_checked(
  command : String,
  args : Array[String],
  cwd? : String? = None,
) -> CompletedCommand {
  let completed = run(command, args, cwd~)
  if completed.status != 0 {
    raise CommandFailed(completed)
  }
  completed
}

///|
pub async fn run_json(
  command : String,
  args : Array[String],
  cwd? : String? = None,
) -> Json {
  let completed = run_checked(command, args, cwd~)
  parse_json_stdout(completed)
}

///|
fn parse_json_stdout(completed : CompletedCommand) -> Json raise {
  let trimmed = completed.stdout.trim().to_string()
  @json.parse(trimmed) catch {
    _ => {
      let lines = trimmed.split("\n").to_array()
      let count = lines.length()
      for offset in 0..<count {
        let start = count - offset - 1
        let line = lines[start].trim().to_string()
        if line.has_prefix("{") || line.has_prefix("[") {
          let builder = StringBuilder::new()
          for index in start..<count {
            if index > start {
              builder.write_char('\n')
            }
            builder.write_string(lines[index].to_string())
          }
          let candidate = builder.to_string()
          let parsed = @json.parse(candidate) catch { _ => continue }
          return parsed
        }
      }
      raise CommandFailed({
        ..completed,
        stderr: if completed.stderr.trim().is_blank() {
          "Expected JSON output on stdout."
        } else {
          completed.stderr
        },
      })
    }
  }
}
