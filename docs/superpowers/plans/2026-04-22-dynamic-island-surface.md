# 灵动岛 Surface 重构实施计划

> **给后续工程执行者：** 按任务逐项实施，并用复选框维护进度。

**目标：** 把当前顶部独立审批弹窗重构为一个常驻灵动岛 surface，状态和审批都从同一个岛体内部展开。

**架构：** 保留现有 Codex app-server 和 core 状态模型。macOS 层新增单一 SwiftUI surface 与状态 store，`NotchStatusWindowController` 只负责窗口生命周期和状态投递，不再通过替换 content view 制造独立弹窗感。

**技术栈：** Swift Package Manager、SwiftUI、AppKit、XCTest。

---

### 任务 1：Surface 尺寸模型

**文件：**
- 修改：`apps/macos/Sources/CodexStatusRadarApp/NotchLayoutMetrics.swift`
- 修改：`apps/macos/Tests/CodexStatusRadarAppTests/NotchLayoutMetricsTests.swift`

- [x] 写失败测试：窗口容器尺寸必须大于等于关闭态和审批态，审批态高度要明显高于状态灯但仍保持顶部轻量。
- [x] 实现 `windowSize`、`collapsedSize`、`expandedApprovalSize`、`closedHeaderHeight`。
- [x] 跑 `swift test --disable-sandbox --filter NotchLayoutMetricsTests`。

### 任务 2：单一灵动岛 Surface View

**文件：**
- 新建：`apps/macos/Sources/CodexStatusRadarApp/DynamicIslandSurfaceView.swift`
- 修改：`apps/macos/Sources/CodexStatusRadarApp/NotchStatusWindowController.swift`

- [x] 写测试覆盖 surface mode 映射：普通状态进入 collapsed，审批请求进入 approval。
- [x] 新增 `DynamicIslandSurfaceStore` 和 `DynamicIslandSurfaceMode`。
- [x] 新增 `DynamicIslandSurfaceView`：同一个黑色岛体在 collapsed 与 approval 之间切换尺寸，审批内容在 header 下方展开。
- [x] `NotchStatusWindowController` 初始化时只安装一次 hosting view，后续只更新 store。

### 任务 3：交互行为

**文件：**
- 修改：`apps/macos/Sources/CodexStatusRadarApp/NotchStatusWindowController.swift`
- 修改：`apps/macos/Sources/CodexStatusRadarApp/DynamicIslandSurfaceView.swift`

- [x] 状态灯模式不抢焦点、不阻塞鼠标。
- [x] 审批模式开启鼠标交互，但不调用 `NSApp.activate`。
- [x] 审批结束后回到 collapsed 工作状态。

### 任务 4：等待提醒态细化

**文件：**
- 修改：`apps/macos/Sources/CodexStatusRadarApp/DynamicIslandSurfaceView.swift`
- 修改：`apps/macos/Sources/CodexStatusRadarApp/NotchLayoutMetrics.swift`
- 修改：`apps/macos/Tests/CodexStatusRadarAppTests/DynamicIslandSurfaceStoreTests.swift`
- 修改：`apps/macos/Tests/CodexStatusRadarAppTests/NotchLayoutMetricsTests.swift`

- [x] 写失败测试：没有 `availableDecisions` 的审批请求进入 `waitingReminder`，不开放鼠标交互。
- [x] 写失败测试：等待提醒态尺寸介于折叠状态灯和完整审批 surface 之间。
- [x] 实现 `DynamicIslandSurfaceMode.waitingReminder` 和 `waitingReminderSize`。
- [x] 跑 `swift test --disable-sandbox --filter 'NotchLayoutMetricsTests|DynamicIslandSurfaceStoreTests'`。

### 任务 5：验证

**命令：**
- `swift test --disable-sandbox`
- `swift build --disable-sandbox --product CodexStatusRadarApp`
- `scripts/run-macos-app.sh --demo-approval`
- `CODEX_SPIKE_CWD=/tmp CODEX_SPIKE_APPROVAL_RESPONSE_DELAY_MS=5000 scripts/run-live-approval-smoke.sh`
- `git diff --check`
