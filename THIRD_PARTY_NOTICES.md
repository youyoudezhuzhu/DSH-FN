# 第三方声明（Third-Party Notices）

本文件集中列出 dsh-go 复制或改写进源码的第三方代码与素材，以及随 App 一起分发的字体、原生库和 Linux 运行时组件。源文件头用 `SPDX-FileCopyrightText` / `SPDX-License-Identifier` 标记版权与许可，并指向本文件；各项目的派生关系见各条目。

- App 内「设置 › 开源许可」页随 APK 分发同样的声明（`app/lib/ui/common/third_party_licenses.dart`，字体在 `app/lib/ui/settings/font_licenses.dart`）。
- Dart / Flutter 依赖应按 `app/pubspec.lock`（以及本地包的 lock）核对直接与传递依赖；Flutter 从包根 `LICENSE` 收集许可并显示在许可证页。这里不逐包重复，发行前仍须核验实际 APK 的许可资产，不能仅凭依赖声明认定已收录。
- 许可证全文见文末「许可证全文」。
- 本项目自己的许可见 `LICENSE`（AGPL-3.0）；品牌标识和吉祥物美术不属于第三方，也不在 AGPL 授权范围内，见 `ASSETS.md`。

## 一、复制或改写进源码的代码

### Phase（MIT，作者授权）

| 项 | 内容 |
|---|---|
| 项目 | Phase，https://github.com/CikeSeven/phase （基于提交 `c209f6f`） |
| 版权人 | Copyright (c) 2026 CikeSeven |
| 许可 | MIT：作者授权本项目按 MIT 许可使用 |
| 用途 | 手机操控：无障碍读屏与操作、控制浮层，以及「不打扰模式」的特权虚拟屏 |

上游路径前缀为 `android/app/src/main/kotlin/app/xiangyue/phase/`；本仓库路径前缀为 `app/android/app/src/main/kotlin/io/github/ccch1mneyyy/dsh_app/phone/`。

| 本仓库文件 | 上游来源 |
|---|---|
| `a11y/Actuator.kt` | `accessibility/AccessibilityDriver.kt`、`vision/VisualDriver.kt` |
| `a11y/ControlOverlay.kt` | `accessibility/TaskOverlay.kt` |
| `a11y/MainScreenDriver.kt` | `accessibility/AccessibilityDriver.kt` |
| `a11y/PhoneA11yService.kt` | `accessibility/PhaseAccessibilityService.kt` |
| `a11y/ScreenShooter.kt` | `vision/VisualDriver.kt` |
| `background/PrivilegedDisplayCore.kt` | `shizuku/ShizukuDeviceService.kt`、`DisplayTextConnection.kt`、`DisplayTextInput.kt` |
| `background/PrivilegedDisplayEntry.kt` | `shizuku/ShizukuDeviceService.kt` |
| `background/PrivilegedProtocol.kt` | 失败原因码集合 |
| `background/ShizukuStarter.kt` | `shizuku/ShizukuConnection.kt` |
| `app/android/app/src/main/res/xml/phone_accessibility_service.xml` | `accessibility_service.xml` |
| `a11y/ImageObservation.kt` | Phase 的视觉观察与截图路径 |
| `app/android/app/src/main/res/xml-v33/phone_accessibility_service.xml` | `accessibility_service.xml`（API 33 变体） |

声明原文：

```text
Portions of the phone control feature are derived from Phase
(https://github.com/CikeSeven/phase), Copyright (c) 2026 CikeSeven,
used under the MIT License with the author's permission.
```

### go.dshtui.com 首页（作者交付使用）

| 项 | 内容 |
|---|---|
| 作品 | DSH Go 展示网站：HTML、CSS、JavaScript、内容检查与发布脚本、八张功能展示图 |
| 作者 | ClayGao233 / 采云师烧饼（https://github.com/ClayGao233 、https://space.bilibili.com/28879571） |
| 许可 | 作者交付给本项目用于 go.dshtui.com；交付包未附许可证声明，不在本仓库的 AGPL-3.0 授权范围内 |
| 用途 | `https://go.dshtui.com/` 首页 |

本仓库位置：`site/home/`。在交付版本上的改动：产品名统一写作「DSH Go」，填写作者、下载、仓库、贡献者和分享元信息（`dist/site-config.js`），加入页面 CSP、下载二维码、第二个下载链接和 Star 数（`dist/index.html`、`dist/author-ui.js`、`dist/refinements.css` 末尾），统一换行符；没有发布的工作文件（作者说明、备份脚本、未用到的图片）未收入。功能展示图依据 DSH Go 的界面截图制作，含 DSH Go 的品牌图形和鲸娘形象（见 `ASSETS.md`）。页底保留作者的「网页开发」署名。

