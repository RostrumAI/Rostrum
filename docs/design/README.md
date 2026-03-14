# Rostrum Design Docs

This directory defines the initial Rostrum product architecture for workflow packaging, client adapters, and marketplace distribution.

## Reading order

1. [CLI Architecture](./cli-architecture.md)
2. [Playbook Package Specification](./playbook-package-spec.md)
3. [Marketplace, Install, and Security](./marketplace-install-security.md)
4. Client adapters:
   - [Claude Code](./clients/claude-code.md)
   - [OpenCode](./clients/opencode.md)
   - [Gemini CLI](./clients/gemini-cli.md)
   - [Codex CLI](./clients/codex-cli.md)
   - [Pi Coding Agent](./clients/pi-coding-agent.md)

## Core decisions

- Rostrum owns workflow state.
- A `Playbook` is portable, but execution is adapter-specific.
- Clients are execution surfaces, not sources of truth.
- Support quality is explicit:
  - `managed`
  - `controller-driven`
  - `cooperative`
  - `experimental`
- Marketplace installation is safe by default, with explicit approval for anything that would otherwise become remote code execution.
