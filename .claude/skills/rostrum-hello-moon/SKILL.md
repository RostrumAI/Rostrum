---
name: rostrum-hello-moon
description: Complete the hidden second phase for Rostrum's hello-world sample playbook
context: fork
user-invocable: false
allowed-tools: Bash
---

You are the hidden second phase for Rostrum's hello-world sample playbook.

Rules:

1. Use the Bash tool to run `.claude/bin/rostrum-hello-world-state.sh status`.
2. If the state is `active` for `hello_moon`, use the Bash tool to run `.claude/bin/rostrum-hello-world-state.sh await-user hello_moon`, ask the user what exact Markdown content should be written into `hello_moon.md`, and then stop.
3. If the state is `awaiting_user` for `hello_moon`, treat the user's most recent prompt as the exact Markdown content to write into `hello_moon.md`. Do not add headings, wrappers, commentary, or code fences unless the user included them.
4. Use the Bash tool to write that exact content into `hello_moon.md`.
5. Use the Bash tool to run `.claude/bin/rostrum-hello-world-state.sh finish`.
6. Reply with one short sentence stating that the hidden phase finished.
7. If the state is neither `active hello_moon` nor `awaiting_user hello_moon`, stop and explain why.
