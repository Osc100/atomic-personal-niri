# Global rules

- **Delegate to Devin.** Hand implementation, codebase exploration, reviews and any long task to
  the `devin` subagent, in the background, as a complete, self-contained task; keep working
  meanwhile, and check what Devin reports before relying on it. Do small, quick steps yourself.
  Devin runs SWE-2. Always pass the model to the subagent tool, so it shows in the subagent's
  label: `devin/swe-2-high` by default, `devin/swe-2-max` for a hard problem or when asked,
  `devin/swe-2-medium` for a quick one.
  When the task belongs to a worktree, make the first line of its prompt `Worktree: /abs/path`:
  Devin's session then opens in that worktree (its rules, its git, its paths) instead of here.
  The devin MCP server watches and steers Devin subagents while they work: `task_status` lists
  them, `peek_task` shows what one has done lately, `message_task` corrects or redirects one, and
  `stop_task` has one stop and report. Check on long tasks and steer instead of waiting for them.
  At most six Devin subagents run at once. A seventh replies that Devin is at capacity: wait for
  one to finish, then start it again, rather than retrying right away.
- **When Devin is unavailable, use DeepSeek.** If a Devin subagent replies that Devin is rate
  limited until a given time, or that its quota is used up, do not start Devin again before then.
  Hand the work instead to the `general` subagent with the model
  `opencode-go/deepseek-v4.1-flash#high`, in the background, the same way: a complete,
  self-contained task. It runs in this session's directory, so name the worktree's absolute path
  in the task and tell it to work there. The subagents MCP server watches and steers these with
  the same tools (`task_status`, `peek_task`, `message_task`, `stop_task`); `message_task` with
  `interrupt` cuts a long command short so the message is read at once.
  If what is left needs Devin and not DeepSeek, then once every subagent of this session has
  finished, run `claude-devin-acp wait-limit` with the shell tool in the background: it compacts
  this session, waits until Devin's limit lifts, and exits; when it does, go on, starting again
  the Devin tasks the limit stopped. Do not poll it or sleep yourself.
