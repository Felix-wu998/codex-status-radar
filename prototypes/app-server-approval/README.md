# App-Server Approval Prototype

This prototype verifies the Codex app-server approval flow and provides a local notch approval mock.

## Files

- `app-server-approval-spike.mjs` - connects to Codex app-server, starts a thread, triggers a command approval request, captures `waitingOnApproval`, and declines the test command.
- `notch-approval-mock.html` - local HTML mock for the notch approval popup.

## Run

From repository root:

```bash
rm -rf /tmp/codex-status-radar-home
mkdir -p /tmp/codex-status-radar-home
cp ~/.codex/auth.json /tmp/codex-status-radar-home/auth.json
cp ~/.codex/config.toml /tmp/codex-status-radar-home/config.toml
CODEX_HOME=/tmp/codex-status-radar-home codex app-server --listen ws://127.0.0.1:8794
```

In another terminal:

```bash
CODEX_APP_SERVER_PORT=8794 node prototypes/app-server-approval/app-server-approval-spike.mjs
```

Open the mock:

```bash
open prototypes/app-server-approval/notch-approval-mock.html
```

## Safety

The script declines the captured approval request. It should not create `/tmp/codex-status-radar-approval-test.txt`.