### PiPilot（MIT）

| 项 | 内容 |
|---|---|
| 项目 | PiPilot，https://github.com/CikeSeven/pi_pilot |
| 版权人 | Copyright (c) 2026 CikeSeven |
| 许可 | MIT |
| 用途 | 聊天界面、通用组件、抽屉外壳与主题的结构和部分实现 |

均在 `app/lib/ui/` 下：

- `chat/`：`chat_header.dart`、`chat_list.dart`、`chat_screen.dart`、`composer.dart`、`model_sheet.dart`
- `chat/render/`：`ansi_text.dart`、`code_block.dart`、`diff_view.dart`、`markdown_body.dart`
- `chat/widgets/`：`approval_card.dart`、`assistant_message.dart`、`question_card.dart`、`thinking_pill.dart`、`tool_row.dart`、`user_bubble.dart`
- `common/`：`app_sheet.dart`、`overscroll_forwarder.dart`、`sheet_navigator.dart`、`status_dot.dart`、`streaming_cursor.dart`、`tool_glyph.dart`
- `settings/`：`diagnostics_page.dart`、`settings_widgets.dart`
- `shell/`：`drawer_drag.dart`、`home_shell.dart`、`sessions_drawer.dart`
- `theme/`：`accent.dart`、`app_theme.dart`、`backdrop.dart`、`highlight_theme.dart`、`motion.dart`、`palette.dart`、`semantic_colors.dart`、`shapes.dart`、`squircle.dart`、`typography.dart`

### DeepSeek Harness（MIT）

| 项 | 内容 |
|---|---|
| 项目 | DeepSeek Harness，https://github.com/deepseek-ai/deepseek-harness |
| 版权人 | Copyright (c) 2026 DeepSeek |
| 许可 | MIT |
| 用途 | 移植官方客户端的若干算法与图形；部分组件的结构与行为参照其 Web 客户端 |

| 本仓库文件 | 上游来源 | 用途 |
|---|---|---|
| `app/lib/ui/chat/secret_mask.dart` | `@deepseek-ai/dsh-client-ui-secret-mask` | 凭据格式、线性匹配与遮挡；眼睛图标 |
| `app/lib/ui/chat/widgets/artifact_card.dart` | `@deepseek-ai/dsh-client-ui-deliverables`（`PresentedFileCard`、`Deliverables`） | 交付文件卡片 |
| `app/lib/state/session_search.dart` | `@deepseek-ai/dsh-client-ui-workspace`（`deriveSearchResults`） | 对话搜索结果合并 |
| `app/lib/ui/features/schedule_editor/cron.dart` | `@deepseek-ai/dsh-client-ui-schedule`（`task-cron.js`） | 定时任务的 cron 解析与中文描述 |
| `app/lib/ui/engine_settings/namespace_copy.dart` | 官方设置页（`dsh-client-ui-settings-*`、`dsh-client-ui-chat`、`dsh-client-ui-conversation` 等）与各包 README 的中文文案 | 引擎设置项的中文文案 |
| `app/lib/ui/common/think_glyph.dart` | `@deepseek-ai/dsh-web-frontend`（`IconThinkOutline`） | 思考图标轮廓 |
| `packages/dsh_client/lib/src/binary_response.dart` | `@deepseek-ai/dsh-client-connection`（`parseBinaryResponse`） | 二进制结果解码 |
| `packages/dsh_client/lib/src/deliverables.dart` | `@deepseek-ai/dsh-client-ui-deliverables`（`isPresentedData`、`isPresentedFile`、`presentedForClosing`） | 交付文件校验与按轮选取 |
| `runtime/patches/route-guard.diff` | `dsh-host-webserver` | 运行时构建时打到 DSH 上的补丁 |
| `runtime/bridge/dsh-go-bridge/PRESET-NOTICE.txt`、`cordis.patch.yml`（shared rows） | `@deepseek-ai/dsh-web-app@0.2.2-rc.1` 的 `presets/standard.patch.yml` | 标准工具集预置的 NOTICE 与拷贝来源 |

此外，App 中部分组件的结构与行为参照 DeepSeek Harness 的 Web 客户端（MIT），包括消息操作、提及、输入区 dock、回合过程、产物、工作区、终端和定时任务等，不逐文件列出。

### DS Bot（Apache-2.0，已修改）

| 项 | 内容 |
|---|---|
| 项目 | DS Bot，https://github.com/Fei2411/DeepSeek-Bot （基于提交 `1bebe82`） |
| 版权人 | Copyright 2026 Fei2411 and the DS Bot contributors |
| 许可 | Apache License 2.0 |
| 用途 | 可交互回复（dsh-ui）的规范化、校验、上限、摘要、选择规则与图表刻度；DS Bot 客户端的配色与默认颜色 |

