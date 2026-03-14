# Claude Code Samples

This repository now includes two Claude Code experiments:

- an active Rostrum `hello-world` sample playbook
- the older, disabled `clear-on-stop` TTY injection experiment

Files:

- `.claude/settings.json`
- `.claude/skills/rostrum-hello-world/SKILL.md`
- `.claude/skills/rostrum-hello-moon/SKILL.md`
- `.claude/bin/rostrum-hello-world-state.sh`
- `.claude/hooks/rostrum-hello-world-stop.sh`
- `.claude/hooks/clear-on-stop.sh`
- `.claude/hooks/clear-on-stop.log`

## Rostrum hello-world sample

The active sample demonstrates a two-phase Rostrum-style playbook using:

- a user-invoked skill: `/rostrum-hello-world`
- a hidden Claude-only skill: `rostrum-hello-moon`
- a local state file in `.claude/state/rostrum-hello-world.json`
- `Stop` and `SubagentStop` hooks that block until phase two finishes
- `context: fork` on both skills so each phase runs in isolated context

Expected flow:

1. The user runs `/rostrum-hello-world`.
2. The skill resets stale sample artifacts, starts the local state machine,
   creates `hello_world.md`, and advances the local state to `hello_moon`.
3. The outer skill immediately invokes the hidden `rostrum-hello-moon` skill.
4. The hidden skill creates `hello_moon.md`, marks the state complete, and returns.
5. If Claude tries to stop early, the stop hook blocks and points it back to the
   hidden skill.
6. The next stop is allowed because the playbook is finished.

The generated files are ignored by git:

- `hello_world.md`
- `hello_moon.md`

## Clear-on-stop experiment

`clear-on-stop.sh` is still in the repo as a failed experiment. It tries to
inject `/clear` into the active terminal when Claude stops. In this environment
the hook process did not have a controlling TTY, so it could not work
reliably.

That script is no longer wired into `.claude/settings.json`.

## Testing the sample

1. Start Claude Code in this repository.
2. Run `/rostrum-hello-world`.
3. Confirm that the skill starts from a clean slate even if the sample files already existed.
4. Confirm that `hello_world.md` appears first.
5. Confirm that Claude automatically continues into the hidden `rostrum-hello-moon` skill.
6. Confirm that `hello_moon.md` appears and the final stop is allowed.

## Relevant Claude docs

- Hooks guide: https://docs.anthropic.com/en/docs/claude-code/hooks-guide
- Hooks reference: https://docs.anthropic.com/en/docs/claude-code/hooks
- Slash commands: https://docs.anthropic.com/en/docs/claude-code/slash-commands
- Subagents: https://docs.anthropic.com/en/docs/claude-code/sub-agents
