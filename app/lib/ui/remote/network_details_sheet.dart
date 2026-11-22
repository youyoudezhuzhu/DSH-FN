/// 主机信息弹层：这台飞牛主机的地址与连接/登录状态。
///
/// 原来的 SSH/中继网络诊断（RTT、路径、IP 协议）只属于已删除的
/// ds-harness-remote 中继；飞牛 fnconnect 这条链路只剩"能不能连上"和
/// "飞牛登录是否还有效"，这里如实显示。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/connection_state.dart';
import '../../state/hosts_state.dart';
import '../common/app_sheet.dart';
import '../common/sheet_title_bar.dart';
import '../settings/settings_widgets.dart';
import '../theme/theme.dart';
import 'host_status.dart';

Future<void> showRemoteNetworkDetails(BuildContext context, HostRef host) => showAppSheet<void>(
  context,
  dismissal: SheetDismissal.button,
  isScrollControlled: true,
  builder: (_) => RemoteNetworkDetailsSheet(host: host),
);

class RemoteNetworkDetailsSheet extends ConsumerWidget {
  const RemoteNetworkDetailsSheet({super.key, required this.host});

  final HostRef host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = DshColors.of(context);
    final fnos = ref.watch(fnosHostProvider);
    final connection = ref.watch(activeConnectionProvider);
    final status = watchHostStatus(ref, host);
    final config = fnos.config;
    final session = fnos.session;
    final error = connection.error;
    final margin = const EdgeInsets.fromLTRB(SheetTitleBar.inset, 0, SheetTitleBar.inset, 16);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetTitleBar('主机信息'),
              SettingsSection(
                title: '飞牛主机',
                margin: margin,
                children: [
                  InfoRow(label: '名称', value: config == null ? '未配置' : '飞牛 · ${config.name ?? config.fnconnectId}'),
                  InfoRow(label: 'fnconnect ID', value: config?.fnconnectId ?? '—'),
                  InfoRow(label: 'DSH 地址', value: config?.target.dshBaseUri.toString() ?? '—', mono: true),
                ],
              ),
              SettingsSection(
                title: '连接状态',
                margin: margin,
                children: [
                  InfoRow(label: '连接', value: status.label),
                  InfoRow(
                    label: '飞牛登录',
                    value: session == null
                        ? '未登录'
                        : session.isStale
                        ? '已过期（建议重新登录）'
                        : '已登录',
                  ),
                ],
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(SheetTitleBar.inset, 0, SheetTitleBar.inset, 12),
                  child: Text(
                    describeHostError(error),
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.danger, height: 1.5),
                  ),
                ),
              if (connection.hasError)
                Padding(
                  padding: const EdgeInsets.fromLTRB(SheetTitleBar.inset, 0, SheetTitleBar.inset, 16),
                  child: FilledButton(
                    onPressed: () => ref.read(fnosConnectionProvider.notifier).retry(),
                    child: const Text('重试连接'),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