以下文件均已修改，每个文件第二行起有 `Modified: …` 说明改动：

| 本仓库文件 | 上游来源 |
|---|---|
| `app/lib/ui/chat/dsh_ui/dsh_ui_model.dart` | `ds-bot/src/shared/views.js`（`normalizeView`、校验与上限、`viewSummary`） |
| `app/lib/ui/chat/dsh_ui/dsh_ui_reply.dart` | `ds-bot/src/shared/views.js`（`validateOptions`） |
| `app/lib/ui/chat/dsh_ui/dsh_ui_chart.dart` | `ds-bot/src/client/widget-chart.js`（`niceTicks`、数值轴、提示框） |
| `app/test/chat/dsh_ui/dsh_ui_model_test.dart` | `ds-bot/test/views.test.js` 的用例 |
| `packages/dsh_client/lib/src/dsbot_api.dart` | `src/client/inks.js`（配色表）、`src/client/characters.js`（`fnv1a`、`defaultColor`） |
| `app/android/.../runtime/GuestSetup.kt` | `ds-bot/src/host/tools.js`、`prompt.js`（`show_view` 说明与提示规则） |
| `app/lib/ui/bots/bot_mention.dart` | `ds-bot/src/shared/mentions.js`（「所有人」与地址判定等提及规则） |

DS Bot 的 NOTICE 原文附在文末。

### Libraries.dev（MIT）

| 项 | 内容 |
|---|---|
| 项目 | Libraries.dev，https://github.com/Jakubantalik/Libraries.dev （基于提交 `387b049`） |
| 版权人 | Copyright (c) 2026 Jakub Antalik |
| 许可 | MIT（只用代码；`LICENSE-MODEL.md` 管的模型文件 `Magnet.mfxl`、`VoicePosition.mfxl` 和 Pro 内容都没有用） |
| 用途 | 界面特效：思考光球、边框流光、语音辉光、语音光环、机器人头像等，从作者的 TypeScript / Swift / Metal 源码翻译成 Dart、Flutter 着色器和 Kotlin；手机操控时屏幕边缘的色带取自 Distortion waves（`packages/distortion-waves`）着色器里留在屏幕边缘的那部分颜色（rim）和 `WaveRim.lumps` |

本仓库位置：`app/lib/ui/fx/`（每个文件第一行注明出处）及其 `app/shaders/fx/` 下的着色器；手机操控的边缘色带在 `app/android/app/src/main/kotlin/io/github/ccch1mneyyy/dsh_app/phone/a11y/EdgeBeam.kt`、`EdgeBeamModel.kt`（同样在文件第一行注明出处）。

金属质感的着色器 `app/shaders/fx/metal_liquid.frag` 是 metal-fx 用的 Paper Shaders `liquidMetal`（Apache-2.0，Paper Design, Inc.，`@paper-design/shaders` 0.0.80）的 GLSL 翻译，按 metal-fx 的 NOTICE 原文保留：

```text
This product includes software developed by Paper Design, Inc.

  Paper Shaders (https://github.com/paper-design/shaders)
  Copyright (c) Paper Design, Inc.
  Licensed under the Apache License, Version 2.0
  http://www.apache.org/licenses/LICENSE-2.0

The liquid-metal material in app/shaders/fx/metal_liquid.frag is the
`liquidMetal` fragment stage of @paper-design/shaders 0.0.80, as used by
Libraries.dev metal-fx, translated to Flutter GLSL.
```改动：换成 Flutter 的 CustomPainter / FragmentShader 绘制，默认颜色从 App 主题色取，跟随「减弱动态」，声音电平改用 App 自己的采集数据；桌面专用的鼠标效果没有移植。

### DSHA（MIT）

| 项 | 内容 |
|---|---|
| 项目 | DSHA，https://github.com/DSH-APP/DSHA |
| 版权人 | Copyright (c) 2026 qiannianhuanxiang |
| 许可 | MIT |
| 用途 | 不打扰模式特权进程的 `app_process` 入口 |
| 文件 | `app/android/app/src/main/kotlin/io/github/ccch1mneyyy/dsh_app/phone/background/PrivilegedDisplayEntry.kt` |

### discourse_docker（MIT）

| 项 | 内容 |
|---|---|
| 项目 | discourse_docker，https://github.com/discourse/discourse_docker |
| 版权人 | Copyright (c) 2018 Civilized Discourse Construction Kit, Inc. |
| 许可 | MIT |
| 用途 | 社区论坛的容器配置，基于官方 `samples/standalone.yml` 改写 |
| 文件 | `infra/forum/containers/app.yml`、`infra/forum/containers/app.reverse-proxy.yml` |

### SillyTavern（AGPL-3.0）

