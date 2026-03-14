# Rostrum Marketplace, Install, and Security

## Goal

Rostrum needs a marketplace for discoverable, versioned workflow packages without turning `rostrum install` into disguised remote code execution.

The install model must feel closer to a package manager plus permissioned setup runner than to a traditional `postinstall` script system.

## Package lifecycle

### Author side

1. Author creates a flow package.
2. `rostrum validate` checks manifest and setup declarations.
3. `rostrum pack` builds a signed artifact.
4. `rostrum publish` uploads:
   - artifact
   - manifest
   - readme
   - screenshots
   - support metadata
   - signature and provenance
5. Rostrum scans and classifies the package.

### Consumer side

1. User runs `rostrum search` or browses the marketplace.
2. User runs `rostrum install`.
3. Rostrum downloads artifact and verifies signature, digest, and publisher trust.
4. Rostrum shows a setup plan.
5. User approves or rejects each required setup action.
6. Rostrum applies approved actions and records receipts.
7. User runs `rostrum init` to bind the flow to a workspace.

## Artifact trust model

Each published artifact should carry:

- publisher identity
- artifact digest
- signature
- provenance statement
- declared setup capability level
- reviewed or unreviewed status

Trust levels:

- `official`
  - published by Rostrum or a verified organization
- `verified`
  - signed by a verified publisher and scanned successfully
- `community`
  - signed but not manually reviewed
- `local`
  - unpacked from disk; never treated as marketplace-reviewed

`rostrum install` should display this trust level before any setup runs.

## Security boundary

The key rule is:

`Downloading a flow is safe by default. Executing setup requires explicit, typed approval.`

That implies:

- no implicit `postinstall`
- no arbitrary shell snippets in marketplace manifests
- no network fetches during setup unless declared and approved
- no writes outside approved target scopes without extra consent

## Setup execution model

### Supported action classes

Preferred setup actions are narrow and inspectable:

- install a named package through a known package manager
- write or patch a known config file
- register an MCP server definition
- copy extension assets into a client-specific directory
- run a signed script with declared arguments

### Setup plan preview

`rostrum setup plan` should render:

- action description
- target path
- target client
- required permissions
- whether network access is needed
- whether elevated privileges may be needed
- rollback availability

Example:

```text
Flow: rostrum/review-loop@0.1.0

Pending actions:
1. Install npm package `playwright-cli`
   Scope: user
   Client: gemini-cli
   Network: yes
   Privilege escalation: no
   Reason: browser automation diagnostics

2. Register MCP server `rostrum-control`
   Scope: workspace
   Client: claude-code
   Writes: .claude/mcp.json
   Rollback: yes
```

### Receipts

Every applied action writes a receipt:

```json
{
  "action_id": "install-playwright-cli",
  "artifact_digest": "sha256:...",
  "approved_by": "local-user",
  "approved_at": "2026-03-14T12:00:00Z",
  "executor": "rostrum@0.1.0",
  "result": "applied"
}
```

If the artifact digest changes, Rostrum invalidates the receipt and re-prompts.

## Handling scripts without opening an RCE hole

Some workflows will need more than declarative file operations. Rostrum should support scripts, but only through a controlled path.

### Allowed marketplace script model

Marketplace packages may include `verified-script` actions only if all of the following are true:

1. The script file is inside the artifact.
2. The script hash is recorded in the manifest.
3. The publisher signs the artifact.
4. Rostrum can preview the script path and declared arguments.
5. The user explicitly approves execution.
6. Rostrum runs the script in a constrained runner with:
   - limited working directory
   - explicit environment allowlist
   - no inherited shell profile
   - no extra arguments beyond the manifest declaration

### Disallowed marketplace behavior

- downloading and executing extra scripts at setup time
- manifest-defined inline shell fragments
- mutating unrelated files outside declared targets
- background daemons without explicit declaration

### Local development escape hatch

Unpublished local flows may use `unsafe-local` actions for rapid iteration, but:

- they cannot be published
- receipts are marked untrusted
- the CLI prints a prominent warning

## Workspace initialization

`rostrum init` should not just install the flow. It should bind it to a workspace.

Initialization responsibilities:

- write `.rostrum/workspace.toml`
- apply workspace-scoped setup actions
- register client entrypoints for the selected adapter
- ask whether the sample flow should become the default project workflow

Example workspace binding:

```toml
[workspace]
root = "/repo"
default_flow = "rostrum.review-loop"
default_client = "claude-code"

[flows."rostrum.review-loop"]
version = "0.1.0"
installed_digest = "sha256:..."
setup_profile = "default"
```

## Publishing flow

`rostrum publish` should require:

- passing `rostrum validate`
- artifact signature present
- changelog or release notes
- declared support tiers for each client
- screenshots or diagrams for marketplace presentation
- explicit security level declaration

Registry-side checks:

- schema validation
- malware scan
- path traversal rejection
- forbidden action rejection
- support tier linting

## Download and install flow

Recommended command sequence:

```bash
rostrum install rostrum/review-loop
rostrum setup plan rostrum/review-loop
rostrum setup apply rostrum/review-loop
rostrum init rostrum/review-loop
```

An optional shorthand:

```bash
rostrum init rostrum/review-loop --install
```

This still must show the setup plan before execution.

## Marketplace API model

Minimum registry endpoints:

- `GET /flows`
- `GET /flows/:publisher/:slug`
- `GET /flows/:publisher/:slug/:version`
- `GET /artifacts/:digest`
- `POST /publish`
- `POST /signatures/verify`
- `POST /install/resolve`

The API should expose setup metadata without requiring artifact download so the CLI can preview risk before install.

## Review and reputation

Marketplace UX should surface:

- support tier by client
- setup capability level
- total required approvals
- last verified date
- publisher verification
- community usage and issue rate

This matters because a "review loop" flow that only needs prompt files should not look equally risky to a flow that wants to install binaries and patch multiple configs.

## Recommendation

Use a conservative default:

- marketplace packages are declarative-first
- verified scripts are allowed, but visibly flagged
- arbitrary remote execution is not part of normal install
- all approvals are local, explicit, and receipt-backed
