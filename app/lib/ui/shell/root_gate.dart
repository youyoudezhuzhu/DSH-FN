/// App 入口的第一层：决定显示"配置飞牛主机"还是主界面。
///
/// DSH-FN 没有手机本地引擎：配置好 fnconnect ID 并登录飞牛账号后，App 直接
/// 连接那台 NAS 上的 DSH；冷启动时自动重连（会话 Cookie 存在安全存储里）。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../launch/launch_state.dart';
import '../../launch/startup_trace.dart';
import '../../state/connection_state.dart';
import '../../state/hosts_state.dart';
import '../onboarding/fnos_setup_page.dart';
import '../theme/theme.dart';
import '../web/mode_home.dart';
import 'brand_mark.dart';

/// App root: configures the fnOS host on first run, then shows the native shell.
class RootGate extends ConsumerStatefulWidget {
  const RootGate({super.key, this.home});

  /// Stands in for [ModeHome] (tests).
  @visibleForTesting
  final Widget? home;

  @override
  ConsumerState<RootGate> createState() => _RootGateState();
}

class _RootGateState extends ConsumerState<RootGate> {
  bool _launchReady = false;

  /// 首次连接迟迟没有结果（网关掉线、WebSocket 卡住）时，别让启动画面一直转。
  static const _slowConnect = Duration(seconds: 20);
  bool _slow = false;
  Timer? _slowTimer;

  void _watchSlowStartup(bool connecting) {
    if (!connecting) {
      _slowTimer?.cancel();
      _slowTimer = null;
      if (_slow) _slow = false;
      return;
    }
    if (_slow || _slowTimer != null) return;
    _slowTimer = Timer(_slowConnect, () {
      if (!mounted) return;
      setState(() {
        _slow = true;
        _slowTimer = null;
      });
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  void _markLaunchReady() {
    if (_launchReady) return;
    _launchReady = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StartupTrace.mark('first page');
      final launch = LaunchController.active.value;
      if (launch == null) return StartupTrace.finished();
      // No on-device engine to wait for: the first page is the whole warm-up.
      launch.ready(waitsForEngine: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final host = ref.watch(fnosHostProvider);
    final connection = ref.watch(activeConnectionProvider);

    final Widget child;
    var key = 'splash';
    if (!host.loaded) {
      child = const _Splash();
    } else if (!host.configured || !host.signedIn) {
      key = 'setup';
      child = const FnosSetupPage();
    } else if (connection.isLoading && _slow) {
      key = 'offline';
      child = _ConnectFailed(
        error: TimeoutException('连接飞牛网关超时'),
        onRetry: () => ref.read(fnosConnectionProvider.notifier).retry(),
        onRelogin: () => ref.read(fnosHostProvider.notifier).clearSession(),
      );
    } else if (connection.hasError && !connection.isLoading) {
      key = 'offline';
      child = _ConnectFailed(
        error: connection.error!,
        onRetry: () => ref.read(fnosConnectionProvider.notifier).retry(),
        onRelogin: () => ref.read(fnosHostProvider.notifier).clearSession(),
      );
    } else if (connection.value == null) {
      // Configured and signed in: the first connect is in flight. The splash
      // carries the wait instead of flashing the setup page.
      child = const _Splash();
    } else {
      key = 'home';
      child = widget.home ?? const ModeHome();
    }

    _watchSlowStartup(key == 'splash' && host.configured && host.signedIn);
    if (key != 'splash') _markLaunchReady();
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.page),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      child: KeyedSubtree(key: ValueKey(key), child: child),
    );
  }
}

/// 连不上飞牛主机：给出可读的原因和两个出口（重试 / 重新登录）。
class _ConnectFailed extends StatelessWidget {
  const _ConnectFailed({required this.error, required this.onRetry, required this.onRelogin});

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onRelogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dshSystemOverlay(theme.brightness),
      child: AppBackdrop(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 64, tile: true),
                  const SizedBox(height: 24),
                  Text('连不上飞牛上的 DSH', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(
                    '请确认这台飞牛 NAS 在线、DSH 应用正在运行，且 fnconnect 可用。\n'
                    '如果飞牛登录已过期，重新登录一次即可。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _detailOf(error),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: onRetry, child: const Text('重试')),
                  const SizedBox(height: 8),
                  TextButton(onPressed: onRelogin, child: const Text('重新登录飞牛')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 失败卡片上的一行细节：异常类型不是给人看的，能拿到 message 就用它。
String _detailOf(Object error) => switch (error) {
  TimeoutException() => '连接超时（20 秒）',
  StateError(:final message) => message,
  _ => error.toString(),
};

/// Shown for the few hundred ms before the saved host is read. Same colour as
/// the Android launch window; the mark fades in only if loading is slow.
class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  bool _visible = false;
  late final Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dshSystemOverlay(Theme.of(context).brightness),
      child: AppBackdrop(
        child: Center(
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: AppMotion.of(context, AppMotion.slow),
            child: const BrandMark(size: 64, tile: true),
          ),
        ),
      ),
    );
  }
}