| 项 | 内容 |
|---|---|
| 项目 | SillyTavern，https://github.com/SillyTavern/SillyTavern |
| 版本 | 1.19.0，提交 `7e8663cd9c184a550b37238218bdd32c6efc68e9` |
| 许可 | AGPL-3.0（与本项目相同） |
| 版权 | SillyTavern 项目及其贡献者（上游 LICENSE 只有 AGPL-3.0 正文，没有单独的版权行；贡献者见上游仓库的提交记录） |
| 用途 | 酒馆引擎照 SillyTavern 的行为移植或改写：提示词组装、世界书、宏、斜杠命令、正则、角色卡与聊天文件的读写、人设 |
| 来源文件 | `public/script.js`；`public/scripts/` 下的 `PromptManager.js`、`openai.js`、`personas.js`、`world-info.js`、`macros.js`、`slash-commands.js`、`bookmarks.js`；`src/character-card-parser.js`、`src/prompt-converters.js`、`src/endpoints/characters.js`、`src/endpoints/chats.js`、`src/endpoints/backends/chat-completions.js` |
| 文件 | `packages/dsh_tavern/lib/src/` 下文件头写明 SillyTavern 来源和提交的文件 |

酒馆引擎里另有几处移植，许可写在各自的文件头或同目录的许可文件里：Fuse.js 7.1.0（Apache-2.0，`packages/dsh_tavern/lib/src/slash/FUSE-LICENSE.txt`）、json-logic-js（MIT，`packages/dsh_tavern/lib/src/state/JSONLOGIC-LICENSE.txt`）、Unicode 16.0.0 数据（Unicode 许可，`packages/dsh_tavern/lib/src/slash/UNICODE-NAME-LICENSE.txt`）、seedrandom 3.0.5（MIT，David Bau，许可原文在 `packages/dsh_tavern/lib/src/macros/macro_engine.dart`）、Handlebars 4.7.9 与 Moment 2.30.1 的有限行为（各自文件头注明）。

## 二、素材

### Phosphor Icons（MIT）

| 项 | 内容 |
|---|---|
| 项目 | Phosphor Icons 2.1.1，https://phosphoricons.com （`@phosphor-icons/core`） |
| 版权人 | Copyright (c) 2023 Phosphor Icons |
| 许可 | MIT |
| 用途 | 界面图标字体的字形；少数图标按它的网格与轮廓补画 |

- `app/tool/icons/phosphor/`：图标源文件与 LICENSE
- `app/assets/fonts/DshIcons.ttf`、`app/lib/ui/theme/dsh_glyphs.dart`：由 `app/tool/make_icon_font.py` 生成
- `app/android/.../phone/a11y/ControlOverlay.kt`：收起键的路径取自 `arrows-in-simple`

### Material Icons（Apache-2.0）

| 项 | 内容 |
|---|---|
| 项目 | Material Icons，https://github.com/google/material-design-icons |
| 版权人 | Google |
| 许可 | Apache License 2.0 |
| 用途 | 桌面快捷方式与快速设置磁贴的图标；按自适应图标画布缩放、居中 |

均在 `app/android/app/src/main/res/drawable/` 下：`ic_shortcut_chat_glyph.xml`（`chat_bubble_outline_rounded`）、`ic_shortcut_new_chat_glyph.xml`（`add_comment_outlined`）、`ic_shortcut_voice_glyph.xml`（`mic_none_rounded`）、`ic_tile_new_chat.xml`（`add_comment_outlined`）、`ic_pet_mic.xml`（`mic_none_rounded`）、`ic_pet_send.xml`（`arrow_upward_rounded`）。

### discourse-emojis（MIT）

| 项 | 内容 |
|---|---|
| 项目 | discourse-emojis，https://github.com/discourse/discourse-emojis |
| 版权人 | Discourse（gemspec 作者 Joffrey Jaffeux） |
| 许可 | MIT（见其 `discourse-emojis.gemspec`） |
| 用途 | 论坛表情的名称与别名表，只用数据，不含图片 |
| 文件 | `app/lib/forum/emoji_data.g.dart`，由 `infra/forum/tools/gen_emoji_table.py` 从 `dist/emojis.json`、`dist/aliases.json` 生成 |

### jQuery 3.7.1（MIT）

| 项 | 内容 |
|---|---|
| 项目 | jQuery 3.7.1，https://jquery.com （npm 包 `jquery@3.7.1`） |
| 版权人 | Copyright OpenJS Foundation and other contributors, https://openjsf.org/ |
| 许可 | MIT（包内 `LICENSE.txt` 原文） |
| 用途 | 酒馆整页画布里给卡脚本用的 `$`／`jQuery`，和酒馆助手页面一样预先放好；「不运行卡的脚本」开着时不载入 |

