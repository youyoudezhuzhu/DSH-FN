# DSH-FN

**DSH-FN** 是一个专门的 Android 客户端：打开 App，输入飞牛 fnconnect 的 ID，就能连接你飞牛 NAS 上运行的 **DeepSeek Harness（DSH）**，在手机上继续用那边的会话、模型、插件和工作区。

> 仓库：<https://github.com/youyoudezhuzhu/DSH-FN>。本项目 fork 自 [ccch1mneyyy/dsh-go](https://github.com/ccch1mneyyy/dsh-go)（AGPL-3.0），并做了大幅裁剪：
> - **删除了"安卓本地运行 DSH"** 的全部能力（PRoot / 内置 Linux / 本机引擎及其安装、安全模式、升级、本机诊断）；
> - **删除了 SSH、ds-harness-remote 中继、WebRTC** 等通用远程链路；
> - **只保留并重做了一种远程连接**：飞牛 fnOS，通过 fnconnect ID 自动连接。
> 聊天、会话、模型/插件设置等界面沿用上游，凡是必须依赖手机本地引擎的能力在 DSH-FN 中不可用。

---

## 前置条件

1. 一台已开启 **fnconnect 远程访问** 的飞牛 fnOS NAS，记下它的 **fnconnect ID**（例如 `mynas`，对应域名 `mynas.fnos.net`）。
2. NAS 上已安装并运行 **DeepSeek Harness** 飞牛应用（应用中心里的 `deepseek.harness`），DSH 服务处于运行状态。
3. 手机能访问互联网。

## 使用

1. 安装 DSH-FN（`flutter build apk` 或 Releases 里的 APK）。
2. 打开 App，输入飞牛 **fnconnect ID**（只填 ID 即可，如 `mynas`；也支持完整域名 `xxx.fnos.net`）。
3. 在弹出的页面里**登录一次飞牛账号**。App 会校验登录态、抓取飞牛会话 Cookie 并保存到 Android Keystore。
4. 之后 App 自动连接 `https://<id>.fnos.net/app/deepseek-harness/fngateway` 上的 DSH，进入聊天界面。
5. 冷启动自动重连；登录过期时 App 会提示重新登录。

## 工作原理

```
手机 App ── HTTPS/WebSocket ──> https://<fnconnect-id>.fnos.net
                                 └─ /app/deepseek-harness/fngateway   （飞牛统一网关）
                                      └─ DSH（deepseek.harness 应用，本机 127.0.0.1:2298）
```

- fnconnect ID → 域名：`<id>.fnos.net`。
- DSH 的 HTTP 与 WebSocket 都带 `/app/deepseek-harness/fngateway` 挂载前缀，由 DSH 客户端自己拼好（含 WS 前缀），网关负责鉴权并把 DSH 会话注入给上游。
- 认证分两层：飞牛统一网关认**飞牛会话 Cookie**（App 首次登录后保存并随请求携带）；DSH 自身的会话由 deepseek.harness 应用在网关侧代持，客户端无需知道 DSH token。
- 没有手机本地引擎、没有 SSH、没有中继；`docs/` 下与旧架构相关的文档已清理。

## 构建

需要 Flutter 3.47.x（Dart 3.13）与 Android SDK。

```bash
cd app
flutter pub get
flutter build apk --release --flavor arm64   # 真机；模拟器用 --flavor x64
# 产物：app/build/app/outputs/flutter-apk/app-arm64-release.apk
```

仓库已包含 Gradle wrapper（`app/android/gradlew`），clone 下来即可构建；需要 Flutter 3.47.7 + Android SDK/NDK（`ANDROID_HOME`）。

仓库内 `tooling/build-apk.sh` 为上游的多 flavor 构建脚本，已去掉本地运行时打包步骤；不想要 companion 资源时可用 `--no-companion`。

## 目录（改造后）

```
app/                Flutter App（Android）
app/lib/fnos/       飞牛 fnconnect 解析、登录 WebView、Cookie 抓取、DSH 连接
app/lib/state/      hosts/connection 状态层（唯一主机 = 飞牛）
app/lib/ui/         界面（chat / sessions / settings / remote / web …）
packages/dsh_client/ DSH Web API 纯 Dart 客户端（新增 cookieHeader 支持）
packages/dsh_tavern/ 酒馆（纯 Dart，保留）
tooling/            构建脚本
```

## 安全与隐私

- 飞牛会话 Cookie 是 bearer 凭据：只写入 Android Keystore（`flutter_secure_storage`），不写日志、不显示明文；"退出登录"会清除 Cookie 与本机配置。
- fnconnect 域名与 DSH 会话都走 HTTPS；App 拒绝明文 `http` 的 fnconnect 输入。
- 请在飞牛账号上开启可用的安全设置（强密码、二次验证）；fnconnect ID 泄露不等于账号泄露，但仍建议不要公开。

## 已知限制

- 只能连接**部署了 deepseek.harness 应用**的飞牛 NAS；DSH 网关路径固定为 `/app/deepseek-harness/fngateway`。
- 依赖飞牛统一网关的登录态；飞牛改动机器登录/网关行为时可能需要更新 App。
- 依赖手机本地引擎的功能（手机操控桥、本机引擎设置、本机文件/终端等）已随本地运行能力一并移除或不提供。
- 仅在 Android 上维护；上游的 iOS / 鸿蒙宿主已删除。
- 测试：保留与远程连接/会话/聊天相关的用例（`app/test`、`packages/dsh_client`）；上游的视觉 golden 测试与只服务本机引擎的测试未随 fork 保留。

## 许可

AGPL-3.0，见 [LICENSE](LICENSE)。上游项目与第三方组件许可见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。


## 更新与隐私

- 应用内更新只查本仓库的 GitHub Releases（`youyoudezhuzhu/DSH-FN`），不会提示上游 dsh-go 的版本，也不走上游镜像/内测通道；APK 资产名 `DSH-FN-<version>-<arm64|x64>.apk`。
- 仓库与源码中不包含任何真实 fnconnect ID；示例统一写作 `mynas`。你在 App 里输入的 ID 只保存在本机（Secure Storage / SharedPreferences）。
- 原版"手机操控"（让 agent 通过无障碍/Shizuku 操作手机）只在本机引擎下可用，本 fork 没有本机引擎，相关 Dart/Kotlin/引导/测试已全部删除；Shizuku 仅保留用于 APK 自更新安装。
