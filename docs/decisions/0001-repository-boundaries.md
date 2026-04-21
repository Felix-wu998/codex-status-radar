# 0001 - Repository Boundaries

## Status

Accepted

## Decision

Use `codex-status-radar/` as the future GitHub repository root inside the current local whiteboard workspace.

Keep the whiteboard root for temporary cross-project files. Put all Codex Status Radar code, GitHub-facing docs, prototypes, scripts, and assets inside `codex-status-radar/`.

## Rationale

The previous layout mixed product notes and prototype files directly in the whiteboard workspace. That is not suitable for GitHub.

The new layout makes the boundaries explicit:

- Production code goes under `apps/` and `packages/`.
- Disposable but reproducible experiments go under `prototypes/`.
- Project knowledge that should travel with GitHub goes under `docs/`.
- Full process history remains in Obsidian.

## Consequences

Future work should happen inside `codex-status-radar/`.

Existing prototype files were moved to:

`prototypes/app-server-approval/`