- `app/assets/tavern/jquery-3.7.1.min.js`：包内 `dist/jquery.min.js` 原样，SHA256 `fc9a93dd241f6b045cbff0481cf4e1901becd0e12fb45166a8f17f95823f0b1a`
- `app/assets/licenses/jquery-3.7.1-LICENSE.txt`：包内 `LICENSE.txt` 原样，SHA256 `d4db9ebe6f29f5168eac45ad713f055623ac5d0dcd5ba92da23d650ae012020d`
- 来源：npm 镜像 registry.npmmirror.com 的 `jquery-3.7.1.tgz`，与 npm 公布的 integrity `sha512-m4avr8yL8kmFN8psrbFFFmB/If14iN5o9nw/NgnnM+kybDJpRsAynV2BsfpTYrTRysYUdADVD7CkUUizgkpLfg==` 一致（2026-11-12 核对）

### Lodash 4.17.21（MIT）

| 项 | 内容 |
|---|---|
| 项目 | Lodash 4.17.21，https://lodash.com （npm 包 `lodash@4.17.21`） |
| 版权人 | Copyright OpenJS Foundation and other contributors <https://openjsf.org/>；基于 Underscore.js（Jeremy Ashkenas, DocumentCloud and Investigative Reporters & Editors） |
| 许可 | MIT（包内 `LICENSE` 原文，含示例代码 CC0 一节） |
| 用途 | 酒馆整页画布里给卡脚本用的 `_`，同上 |

- `app/assets/tavern/lodash-4.17.21.min.js`：包内 `lodash.min.js` 原样，SHA256 `a9705dfc47c0763380d851ab1801be6f76019f6b67e40e9b873f8b4a0603f7a9`
- `app/assets/licenses/lodash-4.17.21-LICENSE.txt`：包内 `LICENSE` 原样，SHA256 `f71e8ed126b46346494aad5486874cd8f0aafe95092ed67d2e3cb6110f939abc`
- 来源：npm 镜像的 `lodash-4.17.21.tgz`，与 npm 公布的 integrity `sha512-v2kDEe57lecTulaDIuNTPy3Ry4gLGJ6Z1O3vE1krgXZNrsQ+LFTGHVxVjcXPs17LhbZVGedAJv8XZ1tvj5FvSg==` 一致（2026-11-12 核对）

### Zod 4.6.7（MIT）

| 项 | 内容 |
|---|---|
| 项目 | Zod 4.6.7，https://zod.dev （npm 包 `zod@4.6.7`） |
| 版权人 | Copyright (c) 2025 Colin McDonnell |
| 许可 | MIT（包内 `LICENSE` 原文） |
| 用途 | 酒馆整页画布和网页岛里给卡脚本用的全局 `z`，和酒馆助手页面一样预先放好（MVU 的 zod 变量结构、状态栏都要它）；「不运行卡的脚本」开着时不载入 |

- `app/assets/tavern/zod-4.6.7.min.js`：npm 包没有单文件浏览器版，由包内 ESM 打成一个 IIFE。入口 `import * as z from 'zod'; globalThis.z = z;`（整个包，`z.object` 和 `z.z.object` 都在，和酒馆助手一样），命令 `esbuild --bundle --minify --format=iife --target=es2019 --legal-comments=inline --banner:js=…`（esbuild 0.28.2，开头一行注释写明出处和许可）。SHA256 `3320c08ae7b97e5a977aac7ea438f9cb1238020e3a8b3bc7cfde2d1965a4e38a`
- `app/assets/licenses/zod-4.6.7-LICENSE.txt`：包内 `LICENSE` 原样，SHA256 `3f1189b28e3866e0d979968d466b78f813f76827cfdca1fbb124cc0a5c8841f8`
- 来源：registry.npmjs.org 的 `zod-4.6.7.tgz`，与 npm 公布的 integrity `sha512-g8W2D2kU6a8untc053fX1uVBKzM7yqAxW/3zwk83+6RyF2+SKOuV+c0wBDhUwzV1PaGapmZH+rmcUzPf+3CGwg==` 一致（2026-11-20 核对）

### YAML 2.9.1（ISC）

| 项 | 内容 |
|---|---|
| 项目 | yaml 2.9.1，https://eemeli.org/yaml/ （npm 包 `yaml@2.9.1`） |
| 版权人 | Copyright Eemeli Aro <eemeli@gmail.com> |
| 许可 | ISC（包内 `LICENSE` 原文） |
| 用途 | 同上，全局 `YAML`（`YAML.parse`／`YAML.stringify`） |

