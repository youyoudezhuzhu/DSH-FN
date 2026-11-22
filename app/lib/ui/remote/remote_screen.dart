/// 远程主机页（保留 [RemoteScreen] 类名与 `const RemoteScreen()` 构造）：
/// DSH-FN 唯一的一台主机——通过飞牛 fnconnect 访问的 NAS 上的 DSH。
///
/// - 未配置 / 更改 ID：输入 fnconnect ID → 校验 → 保存 → 弹出飞牛登录页 →
///   保存会话 Cookie → 等 DSH 连上 → 关闭页面。
/// - 已配置：显示主机、连接状态和失败原因，可重新登录、测试连接、更改 ID、
///   退出登录（清除配置与会话 Cookie）。
///
/// 首次启动的整页引导由 RootGate 的 FnosSetupPage 负责；这里既可以从设置
/// 进入管理，也可以在未配置时完成同一套"输入 + 登录"流程。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fnos/fnconnect.dart';
import '../../fnos/fnos_auth.dart';
import '../../fnos/fnos_webview.dart';
import '../../state/connection_state.dart';
import '../../state/hosts_state.dart';
import '../common/app_dialog.dart';
import '../common/brief_notice.dart';
import '../common/status_chip.dart';
import '../settings/settings_widgets.dart';
import '../shell/page_frame.dart';
import '../theme/app_icons.dart';
import '../theme/theme.dart';
import 'host_status.dart';

class RemoteScreen extends ConsumerStatefulWidget {
  const RemoteScreen({super.key});

  @override
  ConsumerState<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends ConsumerState<RemoteScreen> {
  late final TextEditingController _idInput;

  /// 登录/连接流程进行中：按钮转圈并禁用。
  bool _busy = false;

  /// 已配置时点「更改 fnconnect ID」进入编辑态。
  bool _editing = false;

  /// 正在用当前会话探测 DSH 入口。
  bool _testing = false;

  String? _error;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _idInput = TextEditingController(text: ref.read(fnosHostProvider).config?.fnconnectId ?? '');
  }

  @override
  void dispose() {
    _idInput.dispose();
    super.dispose();
  }

  // ── 流程 ──────────────────────────────────────────────────────────────────

