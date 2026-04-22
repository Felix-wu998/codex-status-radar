# 脚本

这里存放可重复执行的本地开发脚本。

不要在脚本中写入密钥。机器相关配置应使用环境变量，或放在本地忽略文件中。

## 可用脚本

- `run-macos-app.sh`：构建并启动本地 macOS app，可加 `--demo-approval` 查看灵动岛审批 demo。
- `run-live-approval-smoke.sh`：启动 app 并触发一次真实 app-server waiting-approval smoke。
- `run-two-client-approval-routing-spike.sh`：启动 actor / observer 双客户端，验证真实审批请求是否会广播给旁路连接。
