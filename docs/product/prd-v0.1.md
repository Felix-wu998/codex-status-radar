# PRD v0.1

## 产品定位

Codex Status Radar 是一个面向高频 Codex 工作流的 macOS 本地工具。

## 核心体验

- Mac 灵动岛状态灯。
- 精准识别 `waiting-approval`。
- 在灵动岛区域弹出 Codex 审批提醒。
- 收到 `availableDecisions` 时，按 Codex 原生 decision 渲染审批按钮。
- 展示当前推进和已完成任务的项目 / 仓库级总结，不展示具体文件清单。
- 任务完成后给出总结和结合当前系统时间的结语。

## 第一阶段切片

第一阶段不是完整仪表盘，必须证明：

1. Codex app-server 可以实时发出 `waitingOnApproval`。
2. 被动订阅连接可以通过 `thread/resume` 观察到已加载线程的等待审批状态。
3. 发起审批请求的连接可以捕获审批请求和 `availableDecisions`。
4. 审批 decision 可以安全渲染，默认不展示敏感命令正文。
5. 灵动岛 UI 可以在没有审批请求体时弹出提醒，在有审批请求体时展示原生审批按钮。

## 第一阶段不做

- 完整替代 Codex 客户端。
- 团队协作。
- 云同步。
- 后台自动审批规则引擎。
- 文件级变更清单。
- 上传代码、命令正文、diff、文件名、完整路径或对话内容。