  /// 保存 fnconnect ID → 飞牛登录 → 保存会话 → 等 DSH 连上。
  Future<void> _submit() async {
    if (_busy) return;
    final target = parseFnConnectInput(_idInput.text.trim());
    if (target == null) {
      setState(() => _error = '请输入正确的飞牛 fnconnect ID，例如 mynas');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _testResult = null;
    });
    try {
      final hosts = ref.read(fnosHostProvider.notifier);
      await hosts.saveTarget(target, name: target.fnconnectId);
      if (!mounted) return;
      setState(() => _editing = false);
      final cookie = await FnosLoginPage.show(context, target: target);
      if (!mounted) return;
      if (cookie == null || cookie.isEmpty) {
        setState(() => _error = '登录没有完成：请在飞牛登录页完成登录，并等待验证通过。');
        return;
      }
      await hosts.saveSession(cookie);
      if (!mounted) return;
      final connected = await _waitConnected();
      if (!mounted) return;
      if (!connected) {
        setState(() => _error = '登录成功，但还没连上 DSH：请确认飞牛 NAS 在线、DSH 应用正在运行，然后点「重试连接」。');
        return;
      }
      showBriefNotice(context, '已连接飞牛 · ${target.fnconnectId}');
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = '连接失败：${describeHostError(error)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 已配置主机：重新走一次飞牛登录（会话过期、换飞牛账号时用）。
  Future<void> _relogin() async {
    final config = ref.read(fnosHostProvider).config;
    if (config == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _testResult = null;
    });
    try {
      final cookie = await FnosLoginPage.show(context, target: config.target);
      if (!mounted) return;
      if (cookie == null || cookie.isEmpty) {
        setState(() => _error = '登录已取消。');
        return;
      }
      await ref.read(fnosHostProvider.notifier).saveSession(cookie);
      if (!mounted) return;
      final connected = await _waitConnected();
      if (!mounted) return;
      if (connected) {
        showBriefNotice(context, '飞牛登录已更新，连接正常');
      } else {
        setState(() => _error = '飞牛登录成功，但还没连上 DSH，可点「重试连接」。');
      }
    } catch (error) {
      if (mounted) setState(() => _error = '登录失败：${describeHostError(error)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 用当前会话访问一次 DSH 入口，确认飞牛登录和网关都还通。
  Future<void> _test() async {
    final host = ref.read(fnosHostProvider);
    final config = host.config;
    final session = host.session;
    if (config == null || session == null || _busy || _testing) return;
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final result = await probeFnosDsh(target: config.target, cookieHeader: session.cookieHeader);
      if (!mounted) return;
      final text = result.authenticated
          ? '连接正常：飞牛网关返回 HTTP ${result.statusCode}，DSH 可访问。'
          : '连接失败：${result.detail ?? '未通过网关验证'}。';
      setState(() => _testResult = text);
      showBriefNotice(context, text);
    } catch (error) {
      if (!mounted) return;
      final text = '连接测试失败：${describeHostError(error)}';
      setState(() => _testResult = text);
      showBriefNotice(context, text);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  void _retryConnect() {
    ref.read(fnosConnectionProvider.notifier).retry();
    showBriefNotice(context, '正在重新连接…');
  }

  void _beginEdit() {
    final config = ref.read(fnosHostProvider).config;
    setState(() {
      _idInput.text = config?.fnconnectId ?? '';
      _editing = true;
      _error = null;
      _testResult = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _error = null;
      _idInput.clear();
    });
  }

  /// 退出登录并忘记这台 NAS；[FnosHostController.forget] 会同时清掉 Cookie。
  Future<void> _logout() async {
    if (_busy) return;
    final ok = await showAppDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('退出登录？'),
        content: const Text('会清除保存的 fnconnect ID 和飞牛会话 Cookie。下次打开 App 需要重新输入 ID 并登录。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('退出登录')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(fnosHostProvider.notifier).forget();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = null;
        _testResult = null;
        _editing = false;
        _idInput.clear();
      });
      showBriefNotice(context, '已退出登录');
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showBriefNotice(context, '退出登录失败：${describeHostError(error)}');
    }
  }

  /// 自动登录：保存/清除飞牛账号密码（只进本机安全存储）。
  Future<void> _editAutoLogin() async {
    final config = ref.read(fnosHostProvider).credentials;
    final username = TextEditingController(text: config?.username ?? '');
    final password = TextEditingController(text: config?.password ?? '');
    final save = await showAppDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('自动登录'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('保存飞牛账号密码到本机安全存储；飞牛登录过期后自动重新登录，密码不上传、不写日志。'),
              const SizedBox(height: 12),
              TextField(
                controller: username,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: '飞牛账号', hintText: '登录 fnOS 的用户名或手机号'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: password,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: '飞牛密码'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('关闭自动登录'),
          ),
          TextButton(onPressed: () => Navigator.of(dialog).pop(), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: const Text('保存')),
        ],
      ),
    );
    if (save == null || !mounted) return;
    await ref.read(fnosHostProvider.notifier).saveCredentials(
      save ? FnosCredentials(username: username.text.trim(), password: password.text) : null,
    );
    if (!mounted) return;
    showBriefNotice(context, save ? '已开启自动登录' : '已关闭自动登录');
  }

