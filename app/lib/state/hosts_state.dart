/// DSH-FN 的主机模型。
///
/// 这里只有一个主机：一台通过飞牛 fnconnect 访问的 NAS 上的 DSH。
/// 安卓本地运行（PRoot 引擎）、SSH 主机和 ds-harness-remote 中继都不再存在，
/// 因此 [HostKind] 只有一个取值，界面上的"本机"一律指这台飞牛主机。
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fnos/fnconnect.dart';
import '../fnos/fnos_auth.dart';
import '../l10n/l10n.dart';
import '../remote/secret_store.dart';
import 'read_list_epoch.dart';

/// DSH-FN 支持的主机类型：只有飞牛 fnconnect 远程主机。
enum HostKind { fnos }

/// 一个主机的身份。
///
/// DSH-FN 只有一个主机，所以相等性只看 [kind]；[id] 是 fnconnect ID，
/// 仅用于展示和日志。
class HostRef {
  const HostRef._(this.kind, this.id, [this.name]);

  const HostRef.fnos([String id = '', String? name]) : this._(HostKind.fnos, id, name);

  /// The app's primary (only) host. Shared UI still compares against this name
  /// when it means "the host this app is about"; in DSH-FN that is the fnOS NAS.
  static const local = HostRef.fnos();

  final HostKind kind;

  /// fnconnect ID（如 `mynas`）；配置尚未加载时为空串。
  final String id;

  /// 配置里的展示名（默认与 ID 相同）。
  final String? name;

  /// DSH-FN 不再有"手机上运行的本机引擎"，恒为 false。
  bool get isLocal => false;

  String encode() => jsonEncode({'kind': kind.name, 'id': id, if (name != null) 'name': name});

  /// 旧版本存下的主机（本机 / SSH / 中继）一律回到飞牛主机；
  /// 具体配置由 [fnosHostProvider] 从自己的键读取。
  static HostRef decode(String? raw) => const HostRef.fnos();

  @override
  bool operator ==(Object other) => other is HostRef && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'HostRef(${kind.name}:$id)';
}

/// 聊天标题等处显示的主机名：`飞牛 · mynas`。
String hostLabel(HostKind kind, String? name) {
  final label = (name == null || name.isEmpty) ? appL10n.commonRemoteHost : _short(name);
  return '${appL10n.hostFnOsLabel} · $label';
}

String _short(String name) {
  final t = name.trim();
  return t.length <= 18 ? t : '${t.substring(0, 17)}…';
}

// ── Secrets ──────────────────────────────────────────────────────────────────

/// Keystore-backed in the app; tests override with [MemorySecretStore].
final secretStoreProvider = Provider<SecretStore>((ref) => SecureSecretStore());

// ── Configured fnOS host ─────────────────────────────────────────────────────

/// 已保存的飞牛主机：fnconnect ID / DSH 网关路径，以及登录一次得到的会话。
class FnosHostConfig {
  const FnosHostConfig({required this.target, this.name});

  factory FnosHostConfig.fromJson(Map<String, Object?> json) {
    final id = json['fnconnectId'];
    if (id is! String || id.isEmpty) throw const FormatException('fnconnectId missing');
    final target = parseFnConnectInput(id);
    if (target == null) throw FormatException('invalid fnconnect id: $id');
    final name = json['name'];
    return FnosHostConfig(target: target, name: name is String && name.isNotEmpty ? name : null);
  }

  final FnConnectTarget target;

  /// 用户可见的名字（默认就用 fnconnect ID）。
  final String? name;

  String get fnconnectId => target.fnconnectId;

  Map<String, Object?> toJson() => {
    'fnconnectId': target.fnconnectId,
    if (name != null) 'name': name,
  };
}

class FnosHostState {
  const FnosHostState({this.config, this.session, this.loaded = false});

  /// 还没配置主机时为 null（首次启动）。
  final FnosHostConfig? config;

  /// 登录过的飞牛会话；为空表示需要（重新）登录。
  final FnosSession? session;

  /// 本地配置读完之前为 false：启动画面期间不要闪一下"未配置"。
  final bool loaded;

  bool get configured => config != null;
  bool get signedIn => session != null;

  FnosHostState copyWith({FnosHostConfig? config, FnosSession? session, bool? loaded, bool clearSession = false}) =>
      FnosHostState(
        config: config ?? this.config,
        session: clearSession ? null : (session ?? this.session),
        loaded: loaded ?? this.loaded,
      );
}

/// 飞牛主机的配置与会话：配置进 SharedPreferences，会话 Cookie 进安全存储。
class FnosHostController extends Notifier<FnosHostState> {
  static const prefsKey = 'fnos_host_v1';
  static const _sessionKey = 'fnos_session';
  late Future<void> _loaded;

