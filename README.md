# Codex Status Radar

Codex Status Radar 是一个本地优先的 macOS 工具，面向高频使用 Codex 的用户。它的核心产品形态是 Mac 灵动岛交互和状态灯，用来提示 Codex 当前是运行中、等待输入、等待审批、已完成还是异常。

第一阶段聚焦两件事：

- 通过 Codex app-server 精准检测 `waiting-approval`。
- 在灵动岛 surface 内部展开符合 Codex 原生 decision model 的审批交互。

## 当前状态

本仓库处于技术验证和 MVP 初始实现阶段，已经建立 Swift core package。

已本地验证：

- Codex app-server 会发出 `thread/status/changed`。
- `activeFlags` 中可以出现 `waitingOnApproval`。
- 发起审批请求的 app-server 连接会收到 `item/commandExecution/requestApproval`。
- approval request 中包含 `availableDecisions`，但该请求体不保证广播给被动订阅的连接。
- 被动订阅连接可以通过 `thread/loaded/list` + `thread/resume` 观察到已加载线程的 `waitingOnApproval` 状态。
- 本地灵动岛审批 surface 可以展示三个审批选项。
- `CodexStatusRadarCore` 可以解码已观测到的 approval decision，并映射成隐私安全的灵动岛 action。
- macOS app shell 已经具备菜单栏入口、顶部状态灯窗口、本地审批 demo surface 和真实 waiting-approval 灵动岛提醒。

## 仓库结构

```text
apps/
  macos/                 生产 macOS 应用代码。
packages/
  core/                  共享协议、解析、状态和 view model 逻辑。
prototypes/
  app-server-approval/   可复现的 approval-flow 技术验证。
docs/
  architecture/          技术架构和目录决策。
  decisions/             ADR 风格的稳定决策记录。
  product/               PRD、范围、隐私和产品要求。
  research/              技术验证、仓库研究和市场笔记。
  superpowers/plans/     可按任务执行的实施计划。
scripts/                 可重复执行的本地开发脚本。
assets/                  产品图片、截图和设计资产。
```

## 隐私边界

核心功能必须本地运行。本产品不得上传源码、对话内容、命令正文、diff、完整项目路径、文件名、token、secret 或认证材料。

开发者侧远程统计只允许匿名产品级事件，必须有文档说明，必须可由用户配置，且默认不应成为核心功能路径。

## 开发入口

继续实现前先读：

- `docs/architecture/technical-architecture.md`
- `docs/superpowers/plans/2026-04-21-macos-mvp.md`

运行 core 测试：

```bash
swift test --disable-sandbox
```

构建 macOS app：

```bash
swift build --disable-sandbox --product CodexStatusRadarApp
```

打开本地灵动岛审批 demo：

```bash
scripts/run-macos-app.sh --demo-approval
```

脚本会生成独立的本地 demo bundle，并强制启动新实例。如果 macOS 的 `open`
在特殊环境下无法打开临时 bundle，脚本会自动退回直接执行模式。

打开本地 mock：

```bash
open prototypes/app-server-approval/notch-approval-mock.html
```

启动 Codex app-server 后运行 approval spike：

```bash
CODEX_APP_SERVER_PORT=8794 node prototypes/app-server-approval/app-server-approval-spike.mjs
```

运行真实 app-server + macOS app 的 waiting-approval 烟测：

```bash
scripts/run-live-approval-smoke.sh
```

完整验证说明见：

- `docs/research/app-server-approval-spike.md`

## 许可证

当前尚未选择最终许可证。首次公开发布前，以及任何借鉴、复制、移植或 fork 第三方项目代码 / UI 文案 / 资产 / 结构前，必须回到：

- `docs/decisions/0002-license-checkpoints.md`

处理许可证和署名边界。