  /// 修改 DSH 网关路径（同一台 NAS，保留飞牛登录）。
  Future<void> _editGatewayPath() async {
    final config = ref.read(fnosHostProvider).config;
    if (config == null) return;
    final controller = TextEditingController(text: config.target.gatewayPath);
    final path = await showDialog<String>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('DSH 网关路径'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.url,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '路径',
                  hintText: defaultDshGatewayPath,
                  helperText: '应用中心安装一般用默认；自建反代/Docker 时填反代路径，如 /dsh',
                  helperMaxLines: 3,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final preset in commonDshGatewayPaths)
                    ActionChip(
                      label: Text(preset, style: theme.textTheme.bodySmall),
                      onPressed: () => controller.text = preset,
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    if (path == null || !mounted) return;
    final target = await ref.read(fnosHostProvider.notifier).saveGatewayPath(path);
    if (!mounted) return;
    if (target == null) {
      showBriefNotice(context, '网关路径不合法：需要以 / 开头的路径');
      return;
    }
    showBriefNotice(context, '已改用 ${target.gatewayPath}，正在重新连接');
  }

  /// 等 DSH 连上（最多 30s）。登录页已经验证过网关，通常不到 1s。
  Future<bool> _waitConnected() async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (mounted && DateTime.now().isBefore(deadline)) {
      final connection = ref.read(activeConnectionProvider);
      if (connection.hasError) return false;
      if (connection.value != null) return true;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return false;
  }

  // ── 界面 ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final host = ref.watch(fnosHostProvider);
    final config = host.config;
    final status = watchHostStatus(ref, ref.watch(activeHostProvider));

    if (!host.loaded) {
      return AppPage.list(
        title: '飞牛主机',
        children: const [
          SizedBox(height: 48),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    final editing = _editing || config == null;
    final children = <Widget>[
      if (editing)
        ..._setupSections(context, host)
      else if (host.session == null)
        ..._signedOutSections(context, host)
      else
        ..._hostSections(context, host, status),
      const SizedBox(height: 24),
    ];
    return AppPage.list(
      title: '飞牛主机',
      subtitle: Text(config == null ? '连接飞牛 NAS 上的 DeepSeek Harness' : '飞牛 · ${config.name ?? config.fnconnectId}'),
      children: children,
    );
  }

  /// 未配置 / 更改 ID：输入框 + 保存并登录。
  List<Widget> _setupSections(BuildContext context, FnosHostState host) {
    final theme = Theme.of(context);
    final colors = DshColors.of(context);
    final changing = host.config != null;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: GlassSurface(
          tier: GlassTier.card,
          borderRadius: AppShape.radiusLg,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(changing ? '更改 fnconnect ID' : '连接飞牛 NAS 上的 DSH', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                '只填 ID，如 mynas。App 会访问 https://<ID>.fnos.net 上的 DSH'
                '（默认网关路径 $defaultDshGatewayPath；自建反代/Docker 等安装方式'
                '可在「管理 → DSH 网关路径」里改），并自动完成登录后的连接。',
                style: theme.textTheme.bodySmall?.copyWith(color: colors.textTertiary, height: 1.5),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('fnconnect-id-input'),
                controller: _idInput,
                enabled: !_busy,
                autofocus: !changing,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                onSubmitted: _busy ? null : (_) => unawaited(_submit()),
                decoration: const InputDecoration(
                  labelText: '飞牛 fnconnect ID',
                  hintText: 'mynas',
                  prefixText: 'https://',
                  suffixText: '.fnos.net',
                  helperText: '也支持粘贴 fnos.net 域名或完整 URL',
                ),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 12),
                Text(error, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : () => unawaited(_submit()),
                child: _busy ? const _BusyLabel('正在登录并连接…') : Text(changing ? '保存并重新登录' : '保存并登录飞牛'),
              ),
              if (changing) ...[
                const SizedBox(height: 4),
                TextButton(onPressed: _busy ? null : _cancelEdit, child: const Text('取消')),
              ],
            ],
          ),
        ),
      ),
      SettingsSection(
        title: '怎么工作',
        footer: Text(
          '登录一次飞牛账号后，会话 Cookie 保存在手机的安全存储里；'
          '之后打开 App 会自动连接，不用重复输入 ID。手机需要能访问 fnos.net。',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.textTertiary, height: 1.5),
        ),
        children: const [
          InfoRow(label: '接入方式', value: '飞牛 fnconnect'),
          InfoRow(label: 'DSH 网关路径', value: '$defaultDshGatewayPath（可在「管理」里改）', mono: true),
        ],
      ),
    ];
  }

  /// 已保存 ID、但还没有可用飞牛登录。
  List<Widget> _signedOutSections(BuildContext context, FnosHostState host) {
    final theme = Theme.of(context);
    final colors = DshColors.of(context);
    final config = host.config!;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: GlassSurface(
          tier: GlassTier.card,
          borderRadius: AppShape.radiusLg,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(AppIcons.lock, size: 20, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(child: Text('需要登录飞牛', style: theme.textTheme.titleMedium)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '已保存 fnconnect ID：${config.fnconnectId}。登录一次飞牛账号即可连接这台 NAS 上的 DSH。',
                style: theme.textTheme.bodySmall?.copyWith(color: colors.textTertiary, height: 1.5),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 12),
                Text(error, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : () => unawaited(_relogin()),
                child: _busy ? const _BusyLabel('正在登录…') : const Text('登录飞牛'),
              ),
            ],
          ),
        ),
      ),
      ..._managementSections(context, host),
    ];
  }

  /// 已配置且已登录：状态卡 + 管理操作 + 连接信息。
  List<Widget> _hostSections(BuildContext context, FnosHostState host, HostStatusView status) {
    final theme = Theme.of(context);
    final colors = DshColors.of(context);
    final config = host.config!;
    final session = host.session!;
    final connection = ref.watch(activeConnectionProvider);
    final error = connection.error;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: GlassSurface(
          tier: GlassTier.card,
          borderRadius: AppShape.radiusLg,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  StatusDot(tone: status.tone, size: 10),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('飞牛 · ${config.name ?? config.fnconnectId}', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          config.target.origin.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(status.label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              if (error != null) ...[
                const SizedBox(height: 6),
                Text(
                  describeHostError(error),
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.danger, height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _retryConnect,
                      icon: const Icon(AppIcons.retry, size: 16),
                      label: const Text('重试连接'),
                    ),
                    const SizedBox(width: 4),
                    TextButton(onPressed: _busy ? null : () => unawaited(_relogin()), child: const Text('重新登录')),
                  ],
                ),
              ] else if (session.isStale) ...[
                const SizedBox(height: 6),
                Text(
                  '飞牛登录已保存超过 25 天，建议重新登录一次。',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.warning, height: 1.5),
                ),
              ],
              if (_busy) ...[const SizedBox(height: 12), const LinearProgressIndicator(minHeight: 2)],
            ],
          ),
        ),
      ),
      if (_error case final error?) _noticeLine(context, error),
      ..._managementSections(context, host),
      SettingsSection(
        title: '连接信息',
        children: [
          InfoRow(label: '飞牛主机', value: '飞牛 · ${config.name ?? config.fnconnectId}'),
          InfoRow(label: 'fnconnect ID', value: config.fnconnectId),
          InfoRow(label: 'DSH 地址', value: config.target.dshBaseUri.toString(), mono: true),
          InfoRow(label: '飞牛登录', value: session.isStale ? '已登录（超过 25 天，建议重新登录）' : '已登录'),
        ],
      ),
    ];
  }

  /// 管理操作：测试连接 / 重新登录 / 更改 ID / 退出登录。
  List<Widget> _managementSections(BuildContext context, FnosHostState host) {
    final session = host.session;
    return [
      SettingsSection(
        title: '管理',
        footer: _testResult == null ? null : Text(_testResult!, style: Theme.of(context).textTheme.bodySmall),
        children: [
          if (session != null)
            SettingsTile(
              icon: AppIcons.retry,
              tinted: false,
              title: '测试连接',
              subtitle: '用当前登录状态访问一次 DSH 入口',
              value: _testing
                  ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              onTap: _busy || _testing ? null : () => unawaited(_test()),
            ),
          SettingsTile(
            icon: AppIcons.refresh,
            tinted: false,
            title: '重新登录飞牛',
            subtitle: '飞牛登录过期或换了飞牛账号时使用',
            onTap: _busy ? null : () => unawaited(_relogin()),
          ),
          SettingsTile(
            icon: AppIcons.lock,
            tinted: false,
            title: '自动登录',
            subtitle: '保存飞牛账号密码到本机；登录过期后自动重新登录，不用手动输',
            value: Text(ref.watch(fnosHostProvider).autoLogin ? '已开启' : '未开启'),
            onTap: _busy ? null : () => unawaited(_editAutoLogin()),
          ),
          SettingsTile(
            icon: AppIcons.configure,
            tinted: false,
            title: 'DSH 网关路径',
            subtitle: '当前 ${ref.read(fnosHostProvider).config?.target.gatewayPath ?? defaultDshGatewayPath}；'
                '自建反代/Docker 时修改',
            onTap: _busy ? null : () => unawaited(_editGatewayPath()),
          ),
          SettingsTile(
            icon: AppIcons.configure,
            tinted: false,
            title: '更改 fnconnect ID',
            subtitle: '换一台飞牛 NAS；当前飞牛登录会失效',
            onTap: _busy ? null : _beginEdit,
          ),
          SettingsTile(
            icon: AppIcons.logout,
            tinted: false,
            danger: true,
            title: '退出登录',
            subtitle: '清除保存的配置和飞牛会话 Cookie',
            onTap: _busy ? null : () => unawaited(_logout()),
          ),
        ],
      ),
    ];
  }

  Widget _noticeLine(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error, height: 1.5)),
    );
  }
}

class _BusyLabel extends StatelessWidget {
  const _BusyLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}