- `app/assets/tavern/yaml-2.9.1.min.js`：同 Zod 的做法，入口 `import YAML from 'yaml'; globalThis.YAML = YAML;`。SHA256 `ccdebd91f1f455d059da218b7f794aaa794705781740e67e94cd0dba0419df29`
- `app/assets/licenses/yaml-2.9.1-LICENSE.txt`：包内 `LICENSE` 原样，SHA256 `5bba27375d93e9119f76c1015f7672cf9ad5f70952296e0842fb2243d6376869`
- 来源：registry.npmjs.org 的 `yaml-2.9.1.tgz`，与 npm 公布的 integrity `sha512-3NxN8+78OdzbT7C/WjGsyfPAtJaN3FNDsWxv7Y7mcDsT/oOmgW8BpyQQFFBnvZE3j9Y2Sdz1ULFLezL7Eb2yFw==` 一致（2026-11-20 核对）

### JetBrains Mono（SIL OFL 1.1）

| 项 | 内容 |
|---|---|
| 项目 | JetBrains Mono，https://github.com/JetBrains/JetBrainsMono |
| 版权人 | Copyright 2020 The JetBrains Mono Project Authors |
| 许可 | SIL Open Font License 1.1，全文见 `app/assets/fonts/OFL.txt` |
| 用途 | 代码字体，随 App 分发，也注入网页版 |
| 文件 | `app/assets/fonts/JetBrainsMono-*.ttf` |

### Unicode Character Database 15.0.0（Unicode 数据许可）

宠物 ZIP 文件名去重使用从 CPython 3.12 / Unicode 15.0.0 生成的 NFC 与 full casefold 数据表；生成脚本为 `app/tool/generate_pet_validation_data.py`，表为 `app/lib/pets/pet_unicode_data.g.dart`。未复制 CPython 实现代码。

Copyright © 1991-2026 Unicode, Inc.

数据版本来源：https://www.unicode.org/Public/15.0.0/ucd/ReadMe.txt （原始数据通知 © 2022 Unicode®, Inc.）。完整 Unicode 当前许可原文取自 https://www.unicode.org/license.txt ，检索于 2026-11-07；这是当前 V3 通知，不把它冒称为 2022 发布时的许可版本。许可全文原样存于 `app/tool/unicode-15.0-LICENSE.txt`，同字节打包为 `app/assets/licenses/unicode-15.0.txt`，由现有 LicenseRegistry 页面展示。

C710 新增的 `image` 4.12.0 是 MIT 许可 pub 依赖；其原许可由 Flutter 的依赖许可收集流程随包提供。Codex Pet 转换根据公开格式独立实现，不把源码许可当作第三方图集再分发授权。

## 三、随 App 分发的原生库

以下库作为 Gradle 依赖打包进 APK，未复制进源码。

| 库 | 版本 | 许可 | 版权人 | 用途 |
|---|---|---|---|---|
| Shizuku-API（`dev.rikka.shizuku:api`、`provider`） | 13.1.5 | MIT | Copyright (c) 2021 RikkaW | 不打扰模式经 Shizuku 获得 shell 权限 |
| Conscrypt（`org.conscrypt:conscrypt-android`） | 2.8.0 | Apache-2.0 | Copyright 2016 The Android Open Source Project | libadb 的 TLS；NOTICE 原文见文末 |
| Bouncy Castle（`bcprov`、`bcpkix-jdk15to18`） | 1.81 | Bouncy Castle Licence（MIT 条款） | Copyright (c) 2000-2023 The Legion of the Bouncy Castle Inc. | 自签名 ADB 客户端证书 |
| libadb-android | 3.1.1 | Apache-2.0（GPL-3.0-or-later 与 Apache-2.0 双许可，按 Apache-2.0 使用） | Copyright 2021 Muntashir Al-Islam | 无线调试配对、ADB 协议与 mDNS |
| spake2-android（libadb-android 的依赖） | 2.2.1 | LGPL-3.0 | Copyright 2021 Muntashir Al-Islam | 无线调试配对的 SPAKE2 |
| AndroidX WebKit | 1.15.0 | Apache-2.0 | The Android Open Source Project | 网页插件的深色模式 |
| ONNX Runtime（`com.microsoft.onnxruntime:onnxruntime-android`） | 1.27.0 | MIT | Copyright (c) Microsoft Corporation | 语音通话在手机上跑判停模型 |
| Silero VAD v6.2（模型文件 `assets/speech/silero_vad.onnx`） | `be95df9` | MIT | Copyright (c) 2020-present Silero Team | 语音通话判断有没有在说话 |
| smart-turn v3.2（模型文件 `assets/speech/smart-turn-v3.2-cpu.onnx`） | `f766f81` | BSD-2-Clause | Copyright (c) 2024–2025, Daily | 语音通话判断一句话说完没有 |
| sherpa-onnx（pub 包 `sherpa_onnx`、`sherpa_onnx_android_*`） | 1.13.4 | Apache-2.0 | Xiaomi Corporation 与 k2-fsa 贡献者 | 手机上的流式语音识别；它带的 `libonnxruntime.so` 也是 ONNX Runtime 1.27.0，只打包一份 |
| Streaming Zipformer 中英双语模型（不随 APK，按需下载，csukuangfj/sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20） | `98590b7` | Apache-2.0 | csukuangfj；上游 pfluo/k2fsa-zipformer-chinese-english-mixed | 实时字幕；许可全文随 APK 的 `assets/licenses/streaming-asr-model-APACHE-2.0.txt` |

