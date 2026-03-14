# Rostrum CLI Architecture

## Purpose

The Rostrum CLI is the local control plane for portable agent workflows. It has four jobs:

1. Author flows.
2. Install and initialize flows.
3. Orchestrate ordered multi-phase runs.
4. Bridge local workspaces to client-specific adapters and the hosted Rostrum control plane.

The CLI does not own the agent session UI. It owns run state and exposes commands that adapters call before, during, and after live interactive sessions.

## Design principles

- `Rostrum owns state, clients own interaction.`
- `rostrum next` is the canonical phase handoff primitive.
- All commands must work in `local-only` mode first.
- Hosted mode reuses the same run model and local files, but syncs them to the Rostrum API.
- Human-oriented commands default to readable output; adapter-facing commands default to JSON.

## Primary nouns

- `Flow`: a versioned workflow package.
- `Run`: one execution of a flow against a workspace.
- `Phase`: an ordered or graph-linked step within a run.
- `Adapter`: the client-specific bridge used to inject context and receive completion signals.
- `Session`: the live client conversation or process associated with a run.
- `Setup receipt`: proof that a required install or config patch has already been approved and applied.

## CLI command groups

### Authoring

- `rostrum create flow`
  - Scaffold a new flow package with manifest, prompts, templates, and tests.
- `rostrum create adapter`
  - Scaffold client-specific adapter bindings for a flow when the generic mapping is insufficient.
- `rostrum validate`
  - Validate manifest schema, prompt references, setup actions, and adapter mappings.
- `rostrum pack`
  - Build a signed `.rostrum.tgz` artifact for distribution.
- `rostrum test`
  - Run manifest-level validation, dry-run setup simulation, and adapter contract tests.

### Installation and workspace init

- `rostrum install <publisher>/<flow>`
  - Download a flow artifact from the marketplace or another registry.
- `rostrum init <publisher>/<flow>`
  - Bind an installed flow to the current workspace, prompt for required setup, and create local config.
- `rostrum setup plan`
  - Show pending setup actions and required approvals before anything executes.
- `rostrum setup apply`
  - Execute approved setup actions and write setup receipts.
- `rostrum doctor`
  - Verify binaries, config patches, adapter registrations, and auth state.

### Run orchestration

- `rostrum start <flow>`
  - Create a run, select adapter, resolve workspace bindings, and emit the first phase payload.
- `rostrum next`
  - Return the current or next actionable phase payload for a given run and client session.
- `rostrum complete-phase`
  - Advance a run when a client explicitly reports phase completion.
- `rostrum status`
  - Show run state, session binding, current phase, and pending actions.
- `rostrum abort`
  - Mark a run aborted and propagate stop instructions to the active adapter if possible.
- `rostrum resume`
  - Rebind a run to a current session or recover a stale local process.

### Marketplace and team commands

- `rostrum login`
  - Authenticate to the hosted Rostrum API.
- `rostrum publish`
  - Upload a validated artifact, signature, screenshots, metadata, and security declaration.
- `rostrum search`
  - Search local and remote registries.
- `rostrum update`
  - Update installed flow artifacts and surface any new setup or permission changes.
- `rostrum yank`
  - Remove a published version from install resolution while keeping audit history.

## Local directory model

Rostrum should follow XDG-style paths on Unix-like systems and equivalent platform directories elsewhere.

### User-level state

- `~/.config/rostrum/config.toml`
  - Auth, registry configuration, default client, output preferences.
- `~/.local/share/rostrum/flows/<publisher>/<flow>/<version>/`
  - Installed flow artifacts and unpacked assets.
- `~/.local/state/rostrum/runs/<run-id>/`
  - Durable run state, session bindings, phase receipts, and adapter overlays.
- `~/.cache/rostrum/`
  - Artifact caches, rendered prompt fragments, temporary package downloads.

### Workspace-level state

- `<workspace>/.rostrum/workspace.toml`
  - Flow bindings, chosen client, workspace-specific overrides.
- `<workspace>/.rostrum/runs/<run-id>.json`
  - Optional pointer file for easy repo-local discovery of active runs.

## Run state model

Each run directory stores normalized state plus adapter-specific overlays:

```text
~/.local/state/rostrum/runs/fr_01J.../
  run.json
  next.json
  phases/
    010-review.json
    020-fix-review-findings.json
    030-review-again.json
  sessions/
    claude-code/
      cc_sess_123.json
    codex-cli/
      codex_sess_456.json
  events.ndjson
```

### `run.json`

Canonical run metadata:

- `run_id`
- `flow_id`
- `flow_version`
- `workspace_root`
- `adapter_id`
- `support_tier`
- `current_phase_id`
- `status`
- `created_at`
- `updated_at`
- `hosted_sync`

