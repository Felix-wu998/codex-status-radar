# Codex 审批请求路由验证

日期：2026-04-22

## 结论

当前 macOS app 作为旁路 observer 连接 Codex app-server 时，可以稳定收到 `thread/status/changed` 里的 `waitingOnApproval`，因此可以做精准灵动岛等待提醒。

但同一轮验证中，`item/commandExecution/requestApproval` 服务端请求和三项 `availableDecisions` 只发送给启动 `turn/start` 的客户端。旁路 observer 通过 `thread/loaded/list` 和 `thread/resume` 订阅线程后，没有收到该请求。

2026-04-22 追加双客户端验证：同一个 app-server 同时连接 actor 和 observer。actor 负责 `thread/start` / `turn/start`，observer 只作为旁路连接存在。结果是 observer 收到了 `waitingOnApproval`，但没有收到 `item/commandExecution/requestApproval`；actor 收到了完整审批请求和三项 `availableDecisions`。这进一步证明：等待状态是广播级事件，审批请求本体是发起 turn 的客户端请求。

这意味着：在不改变连接模式前，产品不能承诺“真实 Codex 审批三按钮一定能在灵动岛直接点击”。当前可靠 MVP 是“精准等待审批提醒”；直接审批需要继续寻找审批请求路由入口，或让本产品成为 turn 的发起/承载客户端。

## 已验证现象

验证命令：

```bash
CODEX_SPIKE_CWD=/tmp CODEX_SPIKE_APPROVAL_RESPONSE_DELAY_MS=5000 scripts/run-live-approval-smoke.sh
```

spike 客户端收到：

- `thread/status/changed`，包含 `activeFlags: ["waitingOnApproval"]`。
- `item/commandExecution/requestApproval`。
- `availableDecisions` 三项：`accept`、`acceptWithExecpolicyAmendment`、`cancel`。

macOS app 日志收到：

- `thread/status/changed`。
- `waiting approval observed`。

macOS app 日志没有收到：

- `approval request received`。

## 双客户端路由验证

验证命令：

```bash
CODEX_SPIKE_CWD=/tmp CODEX_SPIKE_APPROVAL_RESPONSE_DELAY_MS=3000 scripts/run-two-client-approval-routing-spike.sh
```

关键输出：

```text
observer SAW_WAITING_ON_APPROVAL
actor SAW_WAITING_ON_APPROVAL
actor APPROVAL_CAPTURED
```

最终摘要：

```json
{
  "result": "pass",
  "expectedRouting": "actor_only",
  "observer": {
    "sawWaitingOnApproval": true,
    "sawApprovalRequest": false
  },
  "actor": {
    "sawWaitingOnApproval": true,
    "sawApprovalRequest": true
  }
}
```

补充现象：

- 刚 `thread/start` 后，observer 对同一个新线程执行 `thread/resume` 会返回 `no rollout found for thread id ...`。
- 即使 resume 失败，observer 仍然能收到 `waitingOnApproval`，说明该状态不是依赖 resume 的私有事件。
- observer 没有收到审批请求本体，说明当前直接审批不能依赖旁路监听。

## 失败实验

曾临时修改 `thread/resume`，加入：

```json
{
  "approvalsReviewer": "user"
}
```

同时把 smoke 断言提高为必须在 app 日志中看到 `approval request received`。

结果：

- 单测可证明 resume payload 可以带该字段。
- 真实 smoke 仍然失败：spike 收到 `requestApproval`，macOS app 仍然没有收到。
- 因此该字段不足以把另一个客户端发起 turn 的审批请求路由到旁路 observer。

该实验改动没有保留在产品代码中。

## 对产品路线的影响

短期可交付：

- 灵动岛精准提示 Codex 进入 waiting-approval。
- 如果协议事件里带 `availableDecisions`，则按原生三项展示按钮。
- 如果旁路连接只拿到 waiting 状态，则展示紧凑等待提醒，让用户回到 Codex 审批。

仍需继续验证：

- Codex 是否存在可注册的独立 approval reviewer 客户端。
- `thread/start` / `turn/start` 是否必须由本产品发起，才能收到服务端审批请求。
- 是否存在 Codex Desktop 插件、hook、或者本地 IPC 能把原生审批请求转给灵动岛。
- open-vibe-island 一类项目是否通过“承载/启动 agent 会话”而不是“旁路监听”实现直接审批。
