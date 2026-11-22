# DSH-FN 文档

- [架构](architecture.md) —— 唯一主机（飞牛 fnOS）、fnconnect 登录与连接链路、与上游 dsh-go 的差异。
- [用户指南](guide/README.md) —— 上游 dsh-go 的用户指南（保留作参考；其中"手机本地运行 DSH / SSH / 中继 / 鸿蒙 / iOS"相关章节在 DSH-FN 中不适用）。
- 仓库根目录 [README](../README.md) —— 安装、前置条件、构建。

## 关键事实速查

- 输入：飞牛 **fnconnect ID**（如 `mynas`），App 拼成 `https://<id>.fnos.net`。
- DSH 位置：飞牛统一网关 `/app/deepseek-harness/fngateway`（HTTP 与 WebSocket 同前缀）。
- 认证：首次用 WebView 登录飞牛账号一次，会话 Cookie 存 Android Keystore；DSH 会话由 deepseek.harness 应用在网关侧代持。
- 构建：`cd app && flutter pub get && flutter build apk --release`。
