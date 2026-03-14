# Claude Code Samples

This repository now includes two Claude Code experiments:

- an active Rostrum `hello-world` sample playbook
- the older, disabled `clear-on-stop` TTY injection experiment

Files:

- `.claude/settings.json`
- `.claude/skills/rostrum-hello-world/SKILL.md`
- `.claude/skills/rostrum-hello-world-phase/SKILL.md`
- `.claude/skills/rostrum-hello-moon/SKILL.md`
- `.claude/bin/rostrum-hello-world-state.sh`
- `.claude/hooks/rostrum-hello-world-prompt-submit.sh`
- `.claude/hooks/rostrum-hello-world-stop.sh`
- `.claude/hooks/clear-on-stop.sh`
- `.claude/hooks/clear-on-stop.log`

## Rostrum hello-world sample

The active sample demonstrates a two-phase Rostrum-style playbook using:

- a user-invoked skill: `/rostrum-hello-world`
- a hidden Claude-only phase-one writer: `rostrum-hello-world-phase`
- a hidden Claude-only skill: `rostrum-hello-moon`
- a local state file in `.claude/state/rostrum-hello-world.json`
- a `UserPromptSubmit` hook that injects resume instructions when the playbook is waiting on the user's content
- `Stop` and `SubagentStop` hooks that block until phase two finishes
- `context: fork` on both skills so each phase runs in isolated context

Expected flow:

1. The user runs `/rostrum-hello-world`.
2. The skill resets stale sample artifacts, starts the local state machine,
   moves the playbook into `awaiting_user hello_world`, and asks the user what to write.
3. When the user replies, the `UserPromptSubmit` hook injects resume context so Claude knows the prompt text is exact file content for `hello_world.md`.
4. Claude invokes the hidden `rostrum-hello-world-phase` skill, writes `hello_world.md`, advances to `hello_moon`, and invokes the hidden `rostrum-hello-moon` skill.
5. The hidden moon skill moves the playbook into `awaiting_user hello_moon` and asks the user what to write.
6. When the user replies again, the `UserPromptSubmit` hook injects resume context for `hello_moon.md`.
7. Claude invokes the hidden `rostrum-hello-moon` skill again, writes `hello_moon.md`, and marks the playbook complete.
8. If Claude tries to stop during an active phase, the stop hook blocks. If the playbook is waiting on the user, stopping is allowed.

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
4. Confirm that Claude pauses and asks what to write into `hello_world.md`.
5. Reply with exact Markdown content for `hello_world.md`.
6. Confirm that `hello_world.md` appears and Claude then pauses again for `hello_moon.md`.
7. Reply with exact Markdown content for `hello_moon.md`.
8. Confirm that `hello_moon.md` appears and the final stop is allowed.

## Relevant Claude docs

- Hooks guide: https://docs.anthropic.com/en/docs/claude-code/hooks-guide
- Hooks reference: https://docs.anthropic.com/en/docs/claude-code/hooks
- Slash commands: https://docs.anthropic.com/en/docs/claude-code/slash-commands
- Subagents: https://docs.anthropic.com/en/docs/claude-code/sub-agents
