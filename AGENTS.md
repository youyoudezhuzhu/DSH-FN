# AGENTS.md

DSH-FN 是 [dsh-go](https://github.com/ccch1mneyyy/dsh-go) 的 Android 专用改造版：**只做一件事** —— 通过飞牛 fnconnect ID 连接飞牛 NAS 上的 DeepSeek Harness（DSH）。

## 改造边界（最重要的规则）

- **没有手机本地引擎**：PRoot / 内置 Linux / 本机 DSH 运行时及其安装、安全模式、升级、本机诊断已删除，不要加回来。
- **只有一种远程连接**：飞牛 fnOS（fnconnect ID → `https://<id>.fnos.net` → `/app/deepseek-harness/fngateway`）。不要恢复 SSH、ds-harness-remote 中继、WebRTC。
- **只有一台主机**：`HostKind` 只有 `fnos`；`HostRef.isLocal` 恒为 false。依赖"本机引擎"的能力应当不可用，而不是假装可用。
- 上游的 iOS / 鸿蒙宿主、`runtime/`、`packages/dsh_remote`、`packages/dartssh2` 已删除，不要恢复。

## 仓库布局

```
app/                   Flutter App（Android）
app/lib/fnos/          fnconnect 解析、飞牛登录 WebView、Cookie 读取、DSH 连接
app/lib/state/         hosts_state / connection_state（唯一主机 = 飞牛）
app/lib/runtime/       仅为共享 UI 保留的类型接口层；没有原生 handler，状态恒为"手机上没有引擎"
app/lib/ui/            界面
packages/dsh_client/   DSH Web API 纯 Dart 客户端（相比上游新增 cookieHeader：整串 Cookie 头）
packages/dsh_tavern/   酒馆（纯 Dart）
tooling/               构建脚本（已去掉本地运行时打包）
```

## 命令

```bash
(cd app && flutter pub get && flutter analyze && flutter test)
(cd packages/dsh_client && dart pub get && dart analyze && dart test)
python3 app/tool/l10n_merge.py            # 改 app/lib/l10n/parts/*.arb 后重新生成
tooling/build-apk.sh --build-name <x.y.z> # 构建 APK
```

Flutter 版本：3.47.x / Dart 3.13。Android 构建需要 Android SDK（`ANDROID_HOME`）。

## 连接链路要点

1. `parseFnConnectInput`：只接受 `https` 的 `<id>.fnos.net`（或纯 ID / 带路径完整 URL），默认网关路径 `/app/deepseek-harness/fngateway`。
2. 登录：`FnosLoginPage` 用 WebView 打开飞牛登录页，轮询 Android `CookieManager` 拿到 fnOS 会话 Cookie，`probeFnosDsh` 确认能连到 DSH。
3. 连接：`DshClient.connect(baseUri: dshBaseUri, cookieHeader: <fnOS cookies>)`；`DshConnection` 会把同一个挂载前缀用于 HTTP 与 WebSocket。
4. 持久化：fnconnect ID 存 SharedPreferences，会话 Cookie 存安全存储（Keystore）；登录过期后清会话重登。

## 硬规则

- 界面文案改 `app/lib/l10n/parts/*.arb` 后运行 `python3 app/tool/l10n_merge.py`，不要手改 `lib/l10n/gen/`。
- 不打印、不记录飞牛会话 Cookie 或任何凭据；诊断/日志外发前人工检查。
- 不改 `packages/dsh_client` 的线上契约而不检查客户端所有调用方。
- 未经要求不 commit、不 push、不打 tag、不发布。
- 只暂存明确路径，不用 `git add .` / `git add -A`。
- 先做最短能跑通的：需求没写的防护不加（多层重试、兜底回退、冗余校验、功能开关）。
- 出问题先读真实输出定位根因，不靠加重试掩盖；改一处就重跑确认。

## 验证纪律

- `flutter analyze` 必须 0 error；`flutter test` 中与本次改动相关的测试要跑。
- 连接链路涉及 WebView 登录与飞牛网关，**真机验证优先**：桌面/模拟器结果不能替代"输入 ID → 登录 → 连接 → 收发消息"。
- 修改 Kotlin 原生层后运行 `cd app/android && ./gradlew :app:compileDebugKotlin`。
