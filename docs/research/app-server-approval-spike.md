# app-server 审批链路验证

## 结论

已在本地验证：Codex app-server 可以提供本产品需要的精准 `waiting-approval` 信号。

已观测到的事件：

- `thread/status/changed`
- `activeFlags: ["waitingOnApproval"]`
- `item/commandExecution/requestApproval`
- `availableDecisions`
- `serverRequest/resolved`

关键边界：

- 发起审批请求的连接可以收到 `item/commandExecution/requestApproval` 和 `availableDecisions`。
- 被动订阅连接通过 `thread/loaded/list` + `thread/resume` 可以看到已加载线程的 `thread/status/changed` 和 `waitingOnApproval`。
- 当前实测中，审批请求体不保证广播给被动订阅连接。因此 MVP 要把能力拆开：
  - 通过 `waitingOnApproval` 做精准刘海提醒。
  - 只有实际收到 `item/commandExecution/requestApproval` 时，才展示可点击的原生审批按钮。

## 可复现文件

- `prototypes/app-server-approval/app-server-approval-spike.mjs`
- `prototypes/app-server-approval/notch-approval-mock.html`
- `scripts/run-live-approval-smoke.sh`

## 运行方式

使用临时 Codex home，避免 spike 写入真实会话：

```bash
rm -rf /tmp/codex-status-radar-home
mkdir -p /tmp/codex-status-radar-home
cp ~/.codex/auth.json /tmp/codex-status-radar-home/auth.json
cp ~/.codex/config.toml /tmp/codex-status-radar-home/config.toml
CODEX_HOME=/tmp/codex-status-radar-home codex app-server --listen ws://127.0.0.1:8794
```

运行 spike：

```bash
CODEX_APP_SERVER_PORT=8794 node prototypes/app-server-approval/app-server-approval-spike.mjs
```

运行 macOS app 真实链路烟测：

```bash
scripts/run-live-approval-smoke.sh
```

清理临时目录：

```bash
rm -rf /tmp/codex-status-radar-home
```

## 重要发现

`availableDecisions` 不保证固定为 `accept`、`acceptForSession`、`decline`。

一次已观测到的命令审批返回：

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

产品含义：UI 应保留 Codex 原生的三选项审批体验，但不能写死选项，必须渲染并回传 `availableDecisions` 中的原始 protocol decision。
