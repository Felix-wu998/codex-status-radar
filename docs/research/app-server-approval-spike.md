# App-Server Approval Spike

## Result

Verified locally: Codex app-server can provide the precise `waiting-approval` signal needed by this product.

Observed events:

- `thread/status/changed`
- `activeFlags: ["waitingOnApproval"]`
- `item/commandExecution/requestApproval`
- `availableDecisions`
- `serverRequest/resolved`

## Reproducible Files

- `prototypes/app-server-approval/app-server-approval-spike.mjs`
- `prototypes/app-server-approval/notch-approval-mock.html`

## Setup

Use a temporary Codex home so the spike does not write to real sessions:

```bash
rm -rf /tmp/codex-status-radar-home
mkdir -p /tmp/codex-status-radar-home
cp ~/.codex/auth.json /tmp/codex-status-radar-home/auth.json
cp ~/.codex/config.toml /tmp/codex-status-radar-home/config.toml
CODEX_HOME=/tmp/codex-status-radar-home codex app-server --listen ws://127.0.0.1:8794
```

Run the spike:

```bash
CODEX_APP_SERVER_PORT=8794 node prototypes/app-server-approval/app-server-approval-spike.mjs
```

Clean up:

```bash
rm -rf /tmp/codex-status-radar-home
```

## Important Finding

`availableDecisions` is not guaranteed to be fixed as `accept`, `acceptForSession`, `decline`.

One observed command approval returned:

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

Product implication: the UI should preserve the native three-choice approval experience, but render and return the exact protocol decisions from `availableDecisions`.
