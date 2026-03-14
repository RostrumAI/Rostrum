---
description: Run Rostrum's two-phase hello-world sample playbook
disable-model-invocation: true
---

Run Rostrum's sample two-phase playbook in this repository.

Execution contract:

1. Use the Bash tool to run `.claude/bin/rostrum-hello-world-state.sh start`.
2. Create `hello_world.md` in the repository root.
3. Put a short heading and one sentence in `hello_world.md` saying the first phase completed successfully.
4. After the file exists, use the Bash tool to run `.claude/bin/rostrum-hello-world-state.sh next hello_moon`.
5. Stop after telling the user phase one is complete.
6. Do not create `hello_moon.md` yourself. The stop hook will decide whether the playbook must continue.
