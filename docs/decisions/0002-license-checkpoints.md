# 0002 License Checkpoints

## Status

Accepted.

## Context

The project is planned for GitHub, but no final license has been selected yet.
The product may reference notch interaction ideas from projects such as
`vibe-notch` and `claude-island`. A clean-room implementation has different
license obligations from copying code, assets, UI text, or repo structure.

## Decision

Keep the repository without a final license during the earliest private
implementation stage, then revisit licensing at each important milestone and
whenever the project borrows from, ports from, or forks another project.

Required checkpoints:

- Before the first public release.
- Before distributing binaries.
- Before copying code, assets, UI text, or substantial structure from another
  repository.
- Before forking `vibe-notch`, `claude-island`, or another notch utility.
- Before adding third-party telemetry, crash reporting, or paid distribution.

## Implications

- Until a license is added, public GitHub readers do not receive an open-source
  license grant.
- If code is copied from a project, preserve required copyright notices and
  license terms.
- If the project remains clean-room, choose the product license intentionally
  later instead of inheriting accidental obligations.
