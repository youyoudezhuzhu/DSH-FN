/// 主机入口：抽屉头部的胶囊 + 点开后的主机弹层。
///
/// DSH-FN 只剩一台主机——通过飞牛 fnconnect 访问的 NAS；点这一行打开
/// [RemoteScreen] 管理 fnconnect ID、飞牛登录和连接。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../state/connection_state.dart';
import '../../state/hosts_state.dart';
import '../common/app_sheet.dart';
import '../common/sheet_title_bar.dart';
import '../common/status_chip.dart';
import '../settings/settings_widgets.dart';
import '../theme/app_icons.dart';
import '../theme/theme.dart';
import 'host_status.dart';

/// Drawer-header chip: `● 飞牛 · mynas · 已连接 ⌄`. Opens the host sheet.
class HostChip extends ConsumerWidget {
  const HostChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final host = ref.watch(activeHostProvider);
    final name = ref.watch(hostNameProvider(host));
    final view = watchHostStatus(ref, host);
    final label = name == null || name.isEmpty ? appL10n.hostFnOsLabel : '${appL10n.hostFnOsLabel} · $name';
    return Semantics(
      button: true,
      onTap: onTap,
      label: '$label ${view.label}',
      child: ExcludeSemantics(
        child: GlassSurface(
          tier: GlassTier.pill,
          stadium: true,
          onTap: onTap,
          padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedStatusDot(tone: view.tone, size: 7),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  '$label · ${view.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.tabular(theme.textTheme.labelMedium!.copyWith(color: scheme.onSurfaceVariant)),
                ),
              ),
              const SizedBox(width: 2),
              Icon(AppIcons.dropdown, size: 16, color: DshColors.of(context).textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// 主机弹层：唯一的一台飞牛主机 + 管理入口。 [onManage] 打开 [RemoteScreen]。
Future<void> showHostSheet(BuildContext context, {required VoidCallback onManage}) {
  return showAppSheet<void>(context, isScrollControlled: true, builder: (_) => HostSheet(onManage: onManage));
}

class HostSheet extends ConsumerWidget {
  const HostSheet({super.key, required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = DshColors.of(context);
    final host = ref.watch(activeHostProvider);
    final name = ref.watch(hostNameProvider(host));
    final view = watchHostStatus(ref, host);
    final fnos = ref.watch(fnosHostProvider);
    final config = fnos.config;
    final title = name == null || name.isEmpty ? '未配置' : name;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetTitleBar('飞牛主机'),
              SheetGroup(
                margin: const EdgeInsets.fromLTRB(SheetTitleBar.inset, 0, SheetTitleBar.inset, 12),
                children: [
                  SettingsTile(
                    key: const ValueKey('host-row-fnos'),
                    icon: AppIcons.remoteHosts,
                    tinted: false,
                    title: '飞牛 · $title',
                    subtitle: config == null ? '输入 fnconnect ID 并登录飞牛账号' : config.target.dshBaseUri.toString(),
                    value: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedStatusDot(tone: view.tone, size: 7),
                        const SizedBox(width: 6),
                        Text(view.label),
                      ],
                    ),
                    trailing: Icon(AppIcons.disclosure, size: 18, color: colors.textTertiary),
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      onManage();
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(SheetTitleBar.inset, 0, SheetTitleBar.inset, 8),
                child: Text(
                  'DSH-FN 只连接一台飞牛 NAS：点这一行管理 fnconnect ID、飞牛登录和连接状态。',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.textTertiary, height: 1.5),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
