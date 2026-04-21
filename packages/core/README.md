# Core Package

Shared app logic for Codex Status Radar.

Current scope:

- Decode Codex app-server command approval decisions.
- Preserve the exact protocol decision payload returned by `availableDecisions`.
- Map decisions to a notch-friendly approval action view model.

Planned scope:

- Codex app-server message models.
- Privacy-safe thread and project summaries.
- Unit tests for additional protocol-to-UI mappings.

Run from the repository root:

```bash
swift test --disable-sandbox
```
