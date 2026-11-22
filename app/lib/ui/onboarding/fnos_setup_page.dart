/// 首次运行 / 重新登录：输入飞牛 fnconnect ID，登录一次飞牛账号。
///
/// 登录只做一次：拿到的飞牛会话 Cookie 存进安全存储，之后 App 冷启动直接
/// 用 Cookie 连 `https://<id>.fnos.net/app/deepseek-harness/fngateway`。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fnos/fnconnect.dart';
import '../../fnos/fnos_webview.dart';
import '../../state/hosts_state.dart';
import '../shell/brand_mark.dart';
import '../theme/theme.dart';

class FnosSetupPage extends ConsumerStatefulWidget {
  const FnosSetupPage({super.key});

  @override
  ConsumerState<FnosSetupPage> createState() => _FnosSetupPageState();
}

class _FnosSetupPageState extends ConsumerState<FnosSetupPage> {
  late final TextEditingController _input;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: ref.read(fnosHostProvider).config?.fnconnectId ?? '');
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final raw = _input.text.trim();
    final target = parseFnConnectInput(raw);
    if (target == null) {
      setState(() => _error = '请输入正确的飞牛 fnconnect ID，例如 mynas');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final hosts = ref.read(fnosHostProvider.notifier);
      await hosts.saveTarget(target);
      if (!mounted) return;
      final cookie = await FnosLoginPage.show(context, target: target);
      if (!mounted) return;
      if (cookie == null || cookie.isEmpty) {
        setState(() {
          _busy = false;
          _error = '登录没有完成：请在弹出的飞牛登录页里登录并等待连接成功。';
        });
        return;
      }
      await hosts.saveSession(cookie);
      // RootGate 会看到已登录并自动开始连接。
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forget() async {
    await ref.read(fnosHostProvider.notifier).forget();
    if (mounted) setState(() => _input.clear());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configured = ref.watch(fnosHostProvider.select((s) => s.configured));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dshSystemOverlay(theme.brightness),
      child: AppBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark(size: 72, tile: true)),
                    const SizedBox(height: 20),
                    Text(
                      'DSH-FN',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '输入飞牛 fnconnect 的 ID，连接这台 NAS 上的 DeepSeek Harness。',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _input,
                      enabled: !_busy,
                      autofocus: !configured,
                      textInputAction: TextInputAction.go,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.url,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: '飞牛 fnconnect ID',
                        hintText: 'mynas',
                        helperText: '只填 ID 即可（如 mynas）；也支持完整域名 xxx.fnos.net',
                      ),
                    ),
                    if (_error case final error?) ...[
                      const SizedBox(height: 12),
                      Text(error, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(configured ? '登录飞牛并连接' : '下一步：登录飞牛'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '首次使用需要在弹出的页面里登录飞牛账号；登录一次后，之后打开 App 会自动连接。',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                    if (configured) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy ? null : _forget,
                        child: const Text('忘记这台 NAS'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
