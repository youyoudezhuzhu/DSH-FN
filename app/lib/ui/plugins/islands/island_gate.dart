// Islands（插件自己的 Web UI）能不能在 App 里打开、从哪里打开。
//
// DSH-FN 只有一种主机：飞牛 NAS 上的 DSH（fnconnect 网关 + 飞牛会话 Cookie）。
// 手机本地引擎、SSH 隧道和中继都已删除；App 内 WebView 还没有接入 fnOS 网关
// 的 Cookie 鉴权，所以离岛先一律关闭（gate=false、url=null）——调用方会退化
// 成普通入口或占位，不会崩。接上网关鉴权后再打开这里。

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plugins/seams/seat_state.dart' show seatRouteGuardReportProvider;
import '../../../state/hosts_state.dart';

/// Whether a host's plugin routes refuse callers without the session cookie
/// (the route guard, §9).
enum RouteGuard {
  /// Not known yet, or nothing to ask (the bridge isn't installed).
  unknown,

  /// A plugin route answered a cookieless call: the hole is open.
  absent,

  /// A plugin route refused a cookieless call (401 / 403).
  present,
}

/// Whether a host may have islands at all (§9).
///
/// DSH-FN 的宿主是飞牛 NAS 上的 DSH：离岛需要 DSH Web 的会话，而 App 内
/// WebView 还没有接上 fnOS 网关的 Cookie 鉴权，先一律不开。参数留在签名里
/// 是为了让调用方（和测试）保持同一套判定语义。
bool islandHostAllowed(
  HostKind kind, {
  bool? reported,
  RouteGuard probed = RouteGuard.unknown,
  bool override = false,
}) => false;

/// The route that answers the probe: the bridge's own inventory, which the
/// guard covers like every other plugin route.
const routeGuardProbePath = '/dsh-go/v1/inventory';

/// Calls [routeGuardProbePath] on [base] with no cookie and no credentials.
Future<RouteGuard> probeRouteGuard(
  Uri base, {
  HttpClient? client,
  Duration timeout = const Duration(seconds: 3),
}) async {
  final http = client ?? HttpClient();
  try {
    final url = Uri(scheme: base.scheme, host: base.host, port: base.port, path: routeGuardProbePath);
    final request = await http.getUrl(url).timeout(timeout);
    request.followRedirects = false;
    final response = await request.close().timeout(timeout);
    await response.drain<void>().catchError((_) {});
    return switch (response.statusCode) {
      401 || 403 => RouteGuard.present,
      >= 200 && < 300 => RouteGuard.absent,
      _ => RouteGuard.unknown,
    };
  } catch (_) {
    return RouteGuard.unknown;
  } finally {
    if (client == null) http.close(force: true);
  }
}

/// What the bridge reports per host (`routeGuard`), from the seats'
/// inventory; null when unknown.
final islandRouteGuardReportProvider = Provider.family<bool?, HostRef>(
  (ref, host) => ref.watch(seatRouteGuardReportProvider(host)),
);

/// Whether [host] may have islands now.
final islandHostGateProvider = Provider.family<bool, HostRef>((ref, host) => islandHostAllowed(host.kind));

/// The DSH Web launch URL for [host]'s islands: none until the fnOS gateway
/// session is available inside the WebView.
final islandHostUrlProvider = Provider.autoDispose.family<Uri?, HostRef>((ref, host) => null);

/// `http://127.0.0.1:3080/?token=…`: the token only buys the session cookie,
/// exactly as the 网页版 does.
Uri islandLaunchUri(String baseUrl, String token) =>
    Uri.parse(baseUrl).replace(path: '/', queryParameters: {'token': token});
