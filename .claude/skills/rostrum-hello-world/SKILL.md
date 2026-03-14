---
name: rostrum-hello-world
description: Run Rostrum's two-phase hello-world sample playbook
context: fork
disable-model-invocation: true
allowed-tools: Bash
---

Run Rostrum's sample two-phase playbook in this repository.

Execution contract:

1. Use the Bash tool to run `.claude/bin/rostrum-hello-world-state.sh prepare`.
2. Use the Bash tool to run `.claude/bin/rostrum-hello-world-state.sh start`.
3. Use the Bash tool to run `.claude/bin/rostrum-hello-world-state.sh await-user hello_world`.
4. Ask the user what exact Markdown content should be written into `hello_world.md`.
5. Tell the user to reply with the exact file content in their next message.
6. Stop after the request. Do not create either file yourself.
