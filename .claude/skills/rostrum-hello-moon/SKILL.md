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
2. Confirm the active phase is `hello_moon`. If it is not, stop and explain why.
3. Use the Bash tool to create `hello_moon.md` in the repository root with exactly this content:

   ```markdown
   # Hello Moon

   Phase two of the Rostrum hello-world playbook completed successfully.
   ```

4. Use the Bash tool to run `.claude/bin/rostrum-hello-world-state.sh finish`.
5. Reply with one short sentence stating that the hidden phase finished.
