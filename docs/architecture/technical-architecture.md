# 技术架构

## 产品边界

Codex Status Radar 是一个本地优先的 macOS Codex 伴随工具。它不替代 Codex，也不接管 Codex 的主流程。它观察本地 Codex app-server 状态，在灵动岛区域展示状态灯，并在 Codex 等待审批时从同一个灵动岛 surface 内部展开审批交互。

产品主体是灵动岛交互和状态灯。菜单栏图标只表示应用已打开，并提供设置、诊断和退出入口。

## 架构目标

- 精准识别 Codex app-server 的 `waitingOnApproval`。
- 保留 Codex 在 `availableDecisions` 中返回的原生审批决策。
- 默认不展示敏感命令正文。
- 不上传源码、对话、命令、diff、完整路径、文件名、token 或 secret。
- 把协议解析、状态归约、隐私处理放在 core 层，把 macOS 展示放在 app 层。
- 后续可以接入匿名产品遥测，但遥测不能成为核心功能路径的一部分。

## 组件划分

```text
Codex app-server
  |
  | 本地 WebSocket
  v
apps/macos
  CodexAppServerClient        连接 app-server
  ApprovalRequestController   管理审批请求
  NotchStatusController       管理灵动岛窗口承载
  DynamicIslandSurfaceView    渲染状态和审批 surface
  MenuBarController           管理菜单栏图标
  SettingsController          管理设置
  |
  v
packages/core
  app-server 协议模型
  审批决策映射
  线程状态归约
  隐私脱敏规则
  总结视图模型
```

## `packages/core` 职责

`packages/core` 是纯 Swift 逻辑层，不依赖 AppKit。

职责：

- 解码 app-server 事件。
- 把 app-server 事件转成本地状态。
- 把 `availableDecisions` 映射成灵动岛按钮模型。
- 在内容进入 UI 或遥测前做隐私脱敏。
- 提供稳定的单元测试。

当前已有：

- `ApprovalDecision.swift`：解码 Codex 审批决策。
- `ApprovalRequestViewModel.swift`：把审批决策映射成 UI action。
- `AppServerEnvelope.swift`：解码 app-server 事件外壳。
- `ThreadStatus.swift`：定义本地状态。
- `CodexEventReducer.swift`：把事件归约成状态。
- `PrivacyRedactor.swift`：负责项目名、路径、遥测字段脱敏。

## `apps/macos` 职责

`apps/macos` 是生产 macOS 应用。

职责：

- 管理应用生命周期。
- 显示菜单栏图标。
- 连接本地 Codex app-server。
- 展示灵动岛状态灯。
- 在同一个灵动岛 surface 内部展开审批交互。
- 把用户选择的原始 decision 发回 Codex app-server。
- 提供隐私、遥测、连接设置。

当前旁路 observer 连接已验证能稳定收到 `waitingOnApproval`，但真实审批三按钮 `requestApproval` 未证明会广播给旁路客户端。直接审批能力需要后续单独突破请求路由；在此之前，生产路径必须保留紧凑等待提醒作为可靠降级。

app 层必须依赖 `CodexStatusRadarCore`，不要重复写协议解析逻辑。

## 数据流

1. macOS 应用启动，菜单栏图标出现。
2. 应用连接配置好的本地 Codex app-server WebSocket。
3. `CodexAppServerClient` 接收 JSON 事件。
4. core 层解码 app-server event。
5. `CodexEventReducer` 把事件归约成本地项目状态。
6. `NotchStatusController` 把状态投递给单一 `DynamicIslandSurfaceView`：
   - 未连接。
   - 空闲。
   - 工作中。
   - 等待用户输入。
   - 等待审批。
   - 已完成。
   - 错误。
7. 审批请求到达时，core 层生成 `ApprovalRequestViewModel`。
8. 灵动岛审批 surface 按 `availableDecisions` 顺序展示按钮。
9. 用户点击后，app 层把原始 decision payload 原样发回 app-server。
10. app-server resolve 后，UI 回到状态灯模式。

## 审批交互原则

审批 UI 不能伪造固定选项，必须渲染 Codex 返回的 `availableDecisions`。

真实观测过的 decision：

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

当前映射：

| 协议 decision | 灵动岛按钮 | 含义 |
| --- | --- | --- |
| `accept` | `批准一次` | 只批准本次请求。 |
| `acceptForSession` | `本次会话批准` | 当前会话内批准。 |
| `acceptWithExecpolicyAmendment` | `本次会话批准` + `允许类似命令` | 批准并允许 proposed exec-policy amendment。 |
| `applyNetworkPolicyAmendment` | `本次会话批准` + `允许网络规则` | 批准并应用 proposed network rule。 |
| `decline` | `拒绝` | 拒绝请求。 |
| `cancel` | `拒绝` + `取消本次请求` | 取消当前请求。 |

关键要求：**原始 decision payload 必须保留，回传时不能改写。**

## 隐私架构

默认不上传：

- 源代码。
- 对话文本。
- 命令正文。
- diff。
- 完整项目路径。
- 文件名。
- token、secret、auth 文件或环境变量。

本地 UI 默认：

- 展示项目 / 仓库名，不展示完整路径。
- 默认隐藏命令详情。
- 用户可以在本地展开查看，但不上传。
- 总结只列项目 / 仓库，不列具体文件路径。

遥测边界：

- 默认关闭。
- 只能是匿名产品级事件。
- 可以记录 app 版本、macOS 大版本、功能开关、粗粒度耗时桶、匿名事件名。
- 不能记录源码、prompt、命令、文件名、完整路径、repo remote、token 或原始 app-server payload。

## app-server 连接策略

MVP 阶段只做 attach 模式：连接已经运行的本地 Codex app-server。

原因：

- 不改动用户 Codex 运行方式。
- 更容易复用已验证的 spike。
- 避免一开始就引入进程管理复杂度。

后续再考虑 managed startup：由应用启动 `codex app-server`。这必须等 attach 模式和审批流稳定后再做。

## 状态模型草案

```swift
struct ProjectStatus {
    let projectName: String
    let threadId: String?
    let phase: CodexPhase
    let pendingApproval: ApprovalRequestViewModel?
}

enum CodexPhase {
    case disconnected
    case idle
    case working
    case waitingForInput
    case waitingForApproval
    case completed
    case failed
}
```

状态归约由 core 层负责。UI 只读取状态并渲染，不直接解析原始 app-server payload。

## 测试策略

core 层：

```bash
swift test --disable-sandbox
```

必须覆盖：

- 真实 app-server payload 解码。
- 审批 decision 原样保留。
- 事件到状态的归约。
- 隐私脱敏规则。

prototype 层：

```bash
node --check prototypes/app-server-approval/app-server-approval-spike.mjs
```

macOS app 层：

- 构建验证：`swift build --disable-sandbox`。
- 本地灵动岛审批 demo：`scripts/run-macos-app.sh --demo-approval`。
- 手动验证：菜单栏图标、灵动岛窗口位置、审批 surface、点击后的状态切换。
- 后续稳定后再补 UI 自动化。

## 发布前门槛

- `swift test --disable-sandbox` 通过。
- `swift build --disable-sandbox` 通过。
- 真实 Codex app-server 审批流验证通过。
- 隐私和遥测设置有明确文档。
- 许可证检查点已处理。
- README 包含安装、运行、隐私和故障排查。
