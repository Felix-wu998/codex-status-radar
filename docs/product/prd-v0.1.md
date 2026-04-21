# PRD v0.1

## Product

Codex Status Radar is a macOS local utility for Codex-heavy workflows.

## Core Experience

- Mac notch status light.
- Precise `waiting-approval` detection.
- Notch popup for Codex approval requests.
- Codex-native approval decisions rendered from `availableDecisions`.
- Project/repository-level summaries.
- Time-aware closing text after task completion.

## First Slice

The first implementation slice is not a full dashboard. It must prove:

1. Codex app-server emits `waitingOnApproval` in real time.
2. Approval requests can be captured.
3. Approval decisions can be rendered safely.
4. The notch UI can show the approval request without showing sensitive command details by default.

## Non-Goals For First Slice

- Full Codex client replacement.
- Team collaboration.
- Cloud sync.
- Background auto-approval rule engine.
- File-level change list.
- Uploading code, command bodies, diffs, filenames, complete paths, or conversation content.