## 四、格式兼容与致谢（未复制代码）

- **Clawd on Desk**（https://github.com/rullerzhou-afk/clawd-on-desk，AGPL-3.0）：桌宠的主题包格式、状态名、优先级与时长默认值与它兼容，宠物包可以在两边通用。本项目没有复制它的代码。
- **Streamdown**（https://github.com/vercel/streamdown）：`app/lib/ui/chat/render/stream_repair.dart` 修补流式 Markdown 末尾的方式参照了它的 `remend`。
- **DS Bot**：dsh-ui 组件的名称与 DS Bot 一致。
- **Open-Meteo**（https://open-meteo.com，数据 CC BY 4.0）：示例插件 `examples/plugins/dsh-go-example-weather` 使用它的天气数据，卡片上注明来源。

## 许可证全文

### MIT License

适用于以下版权声明：

```text
Copyright (c) 2026 CikeSeven                                   (PiPilot)
Copyright (c) 2026 CikeSeven                                   (Phase)
Copyright (c) 2026 DeepSeek                                    (DeepSeek Harness)
Copyright (c) 2026 qiannianhuanxiang                           (DSHA)
Copyright (c) Microsoft Corporation                            (ONNX Runtime)
Copyright (c) 2020-present Silero Team                         (Silero VAD)
Copyright (c) 2026 Jakub Antalik                               (Libraries.dev)
Copyright (c) 2018 Civilized Discourse Construction Kit, Inc.  (discourse_docker)
Copyright (c) 2023 Phosphor Icons                              (Phosphor Icons)
Copyright (c) 2021 RikkaW                                      (Shizuku-API)
```

discourse-emojis 上游未附 LICENSE 文件与版权行，按其 gemspec 声明的 MIT 使用。

```text
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Apache License 2.0

适用于 DS Bot、Material Icons、libadb-android、Conscrypt、AndroidX WebKit。

```text
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS
```

### NOTICE：DS Bot（提交 `1bebe82`，原文照录）

```text
DS Bot
Copyright 2026 Fei2411 and the DS Bot contributors

This product is licensed under the Apache License, Version 2.0 (see LICENSE).

==============================================================================
Third-party code in this repository
==============================================================================

