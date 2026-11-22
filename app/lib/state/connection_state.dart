/// DSH-FN 的连接层。
///
/// 只有一种连接：通过飞牛 fnconnect 落到 NAS 上 DSH（HTTP + WebSocket，走
/// `/app/deepseek-harness/fngateway` 前缀，认证用登录一次得到的飞牛会话
/// Cookie）。原来的本机引擎、SSH 主机和 ds-harness-remote 中继都已删除。
library;

import 'dart:async';

import 'package:dsh_client/dsh_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fnos/fnos_auth.dart';
import '../fnos/fnos_client.dart';
import '../remote/link_status.dart';
import '../remote/network_watch.dart';
import 'hosts_state.dart';

/// A connected DSH host: in DSH-FN always the fnOS NAS behind its fnconnect ID.
class HostConnection {
  const HostConnection({
    required this.client,
    this._label,
    required this.isLocal,
    this.kind = HostKind.fnos,
    this.hostId,
    this.name,
    this.workingDirectory,
  });

  final DshClient client;

  /// A fixed label (tests); null builds it from [kind] and [name].
  final String? _label;

  /// The host's own name (the fnconnect ID); null when not known.
  final String? name;

  /// Shown in the chat header: `飞牛 · mynas`.
  String get label => _label ?? hostLabel(kind, name);
  final bool isLocal;
  final HostKind kind;
  final String? hostId;

  /// Default cwd for new sessions on the NAS; null lets the remote DSH pick.
  final String? workingDirectory;
}

/// Network changes and app resumes: a dropped connection is retried then.
final networkKicksProvider = Provider<Stream<void>>((ref) => networkKicks());

/// Connects to the DSH on the configured fnOS NAS.
class FnosConnectionController extends AsyncNotifier<HostConnection?> {
  @override
  Future<HostConnection?> build() async {
    final r = ref;
    final kicks = r.read(networkKicksProvider).listen((_) {
      if (r.mounted && state.hasError && !state.isLoading) r.invalidateSelf();
    });
    r.onDispose(() => unawaited(kicks.cancel()));

    final host = r.watch(fnosHostProvider.select((s) => (s.loaded, s.config, s.session)));
    final (loaded, config, session) = host;
    if (!loaded) return null;
    // Nothing to connect to yet: onboarding asks for the ID, then for a login.
    if (config == null || session == null) return null;

    // 网关的飞牛会话会过期（关掉 App 一段时间再打开最常见）：先探测一次，
    // 明确是登录失效就清掉会话让界面回到登录页，而不是一直转圈。
    final probe = await probeFnosDsh(target: config.target, cookieHeader: session.cookieHeader);
    if (!r.mounted) return null;
    if (!probe.authenticated) {
      if (_looksLikeExpiredSession(probe.detail)) {
        await r.read(fnosHostProvider.notifier).clearSession();
        return null;
      }
      throw StateError(probe.detail ?? '连不上飞牛网关');
    }

    final DshClient client;
    try {
      client = await connectFnosDsh(
        target: config.target,
        cookieHeader: session.cookieHeader,
        backgroundLists: true,
      ).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw StateError('连接飞牛网关超时：请确认 NAS 在线且 fnconnect 可用');
    } on DshHttpException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await r.read(fnosHostProvider.notifier).clearSession();
        return null;
      }
      rethrow;
    } on DshProtocolException catch (error) {
      if (error.message.toLowerCase().contains('invalid token')) {
        await r.read(fnosHostProvider.notifier).clearSession();
        return null;
      }
      rethrow;
    }
    if (!r.mounted) {
      await client.close();
      return null;
    }
    r.onDispose(() => unawaited(client.close()));
    return HostConnection(
      client: client,
      name: config.name ?? config.fnconnectId,
      isLocal: false,
      kind: HostKind.fnos,
      hostId: config.fnconnectId,
      workingDirectory: null,
    );
  }

  /// 探测结果里哪些原因等于「飞牛登录失效」，而不是网络/DSH 没起来。
  static bool _looksLikeExpiredSession(String? detail) {
    if (detail == null) return false;
    final text = detail.toLowerCase();
    return text.contains('invalid token') ||
        text.contains('失效') ||
        text.contains('401') ||
        text.contains('403');
  }

  /// Connects again now (失败卡片上的「重试」).
  void retry() {
    if (ref.mounted) ref.invalidateSelf();
  }
}

final fnosConnectionProvider = AsyncNotifierProvider.autoDispose<FnosConnectionController, HostConnection?>(
  FnosConnectionController.new,
);

/// Compatibility alias: shared UI reads the one host as `localConnectionProvider`.
final localConnectionProvider = fnosConnectionProvider;

/// The active host's connection — the single entry point for the whole app.
final activeConnectionProvider = Provider<AsyncValue<HostConnection?>>((ref) => ref.watch(fnosConnectionProvider));

/// Per-host retry handle used by connection cards: `remoteConnectionProvider(host)`.
class RemoteConnectionController extends AsyncNotifier<HostConnection?> {
  @override
  Future<HostConnection?> build() => ref.watch(fnosConnectionProvider.future);

  /// Gives up any backoff and connects again now.
  void retry() {
    final target = ref.read(fnosConnectionProvider.notifier);
    target.retry();
    if (ref.mounted) ref.invalidateSelf();
  }
}

final remoteConnectionProvider = AsyncNotifierProvider.autoDispose
    .family<RemoteConnectionController, HostConnection?, HostRef>((host) => RemoteConnectionController());

/// The host's display name (the fnconnect ID); null before it is configured.
final hostNameProvider = Provider.autoDispose.family<String?, HostRef>((ref, host) {
  ref.watch(fnosHostProvider.select((s) => s.config));
  final config = ref.read(fnosHostProvider).config;
  return config?.name ?? config?.fnconnectId;
});

/// Link status for shared UI. There is no SSH/relay link in DSH-FN: report the
/// idle status so status widgets render "未连接" until [activeConnectionProvider] changes.
final hostLinkStatusProvider = Provider.autoDispose.family<HostLinkStatus, HostRef>(
  (ref, host) => HostLinkStatus.idle,
);
