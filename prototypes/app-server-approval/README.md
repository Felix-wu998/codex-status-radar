# app-server 审批原型

这个原型用于验证 Codex app-server 审批链路，并提供一个本地刘海审批 mock。

## 文件

- `app-server-approval-spike.mjs`：连接 Codex app-server，创建线程，触发命令审批请求，捕获 `waitingOnApproval`，并拒绝测试命令。
- `notch-approval-mock.html`：本地 HTML 刘海审批弹窗 mock。

## 运行

在仓库根目录执行：

```bash
rm -rf /tmp/codex-status-radar-home
mkdir -p /tmp/codex-status-radar-home
cp ~/.codex/auth.json /tmp/codex-status-radar-home/auth.json
cp ~/.codex/config.toml /tmp/codex-status-radar-home/config.toml
CODEX_HOME=/tmp/codex-status-radar-home codex app-server --listen ws://127.0.0.1:8794
```

另开一个终端执行：

```bash
CODEX_APP_SERVER_PORT=8794 node prototypes/app-server-approval/app-server-approval-spike.mjs
```

打开 mock：

```bash
open prototypes/app-server-approval/notch-approval-mock.html
```

## 安全边界

脚本会拒绝捕获到的审批请求，正常情况下不应创建 `/tmp/codex-status-radar-approval-test.txt`。
