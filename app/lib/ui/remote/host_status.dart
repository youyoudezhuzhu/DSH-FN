/// 主机状态：状态点 + 文字。外壳（抽屉、会话列表、网页版）和主机页共用。
///
/// DSH-FN 只有一台飞牛主机；状态来自 [fnosHostProvider]（是否配置/登录飞牛）
/// 和 [activeConnectionProvider]（是否连上那台 NAS 上的 DSH）。
library;

import 'dart:async';
import 'dart:io';

import 'package:dsh_client/dsh_client.dart' show DshHttpException, DshRemoteException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../remote/link_status.dart';
import '../../state/connection_state.dart';
import '../../state/hosts_state.dart';
import '../common/status_chip.dart';
import '../theme/app_icons.dart';

/// Dot + words for a host's state. Colour is never the only signal.
class HostStatusView {
  const HostStatusView(this.tone, this.label);

  final StatusTone tone;
  final String label;

  /// 旧连接层（[HostLinkStatus]）的状态；共享 UI 仍沿用它。
  static HostStatusView ofLink(HostLinkStatus status) => switch (status.phase) {
    HostLinkPhase.idle => HostStatusView(StatusTone.idle, appL10n.commonNotConnected),
    HostLinkPhase.connecting => HostStatusView(
      StatusTone.busy,
      status.step == null ? appL10n.remoteConnecting : '${status.step!.label}…',
    ),
    HostLinkPhase.connected => HostStatusView(StatusTone.ok, appL10n.remoteConnected),
    HostLinkPhase.reconnecting => HostStatusView(StatusTone.warn, appL10n.remoteReconnecting),
    HostLinkPhase.failed => HostStatusView(StatusTone.error, appL10n.commonConnectionFailed),
  };
}

/// Live status of the one fnOS host: 未配置 → 未登录 → 连接中 → 已连接/失败.
HostStatusView watchHostStatus(WidgetRef ref, HostRef host) {
  final fnos = ref.watch(fnosHostProvider.select((s) => (s.loaded, s.configured, s.signedIn)));
  final (loaded, configured, signedIn) = fnos;
  if (!loaded) return HostStatusView(StatusTone.busy, appL10n.remoteConnecting);
  if (!configured) return const HostStatusView(StatusTone.idle, '未配置');
  if (!signedIn) return const HostStatusView(StatusTone.idle, '未登录');
  final connection = ref.watch(activeConnectionProvider);
  if (connection.hasError) return HostStatusView(StatusTone.error, appL10n.commonConnectionFailed);
  if (connection.value == null) return HostStatusView(StatusTone.busy, appL10n.remoteConnecting);
  return HostStatusView(StatusTone.ok, appL10n.remoteConnected);
}

/// 一句能给人看的中文原因（不含 Cookie、不含原始异常全文）。
String describeHostError(Object error) => switch (error) {
  DshHttpException(:final statusCode) when statusCode == 401 || statusCode == 403 => '飞牛登录已失效，请重新登录',
  DshHttpException(:final statusCode) => 'DSH 网关返回 HTTP $statusCode',
  DshRemoteException(:final message) when message.isNotEmpty => message,
  DshRemoteException(:final code) => 'DSH 返回错误（$code）',
  SocketException() => '无法连接飞牛网关，请检查网络或确认 NAS 在线',
  HandshakeException() => 'TLS 握手失败，无法安全连接飞牛网关',
  TimeoutException() => '连接超时',
  _ => '连接失败（${error.runtimeType}）',
};

IconData hostKindIcon(HostKind kind) => switch (kind) {
  HostKind.fnos => AppIcons.remoteHosts,
};

int hostKindTint(HostKind kind) => switch (kind) {
  HostKind.fnos => 0,
};
