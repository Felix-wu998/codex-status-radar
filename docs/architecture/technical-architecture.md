# Technical Architecture

## Product Boundary

Codex Status Radar is a local-first macOS companion for Codex. The app does not
replace Codex. It observes Codex app-server state, renders a notch status light,
and surfaces approval requests with the same decision choices Codex provides.

The primary product surface is the notch. The menu bar icon exists only to show
that the app is running and to expose settings or diagnostics.

## Architectural Goals

- Detect `waitingOnApproval` precisely from Codex app-server.
- Preserve Codex-native approval decisions from `availableDecisions`.
- Keep source code, command bodies, diffs, filenames, complete paths, tokens,
  secrets, and conversation content local.
- Keep the first implementation testable without building the full UI.
- Isolate protocol parsing from macOS presentation code.
- Allow optional anonymous product telemetry later without making telemetry part
  of the core product path.

## Component Map

```text
Codex app-server
  |
  | local WebSocket
  v
apps/macos
  CodexAppServerClient
  ApprovalRequestController
  NotchStatusController
  MenuBarController
  SettingsController
  |
  v
packages/core
  AppServer protocol models
  Approval decision mapper
  Thread status reducer
  Privacy redaction rules
  Summary view models
  |
  v
Local UI only
```

## Repository Responsibilities

### `packages/core`

Pure Swift logic with no AppKit dependency.

Responsibilities:

- Decode app-server protocol messages that the app needs.
- Convert app-server events into stable local state.
- Map approval decisions into notch-safe UI actions.
- Redact sensitive fields before they can reach UI summaries or telemetry.
- Provide deterministic unit tests for protocol behavior.

Current files:

- `ApprovalDecision.swift` decodes command approval decision payloads.
- `ApprovalRequestViewModel.swift` maps decisions to user-facing actions.
- `ApprovalDecisionMapperTests.swift` covers observed approval payloads.

Planned files:

- `AppServerEnvelope.swift` for common app-server event envelopes.
- `ThreadStatus.swift` for `activeFlags`, running state, and completion state.
- `CodexEventReducer.swift` for ordered event-to-state reduction.
- `PrivacyRedactor.swift` for local redaction before display or telemetry.

### `apps/macos`

Production macOS app target.

Responsibilities:

- Manage app lifecycle and menu bar presence.
- Connect to a local Codex app-server WebSocket.
- Render the notch status light and approval popover.
- Send selected approval decisions back to Codex app-server.
- Expose privacy, telemetry, and connection settings.

The app should depend on `CodexStatusRadarCore`, not duplicate protocol logic.

### `prototypes`

Disposable but reproducible experiments.

The existing app-server approval spike remains the source of truth for the first
observed approval flow. Prototype code should not be imported into production
without being rewritten behind core tests.

### `docs`

GitHub-readable project knowledge:

- Product requirements.
- Architecture.
- Technical research.
- Decision records.
- Implementation plans.

Obsidian remains the broader work journal.

## Runtime Data Flow

1. The macOS app starts and shows the menu bar icon.
2. The app connects to a configured local Codex app-server endpoint.
3. `CodexAppServerClient` receives WebSocket JSON messages.
4. Core protocol models decode only the event shapes the app understands.
5. `CodexEventReducer` updates local thread/project state.
6. `NotchStatusController` maps state into a small status light:
   - idle
   - working
   - waiting for user input
   - waiting for approval
   - completed
   - error/disconnected
7. When an approval request arrives, `ApprovalRequestController` creates an
   `ApprovalRequestViewModel`.
8. The notch approval UI renders the ordered actions from `availableDecisions`.
9. The selected decision is sent back to app-server unchanged.
10. The UI returns to status-light mode after app-server resolves the request.

## Approval Interaction

The approval UI must not hard-code a fake approval model. It renders the ordered
decisions returned by Codex.

Observed decision example:

```json
[
  "accept",
  {
    "acceptWithExecpolicyAmendment": {
      "execpolicy_amendment": [
        "touch",
        "/tmp/codex-status-radar-approval-test.txt"
      ]
    }
  },
  "cancel"
]
```

Current mapping:

| Protocol decision | Notch action | Meaning |
| --- | --- | --- |
| `accept` | `批准一次` | Approve only this request. |
| `acceptForSession` | `本次会话批准` | Approve for the current session. |
| `acceptWithExecpolicyAmendment` | `本次会话批准` + `允许类似命令` | Approve and allow a proposed exec-policy amendment. |
| `applyNetworkPolicyAmendment` | `本次会话批准` + `允许网络规则` | Approve and apply a proposed network rule. |
| `decline` | `拒绝` | Decline the request. |
| `cancel` | `拒绝` + `取消本次请求` | Cancel the current request. |

The exact decision payload must be retained and sent back unchanged.

## Privacy Architecture

Privacy is enforced as a design boundary, not only a settings copy line.

Never upload:

- Source code.
- Conversation text.
- Command bodies.
- Diffs.
- Complete project paths.
- Filenames.
- Tokens, secrets, auth files, or environment variables.

Local UI default:

- Show project/repository name, not full path.
- Hide command details by default.
- Allow user expansion for local inspection only.
- Summaries list project/repository names, not changed file paths.

Telemetry boundary:

- Telemetry is optional and product-level only.
- It can include app version, macOS major version, feature toggles, coarse
  latency buckets, and anonymous event names.
- It cannot include code, prompts, commands, filenames, full paths, repo remote
  URLs, tokens, or raw app-server payloads.
- Telemetry must be documented and controllable from settings before release.

## App-Server Connection Strategy

MVP strategy: attach to an existing local app-server endpoint first.

Reasons:

- It keeps process ownership simple.
- It allows testing against the known working spike setup.
- It avoids silently changing the user's Codex runtime behavior.

Later strategy: offer managed startup.

Managed startup can launch `codex app-server` from a configured Codex binary, but
only after the attach-only client and approval flow are stable.

## State Model

Core state should be small and UI-oriented:

```swift
struct ProjectStatus {
    let projectName: String
    let threadId: String
    let phase: CodexPhase
    let pendingApproval: ApprovalRequestViewModel?
    let lastUpdatedAt: Date
}

enum CodexPhase {
    case disconnected
    case idle
    case working
    case waitingForInput
    case waitingForApproval
    case completed
    case failed
}
```

The reducer owns state transitions. UI code reads state and renders it; UI code
does not parse raw app-server payloads.

## Testing Strategy

### Core

Core tests run with SwiftPM:

```bash
swift test --disable-sandbox
```

Core tests must cover:

- Protocol decoding for observed app-server payloads.
- Approval decision preservation.
- State reducer behavior.
- Privacy redaction behavior.

### macOS App

macOS app tests should cover:

- View-model rendering decisions.
- App-server client reconnection behavior with local fixture messages.
- Approval response routing.

Manual verification remains required for notch placement and macOS permission
behavior until stable UI automation exists.

### Prototype

Prototype syntax check:

```bash
node --check prototypes/app-server-approval/app-server-approval-spike.mjs
```

The prototype should be rerun after app-server protocol changes.

## Release Gates

Before first public binary:

- `swift test --disable-sandbox` passes.
- Approval flow is verified against real Codex app-server.
- Privacy settings and telemetry settings are documented.
- License checkpoint is resolved.
- README includes install, run, privacy, and troubleshooting sections.
