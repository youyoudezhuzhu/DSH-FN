# 安全

## 凭据

- 飞牛会话 Cookie 是 bearer 凭据：只写入 Android Keystore（`flutter_secure_storage`），不写日志、不显示明文；「退出登录」会清除 Cookie 和本机配置。
- DSH 的模型凭据保存在 **NAS 端** 的 DSH 上，DSH-FN 不在手机上持久化 API Key。

## 传输

- 只接受 `https://<fnconnect-id>.fnos.net`；App 拒绝明文 `http` 的 fnconnect 输入。
- HTTP 与 WebSocket 都经飞牛统一网关（含登录态校验），再进入 deepseek.harness 应用。

## 报告问题

发现安全问题请不要公开提交 issue 细节，先私下联系维护者；不要在报告里附带任何真实 Cookie、token 或内网地址。
