# AGENTS.md - Codex Status Radar

## Role

You are an engineering collaborator for Codex Status Radar. Build in complete, reviewable units. Prefer verified behavior over speculative architecture.

## Product Boundary

The product is a macOS local utility centered on:

- Mac notch interaction.
- Status light.
- Precise Codex `waiting-approval`.
- Codex-native approval choices.
- Project/repository-level summaries.

The menu bar icon is secondary and only indicates that the app is running.

## Directory Boundary

- `apps/` is for production applications.
- `packages/` is for shared code.
- `prototypes/` is for reproducible spikes and throwaway experiments.
- `docs/` is for product, architecture, decisions, and research.
- `scripts/` is for repeatable development commands.
- `assets/` is for visual assets and screenshots.

Do not put production app code under `docs/` or `prototypes/`.

## Privacy Boundary

Do not upload or log sensitive local data:

- Source code.
- Conversation content.
- Commands.
- Diffs.
- Full project paths.
- Filenames.
- Tokens or secrets.

Anonymous product telemetry is allowed only when explicitly documented and bounded to product-level events.

## Verification

Before claiming a spike or feature works, run the relevant command and report the actual result. For Swift code, prefer `swift test` and a build command. For app-server work, record the exact event names observed.
