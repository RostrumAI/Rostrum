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
3. Use the Bash tool to create `hello_world.md` in the repository root with exactly this content:

   ```markdown
   # Hello World

   Phase one of the Rostrum hello-world playbook completed successfully.
   ```

4. Use the Bash tool to run `.claude/bin/rostrum-hello-world-state.sh next hello_moon`.
5. Immediately invoke the hidden `rostrum-hello-moon` skill so phase two runs automatically in its own forked context.
6. Do not mark the playbook complete yourself. The hidden phase owns completion.
7. After the hidden phase returns, give the user a brief success summary.
