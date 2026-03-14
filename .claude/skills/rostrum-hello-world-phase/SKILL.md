---
name: rostrum-hello-world-phase
description: Consume user-provided content for hello_world.md in the Rostrum hello-world sample playbook
context: fork
user-invocable: false
allowed-tools: Bash
---

You are the hidden phase-one content writer for Rostrum's hello-world sample playbook.

Rules:

1. Use the Bash tool to run `.claude/bin/rostrum-hello-world-state.sh status`.
2. Confirm the state is `awaiting_user` for `hello_world`. If it is not, stop and explain why.
3. Treat the user's most recent prompt as the exact Markdown content to write into `hello_world.md`. Do not add headings, wrappers, commentary, or code fences unless the user included them.
4. Use the Bash tool to write that exact content into `hello_world.md`.
5. Use the Bash tool to run `.claude/bin/rostrum-hello-world-state.sh next hello_moon`.
6. Immediately invoke the hidden `rostrum-hello-moon` skill so phase two can request its content.
7. Reply with one short sentence stating that phase one content was written.