  SecretStore get _secrets => ref.read(secretStoreProvider);

  @override
  FnosHostState build() {
    _loaded = _load();
    return const FnosHostState();
  }

  /// 读完本地配置；写入会等它，避免早期保存覆盖磁盘上的内容。
  Future<void> get ready => _loaded;

  Future<void> _load() async {
    FnosHostConfig? config;
    FnosSession? session;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, Object?>) config = FnosHostConfig.fromJson(decoded);
      }
    } catch (_) {
      // 没有 preferences 后端（测试）或坏数据：当作未配置。
    }
    try {
      final raw = await _secrets.read(_sessionKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, Object?>) session = FnosSession.fromJson(decoded);
      }
    } catch (_) {
      // 安全存储不可用或坏数据：当作未登录。
    }
    if (!ref.mounted) return;
    state = FnosHostState(config: config, session: session, loaded: true);
  }

  /// 保存主机（fnconnect ID）。换到另一台 NAS 时旧会话作废。
  Future<void> saveTarget(FnConnectTarget target, {String? name}) async {
    await _loaded;
    final changed = state.config?.fnconnectId != target.fnconnectId;
    final config = FnosHostConfig(target: target, name: name);
    ref.read(readListCredentialEpochProvider.notifier).advance();
    state = FnosHostState(
      config: config,
      session: changed ? null : state.session,
      loaded: true,
    );
    if (changed) await _secrets.delete(_sessionKey);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, jsonEncode(config.toJson()));
    } catch (_) {
      // 内存里已经生效；下次启动重新配置即可。
    }
  }

  /// 记住登录得到的飞牛会话 Cookie。
  Future<void> saveSession(String cookieHeader) async {
    await _loaded;
    final session = FnosSession.now(cookieHeader);
    ref.read(readListCredentialEpochProvider.notifier).advance();
    state = state.copyWith(session: session, loaded: true);
    try {
      await _secrets.write(_sessionKey, jsonEncode(session.toJson()));
    } catch (_) {
      // 写不进安全存储：本次运行仍可用，下次启动要重新登录。
    }
  }

  /// 只清会话（重新登录），保留 fnconnect ID。
  Future<void> clearSession() async {
    await _loaded;
    ref.read(readListCredentialEpochProvider.notifier).advance();
    state = state.copyWith(clearSession: true, loaded: true);
    try {
      await _secrets.delete(_sessionKey);
    } catch (_) {}
  }

  /// 退出登录并忘记这台 NAS。
  Future<void> forget() async {
    await _loaded;
    ref.read(readListCredentialEpochProvider.notifier).advance();
    state = const FnosHostState(loaded: true);
    try {
      await _secrets.delete(_sessionKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefsKey);
    } catch (_) {}
    unawaited(clearFnosCookies());
  }

  /// 刷新主页标题等用的 HostRef。
  HostRef get hostRef {
    final config = state.config;
    if (config == null) return const HostRef.fnos();
    return HostRef.fnos(config.fnconnectId, config.name ?? config.fnconnectId);
  }
}

final fnosHostProvider = NotifierProvider<FnosHostController, FnosHostState>(FnosHostController.new);

/// 当前主机：DSH-FN 只有飞牛主机，保留这个 provider 让共享 UI 的
/// `ref.watch(activeHostProvider).isLocal` 等判断继续工作（恒为 false）。
class ActiveHostController extends Notifier<HostRef> {
  @override
  HostRef build() {
    ref.watch(fnosHostProvider.select((s) => s.config?.fnconnectId));
    final config = ref.read(fnosHostProvider).config;
    if (config == null) return const HostRef.fnos();
    return HostRef.fnos(config.fnconnectId, config.name ?? config.fnconnectId);
  }

  /// 切换当前主机引用。App 只有一个飞牛主机；保留这个入口让按主机分键的
  /// 缓存/通知在状态层继续按 [hostId] 隔离（配置变化时会在 [build] 里重建）。
  void select(HostRef host) => state = host;

  /// 主机被删除后回到配置里的那一个（没有配置时是空 id 的占位主机）。
  Future<void> forget(bool Function(HostRef host) gone) async {
    if (!gone(state)) return;
    final config = ref.read(fnosHostProvider).config;
    state = config == null
        ? const HostRef.fnos()
        : HostRef.fnos(config.fnconnectId, config.name ?? config.fnconnectId);
  }
}

final activeHostProvider = NotifierProvider<ActiveHostController, HostRef>(ActiveHostController.new);
