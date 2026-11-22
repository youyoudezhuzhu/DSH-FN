# 贡献指南

DSH-FN 是 dsh-go 的 Android 专用改造版，只保留"通过飞牛 fnconnect ID 连接飞牛 NAS 上的 DSH"这一条链路。

## 改动前

1. 先读 [AGENTS.md](AGENTS.md)（硬规则）与 [docs/architecture.md](docs/architecture.md)。
2. 不要恢复已删除的能力：手机本地引擎（PRoot/内置 Linux）、SSH、ds-harness-remote 中继、WebRTC、iOS / 鸿蒙宿主。
3. 连接链路（`app/lib/fnos/` + `app/lib/state/{hosts,connection}_state.dart`）改动时，把 HTTP 与 WebSocket 的挂载前缀、Cookie 头、登录过期重登这三种情况都验证一遍。

## 验证

```bash
(cd app && flutter pub get && flutter analyze && flutter test)
(cd packages/dsh_client && dart pub get && dart analyze && dart test)
python3 app/tool/l10n_merge.py --check   # 改了 l10n/parts 才需要先 merge
cd app/android && ./gradlew :app:compileDebugKotlin   # 改了 Kotlin 才需要
```

- 只接受能通过 `flutter analyze`（0 error）的改动。
- 涉及 WebView 登录/飞牛网关的改动，需要在真机上走通"输入 ID → 登录 → 连接 → 收发消息"。
- 不打印或提交任何飞牛会话 Cookie、API Key、token。

## 提交

- 未经要求不 push、不打 tag、不发布。
- 只暂存明确路径，不用 `git add .` / `git add -A`。
