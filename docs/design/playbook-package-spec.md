# Rostrum Playbook Package Specification

## Purpose

A Rostrum `Playbook` is a portable package that describes reusable agent workflows across multiple clients while leaving session control to client adapters.

The package format must make these concerns explicit:

- setup requirements
- phase ordering
- completion contracts
- client adapter mappings
- marketplace metadata
- security declarations

## Package structure

```text
review-playbook/
  rostrum.playbook.toml
  prompts/
    010-review.md
    020-fix-findings.md
    030-review-again.md
  assets/
  templates/
  adapters/
    claude-code/
    opencode/
    gemini-cli/
    codex-cli/
    pi-coding-agent/
  tests/
  docs/
```

`rostrum.playbook.toml` is required. Everything else is optional unless referenced by the manifest.

## Manifest sections

### `[playbook]`

Identity and packaging metadata:

- `id`
- `version`
- `title`
- `summary`
- `description`
- `publisher`
- `license`
- `homepage`
- `repository`

### `[marketplace]`

Registry-facing metadata:

- `categories`
- `tags`
- `icon`
- `readme`
- `visibility`
- `support_contact`

### `[requirements]`

Playbook requirements that Rostrum must validate before a run starts:

- binaries
- minimum client versions
- supported operating systems
- required environment variables
- optional services

### `[[setup.actions]]`

Declarative, permissioned setup actions executed through Rostrum, not arbitrary post-install hooks.

Supported action types should be narrowly typed:

- `install_binary`
- `install_package_manager_dependency`
- `write_file`
- `patch_file`
- `register_mcp_server`
- `register_client_extension`
- `run_verified_script`

Each action declares:

- `id`
- `type`
- `description`
- `when`
- `client_scope`
- `approval_required`
- `rollback`

### `[[phases]]`

Each phase defines:

- `id`
- `title`
- `order`
- `prompt`
- `input_refs`
- `expected_outputs`
- `completion_tool`
- `completion_validation`
- `on_success`
- `on_failure`

### `[state]`

Playbook-level rules for run ownership:

- `owner = "rostrum"`
- `phase_pointer = "central"`
- `session_binding = "adapter_overlay"`
- `resume_policy`

### `[clients.<client-id>]`

Default adapter mapping for a supported client:

- `support_tier`
- `start_trigger`
- `injection_strategy`
- `completion_transport`
- `stop_strategy`
- `requires_custom_extension`
- `notes`

## Example manifest

```toml
[playbook]
id = "rostrum.review-loop"
version = "0.1.0"
title = "Review, Fix, Review Again"
summary = "Three-phase code review workflow for interactive coding agents."
publisher = "rostrum"
license = "MIT"

[marketplace]
categories = ["code-review", "quality"]
tags = ["review", "workflow", "agents"]
visibility = "public"

[requirements]
binaries = ["git"]
supported_clients = ["claude-code", "opencode", "gemini-cli", "codex-cli", "pi-coding-agent"]

[[setup.actions]]
id = "install-playwright-cli"
type = "install_package_manager_dependency"
description = "Install playwright-cli when the selected adapter depends on browser automation diagnostics."
client_scope = ["claude-code", "gemini-cli"]
approval_required = true

[[phases]]
id = "010-review"
title = "Review code"
order = 10
prompt = "prompts/010-review.md"
expected_outputs = ["review-findings.json"]
completion_tool = "rostrum_complete_phase"
completion_validation = "require_review_findings_receipt"
on_success = "020-fix-review-findings"

[[phases]]
id = "020-fix-review-findings"
title = "Fix review findings"
order = 20
prompt = "prompts/020-fix-findings.md"
input_refs = ["phase:010-review:review-findings.json"]
expected_outputs = ["change-summary.md"]
completion_tool = "rostrum_complete_phase"
completion_validation = "require_workspace_diff"
on_success = "030-review-again"

[[phases]]
id = "030-review-again"
title = "Review code again"
order = 30
prompt = "prompts/030-review-again.md"
input_refs = ["phase:020-fix-review-findings:change-summary.md"]
expected_outputs = ["final-review.md"]
completion_tool = "rostrum_complete_phase"
completion_validation = "require_final_review_receipt"
on_success = "complete"

[state]
owner = "rostrum"
phase_pointer = "central"
session_binding = "adapter_overlay"
resume_policy = "resume-or-rebind"

[clients.claude-code]
support_tier = "managed"
start_trigger = "/rostrum:review"
injection_strategy = "hook_payload"
completion_transport = "mcp_tool"
stop_strategy = "hook_stop"
requires_custom_extension = false

[clients.opencode]
support_tier = "controller-driven"
start_trigger = "rostrum opencode start"
injection_strategy = "session_api_message"
completion_transport = "mcp_tool"
stop_strategy = "server_side_control"
requires_custom_extension = true

[clients.gemini-cli]
support_tier = "managed"
start_trigger = "/rostrum:review"
injection_strategy = "extension_hook"
completion_transport = "mcp_tool"
stop_strategy = "extension_stop"
requires_custom_extension = true

[clients.codex-cli]
support_tier = "cooperative"
start_trigger = "/rostrum:review"
injection_strategy = "instruction_refresh"
completion_transport = "mcp_tool"
stop_strategy = "operator_visible"
requires_custom_extension = false

[clients.pi-coding-agent]
support_tier = "experimental"
start_trigger = "/rostrum:review"
injection_strategy = "extension_event"
completion_transport = "mcp_tool"
stop_strategy = "rpc_or_extension"
requires_custom_extension = true
```

## Phase model

Playbooks should support both linear and graph-linked progression, but launch should optimize for ordered phases.

Rules:

- every phase has a stable ID
- phase transitions are explicit
- completion is tool-driven whenever possible
- playbook authors can define validation gates between phases

## Adapter bindings

The manifest must not embed client-specific state. It may define adapter rules, but runtime values live outside the package.

Allowed adapter-specific configuration:

- prompt framing templates
- hook registration hints
- command aliases
- extension asset references
- completion transport selection

Forbidden adapter-specific configuration:

- live session IDs
- mutable phase pointers
- hidden state carried only in prompts

## Setup model

Setup actions are package data, not free-form code. A playbook can request one of three security levels:

- `declarative-only`
  - typed actions only
- `verified-script`
  - scripts allowed only if signed, hashed, and reviewed by Rostrum
- `unsafe-local`
  - local unpublished development playbooks only

Marketplace distribution should reject `unsafe-local`.

## Playbook Creation UX

`rostrum create playbook` should:

1. Ask for workflow name, summary, and client list.
2. Generate a linear or graph template.
3. Generate prompt files and example completion rules.
4. Ask whether setup actions are required.
5. Offer marketplace metadata scaffolding.

`rostrum create playbook --from review-loop` should create a minimal starter with:

- three phases
- example review prompt structure
- adapter mappings for all launch clients
- placeholder validation rules

## Validation

`rostrum validate` should reject:

- missing prompt files
- duplicate phase IDs
- unreachable phases
- transitions to unknown phases
- setup actions without approval metadata
- client mappings that promise unsupported enforcement levels

## Packaging

`rostrum pack` produces:

- playbook artifact tarball
- manifest digest
- signature bundle
- optional provenance statement

The package must be content-addressable so setup receipts and review approvals remain stable across reinstalls.
