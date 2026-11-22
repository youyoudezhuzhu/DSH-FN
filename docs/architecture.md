# DSH-FN 架构

DSH-FN 是 dsh-go 的 Android 专用改造版：**只做一件事** —— 通过飞牛 fnconnect ID 连接飞牛 NAS 上的 DeepSeek Harness（DSH）。

## 一页全貌

```text
┌──────────────── 手机 App（Flutter / Android）────────────────┐
│ Dart: ui/ ──Riverpod──> state/ ──DshClient──┐               │
│        │                                    │ HTTPS + WS   │
│        └─ 飞牛登录 WebView（首次一次）        │              │
│           └─ 抓 fnOS 会话 Cookie → 安全存储   │              │
└─────────────────────────────────────────────┼───────────────┘
                                              ▼
                     https://<fnconnect-id>.fnos.net
                       └─ /app/deepseek-harness/fngateway   （飞牛统一网关 + deepseek.harness 应用）
                            └─ DSH（NAS 上 127.0.0.1:2298）
```

- **没有手机本地引擎**：不存在 PRoot / 内置 Linux / 本机 `dsh web`；`app/lib/runtime/` 只剩共享 UI 用的类型接口，没有原生 handler，状态恒为"手机上没有引擎"。
- **没有通用远程链路**：SSH、ds-harness-remote 中继、WebRTC 已删除。
- **唯一主机**：`HostKind.fnos`，`HostRef.isLocal` 恒 false。

## 连接链路（app/lib/fnos/）

| 步骤 | 文件 | 说明 |
|---|---|---|
| 解析输入 | `fnconnect.dart` | `mynas` → `https://mynas.fnos.net`；只接受 https + `<id>.fnos.net`；DSH 挂载路径固定 `/app/deepseek-harness/fngateway` |
| 登录（一次） | `fnos_webview.dart` | WebView 打开飞牛登录页，每秒轮询 Android CookieManager，`probeFnosDsh` 通过后返回 Cookie 串 |
| 探测 | `fnos_auth.dart` | GET 网关路径并带 Cookie；200 且响应不含 `invalid token` 即已登录 |
| 连接 | `fnos_client.dart` | `DshClient.connect(baseUri: dshBaseUri, cookieHeader: cookies, hostHeader: host)` |
| 持久化 | `state/hosts_state.dart` | fnconnect ID 存 SharedPreferences；会话 Cookie 存 Android Keystore（`flutter_secure_storage`） |

`packages/dsh_client` 相比上游新增 `cookieHeader`：把任意整串 Cookie 头（`k=v; k2=v2`）随 HTTP 与 WebSocket 发送，用于飞牛网关鉴权；DSH 自身的会话由 deepseek.harness 应用在网关侧代持。

## 状态层

- `state/hosts_state.dart`：`fnosHostProvider`（配置 + 会话）、`activeHostProvider`（唯一主机）、`hostLabel`。
- `state/connection_state.dart`：`fnosConnectionProvider`（配置 + 会话就绪后自动连接）、`activeConnectionProvider`（全 App 唯一连接入口）、`remoteConnectionProvider(host).notifier.retry()`。
- 冷启动：`ui/shell/root_gate.dart` 读配置 → 未配置/未登录显示 `ui/onboarding/fnos_setup_page.dart` → 已登录自动连接 → 连接失败显示重试/重新登录。

## 与上游 dsh-go 的差异

删除：`runtime/`（PRoot 运行时、引擎补丁、dsh-go-bridge、boot/direct）、`app/lib/runtime/` 实现、Android Kotlin `runtime/`、`app/ohos/`、`app/ios/`、`packages/dsh_remote/`、`packages/dartssh2/`、`app/lib/remote/{ssh,relay,session_backup}/`、本机引擎相关的设置/安全模式/安装/诊断页面、服务端（site/market/services/infra）与插件 SDK。

保留并改造：聊天、会话、模型/插件/设置页、酒馆；`ui/remote/` 重写为"飞牛主机页"；`ui/web/`（网页模式）改为打开飞牛网关上的 DSH 网页版。

依赖手机本地引擎的功能（本机文件/终端、伙伴/宠物、原生插件桥等）在 DSH-FN 中不可用或已移除。
