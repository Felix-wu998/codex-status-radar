# Directory Structure

## Goal

Keep code, reusable logic, experiments, and non-code project material separate so the repository can grow without becoming a whiteboard dump.

## Root Structure

```text
codex-status-radar/
  apps/
  packages/
  prototypes/
  docs/
  scripts/
  assets/
  README.md
  AGENTS.md
  .gitignore
```

## Rules

### `apps/`

Production applications only. The first production target will be `apps/macos`.

### `packages/`

Reusable code shared by apps or tests. The first package will be `packages/core`, covering Codex app-server protocol models, approval request mapping, and privacy-safe state models.

### `prototypes/`

Reproducible experiments. Prototype code can be rough, but each prototype needs a README explaining:

- What it proves.
- How to run it.
- What result was observed.
- Whether it should be promoted or discarded.

### `docs/`

Non-code material that should remain with the GitHub repository:

- Product requirements.
- Architecture notes.
- Research summaries.
- Decision records.

### Obsidian

Full process notes stay in:

`/Users/wuzhentian/Develop/Obsidian/10-项目/Codex状态雷达/`

Obsidian is the work journal. GitHub `docs/` is the cleaned project knowledge base.
