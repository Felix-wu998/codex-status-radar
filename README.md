# Codex Status Radar

Codex Status Radar is a local-first macOS utility for heavy Codex users. Its core product surface is a Mac notch interaction and status light that shows when Codex is running, waiting for input, waiting for approval, or done.

The first product slice focuses on precise `waiting-approval` detection through Codex app-server and a notch approval interaction that follows Codex's native decision model.

## Current Status

This repository is in technical spike stage, with the first shared Swift core
package now in place.

Verified locally:

- Codex app-server can emit `thread/status/changed` with `activeFlags: ["waitingOnApproval"]`.
- Codex app-server can emit `item/commandExecution/requestApproval`.
- Approval requests include `availableDecisions`.
- A local mock notch approval card can render three approval choices.
- `CodexStatusRadarCore` can decode observed approval decisions and map them to
  privacy-safe notch actions.

## Repository Layout

```text
apps/
  macos/                 Production macOS app code will live here.
packages/
  core/                  Shared protocol, parsing, and view-model logic.
prototypes/
  app-server-approval/   Disposable but reproducible approval-flow spike.
docs/
  architecture/          Technical architecture and directory decisions.
  decisions/             ADR-style product and engineering decisions.
  product/               PRD, scope, privacy, and product requirements.
  research/              Technical and market research notes.
scripts/                 Repeatable local development scripts.
assets/                  Product images, screenshots, and design assets.
```

## Privacy Boundary

Core functionality must run locally. The product must not upload source code, conversation content, command bodies, diffs, complete project paths, filenames, tokens, secrets, or authentication material.

Developer-side telemetry is allowed only as anonymous product-level events, must be documented, and must be user-configurable.

## Development

The current reproducible spike is in `prototypes/app-server-approval`.

Read before continuing implementation:

- `docs/architecture/technical-architecture.md`
- `docs/superpowers/plans/2026-04-21-macos-mvp.md`

Run core tests:

```bash
swift test --disable-sandbox
```

Open the local mock:

```bash
open prototypes/app-server-approval/notch-approval-mock.html
```

Run the app-server approval spike after starting Codex app-server:

```bash
CODEX_APP_SERVER_PORT=8794 node prototypes/app-server-approval/app-server-approval-spike.mjs
```

See `docs/research/app-server-approval-spike.md` for the full setup.

## License

No license has been selected yet. Before the first public release, and whenever
this project borrows from or forks another project, revisit
`docs/decisions/0002-license-checkpoints.md`.