DeepSeek Harness (https://github.com/deepseek-ai/deepseek-harness)
MIT License, Copyright (c) 2026 DeepSeek

  - ds-bot/dev/desktop-linux/launch.mts follows the steps of
    apps/desktop/scripts/dev.ts in DeepSeek Harness and reuses a few of its
    lines (the release record and the Electron launch arguments). It is a
    developer script for screenshots on Linux and is not in the npm package.
  - app/src/host.mjs and app/src/profile.mjs follow
    apps/desktop-host/src/index.ts: the profile boot and the ready, fatal and
    shutdown messages.
  - app/src/host-process.mjs follows apps/desktop/src/host-process.ts: the
    Host in Electron's Node mode and the shutdown escalation.
  - app/src/main.mjs follows apps/desktop/src/main.ts for the Windows window
    options (the caption-button overlay, its colors and the native theme). app/src/preload.cjs adapts
    apps/desktop/src/preload-windows.ts, apps/desktop/src/preload-platform.ts
    and apps/desktop/src/preload-theme.ts: the caption-band marks, the
    fullscreen mark, the caption-color measure and the theme sync.
  - app/src/bot-browser.mjs adapts apps/desktop/src/browser-guests.ts, and
    the browser part of app/src/preload.cjs follows
    apps/desktop/src/preload-browser.ts: the webview leases, the attachment
    checks and fixed guest preferences, the session policy and the new-window
    requests.
  - app/engine/cordis.patch.yml follows the bundle patch of
    @deepseek-ai/dsh-web-app (packages/bundle/web-app/cordis.patch.yml): the
    transport and host-service rows and the agent-plane rows it turns off.
    app/engine/preset-standard.patch.yml copies its standard preset
    (presets/standard.patch.yml), including the plan-mode prompt text,
    without the goal rows.
  - .agents/skills/record-browser-gif/ comes from the skill of the same name
    in DeepSeek Harness (.agents/skills/record-browser-gif/): SKILL.md is
    adapted and translated for this repository; scripts/encode_gif.py and
    scripts/test_encode_gif.py are copied unchanged.

  Full license text:

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

No other third-party code is copied into this repository. At run time the
plugin uses the @deepseek-ai/* packages of the DeepSeek Harness install it
runs in; they are not bundled. esbuild is a build tool only. The desktop app
in app/ installs the pinned @deepseek-ai/* packages, Electron and pnpm from
npm; they keep their own licenses. The build of its window (app/ui) bundles,
from npm, React and React DOM (MIT, Copyright (c) Meta Platforms, Inc. and
affiliates), and react-markdown and remark-gfm with the packages they use
(MIT, most of them Copyright (c) Titus Wormer; @ungap/structured-clone is ISC,
Copyright (c) Andrea Giammarchi). Vite is a build tool only.

==============================================================================
Projects that gave us ideas (no code copied)
==============================================================================

We thank these projects for the designs they published. DS Bot learned from
their ideas; it does not contain their code.

  - AgentMemoryRepo (https://github.com/AgentMemoryRepo/agentmemoryrepo), MIT:
    the Markdown format of Bot memory (one entry per line with [key: value]
    metadata, a MEMORY.md index that links topic files).
  - OpenAI Codex (https://github.com/openai/codex), Apache-2.0:
    keeping the user's messages next to the summary in a checkpoint, and
    message anchors for searching earlier chat.
  - OpenMausBot (https://github.com/milind-soni/OpenMausBot), Apache-2.0:
    group chat rounds and @mention relays between Bots.
  - Hermes Agent (https://github.com/NousResearch/hermes-agent) and
    Hermes Bot Mode (https://github.com/NousResearch/Hermes-Bot-Mode), MIT:
    one Session per member per group chat, and the list of earlier user
    messages that the plugin, not the model, writes into the handoff.
  - OpenCode (https://github.com/sst/opencode), MIT;
    goose (https://github.com/block/goose), Apache-2.0;
    pi (https://github.com/badlogic/pi-mono), MIT;
    Gemini CLI (https://github.com/google-gemini/gemini-cli), Apache-2.0:
    when to condense a long conversation, and what a handoff note holds.
  - obelisk (https://github.com/tommy0103/obelisk), AGPL-3.0:
    searching a Bot's own chat with a SQLite FTS5 index ranked by BM25.
  - DeepSeek Harness Voice Input plugin
    (packages/experimental/client-ui-voice-input), MIT: the voice chat
    records with the same steps (record, resample to 16 kHz mono, PCM16 WAV)
    before it calls the plugin's speech service.
```

### NOTICE：Conscrypt 2.8.0（原文照录）

```text
Copyright 2016 The Android Open Source Project

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-----------------------------------------------------------------------
This product contains a modified portion of `Netty`, a configurable network
stack in Java, which can be obtained at:

  * LICENSE:
    * licenses/LICENSE.netty.txt (Apache License 2.0)
  * HOMEPAGE:
    * http://netty.io/

This product contains a modified portion of `Apache Harmony`, modular Java runtime,
which can be obtained at:

  * LICENSE:
    * licenses/LICENSE.harmony.txt (Apache License 2.0)
  * HOMEPAGE:
    * https://harmony.apache.org/
```

### Bouncy Castle Licence

```text
Copyright (c) 2000-2023 The Legion of the Bouncy Castle Inc. (https://www.bouncycastle.org)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
```

### 其他许可证

- SIL Open Font License 1.1：`app/assets/fonts/OFL.txt`
- GNU LGPL-3.0（spake2-android、libtalloc）：https://www.gnu.org/licenses/lgpl-3.0.txt ；它以 GNU GPL-3.0 为基础，两份全文一并附在 App 内许可页的 spake2-android 条目里：https://www.gnu.org/licenses/gpl-3.0.txt

## Google ML Kit Text Recognition (Chinese)

Google ML Kit Text Recognition (Chinese)
com.google.mlkit:text-recognition-chinese:16.0.1

This bundled Google SDK is subject to the Google ML Kit terms:
https://developers.google.com/ml-kit/terms
Android SDK data disclosure:
https://developers.google.com/ml-kit/android-data-disclosure

Recognition runs on-device. Screenshots and recognized text are not sent to
Google by this SDK. The SDK collects usage statistics such as device model,
app version and processing time. Phone control may send screenshots and
recognized text to the user's configured model.

Local recognition is enabled by default. While off, recognition requests do not
trigger SDK loading or initialization. Turning it off prevents new recognition,
but does not uninstall
the SDK or promise to clear or stop sending previously accumulated SDK statistics.
The dsh-go anonymous usage statistics switch does not control this SDK.
The Apache 2.0 license for documentation sample code is not the license for
this SDK binary. This notice does not replace Google's SDK terms.
