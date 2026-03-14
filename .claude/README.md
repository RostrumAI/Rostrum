# Claude Code Sample Hook

This repository includes an experimental Claude Code `Stop` hook that attempts
to clear the active session whenever Claude finishes responding.

Files:

- `.claude/settings.json`
- `.claude/hooks/clear-on-stop.sh`

## Important caveat

This is not using a documented Claude Code API for clearing the current
session. Anthropic's hook documentation describes hooks as shell commands that
communicate through stdin, stdout, stderr, and exit codes, and explicitly says
command hooks cannot directly trigger commands or tool calls.

Because of that limitation, this sample uses terminal input injection to push
`/clear` into the current TTY after a `Stop` event.

## Expected behavior

Best case:

1. Claude finishes responding.
2. The `Stop` hook fires.
3. The hook injects `/clear` into the active terminal.
4. Claude clears the conversation context.

## Known limitations

- It is local-terminal-only.
- It depends on `python3`.
- It works best when the Claude CLI is attached to a traditional TTY.
- It may not work in all terminals, OS versions, or sandboxed environments.
- It is not expected to work reliably in browser, remote-control, or IDE panel
  surfaces.
- It is intentionally hacky and should not be treated as a production adapter
  contract.

## Disable it

Set `ROSTRUM_DISABLE_CLAUDE_STOP_CLEAR=1` in the environment before starting
Claude Code, or remove the `Stop` hook from `.claude/settings.json`.

## Relevant Claude docs

- Hooks guide: https://docs.anthropic.com/en/docs/claude-code/hooks-guide
- Hooks reference: https://docs.anthropic.com/en/docs/claude-code/hooks