### `next.json`

This file answers "what happens next?" independently of client implementation:

```json
{
  "run_id": "fr_01J...",
  "current_phase_id": "020-fix-review-findings",
  "next_phase_id": "030-review-again",
  "dispatch_state": "pending",
  "payload_ref": "phases/030-review-again.json",
  "completion_mode": "mcp_tool",
  "continuation_rule": "explicit_complete_phase",
  "updated_at": "2026-03-14T12:00:00Z"
}
```

### Per-client session overlays

Each adapter keeps only execution-surface details that Rostrum itself cannot infer:

- external session ID
- injection strategy in use
- last injected payload hash
- whether the current phase has been acknowledged
- completion signal transport
- stop/continue affordances available for that client

Example:

```json
{
  "run_id": "fr_01J...",
  "client": "codex-cli",
  "session_id": "codex_sess_456",
  "session_locator": {
    "cwd": "/repo",
    "process_id": 82811
  },
  "current_phase_id": "020-fix-review-findings",
  "pending_payload_hash": "sha256:...",
  "injection_state": "shown_to_user",
  "completion_signal": "mcp:rostrum_complete_phase",
  "enforcement_level": "cooperative",
  "updated_at": "2026-03-14T12:00:00Z"
}
```

This split is deliberate:

- `next.json` is universal.
- `sessions/<client>/<session>.json` is adapter-specific.
- Hosted Rostrum can mirror both, but the universal file remains the source of truth.

## `rostrum next`

`rostrum next` is the adapter-facing state transition read. It should be cheap, deterministic, and idempotent.

### Responsibilities

1. Confirm the run exists and is not completed or aborted.
2. Resolve the current or next phase from canonical run state.
3. Render the phase payload for the requested client adapter.
4. Record a dispatch event and adapter overlay update.
5. Return a machine-readable payload and the expected completion contract.

### Interface

```bash
rostrum next \
  --run fr_01J... \
  --client claude-code \
  --session cc_sess_123 \
  --format json
```

Example response:

```json
{
  "run_id": "fr_01J...",
  "phase_id": "020-fix-review-findings",
  "title": "Fix review findings",
  "prompt": "Address the accepted review findings from phase 1...",
  "completion": {
    "mode": "mcp_tool",
    "tool_name": "rostrum_complete_phase"
  },
  "continuation": {
    "next_phase_id": "030-review-again",
    "requires_explicit_ack": true
  },
  "adapter": {
    "client": "claude-code",
    "injection_mode": "hook_payload"
  }
}
```

`rostrum next` must not mutate the phase pointer on its own. Advancement only occurs through `rostrum complete-phase` or an adapter contract that Rostrum explicitly trusts.

## `rostrum complete-phase`

This command is the authoritative write path for progression.

Inputs:

- `run_id`
- `phase_id`
- `client`
- `session`
- optional completion metadata:
  - output summary
  - files changed
  - review findings count
  - verification status

Rules:

- The adapter must be bound to the run.
- The phase must match the run's current phase.
- Advancement can be blocked by validation rules in the flow spec.
- Rostrum writes a phase receipt and updates `run.json` and `next.json`.

## Hosted sync model

Hosted Rostrum should reuse the same state machine with an API mirror:

- local CLI writes first
- API sync happens immediately after durable local write
- if sync fails, the run becomes `dirty` but still resumable

This lets offline local execution continue without losing determinism.

## Authoring workflow

`rostrum create flow` should produce:

```text
my-review-flow/
  rostrum.flow.toml
  prompts/
    010-review.md
    020-fix.md
    030-review-again.md
  templates/
  tests/
    manifest.test.json
```

The scaffolder should ask for:

- flow name and slug
- supported clients
- ordered phase count
- whether the flow is local-only or marketplace-bound
- whether setup includes binaries or config patches

## Initialization workflow

`rostrum init <publisher>/<flow>` should:

1. Resolve the artifact.
2. Show setup plan and requested permissions.
3. Verify signatures and provenance.
4. Install the artifact into user-level flow storage.
5. Write workspace binding to `.rostrum/workspace.toml`.
6. Register client adapter hooks, commands, or extension assets when approved.

## Error handling

Expected failure modes:

- session lost while run is active
- client adapter cannot inject next payload
- required setup receipt missing
- flow version changed during active run
- hosted sync conflict

CLI response rules:

- human mode explains the next operator action
- JSON mode returns stable error codes
- no silent advancement

## Non-goals

- Simulating arbitrary TUI behavior as the primary integration path
- Letting flows mutate run state directly
- Treating all clients as equally enforceable
