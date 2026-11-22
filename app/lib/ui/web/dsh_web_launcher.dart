import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../state/hosts_state.dart';
import '../../state/plugins_state.dart' show installedPluginsProvider;
import '../../state/settings_state.dart';
import '../../state/ui_mode_state.dart';
import 'web_target.dart';
import 'web_view_page.dart';

/// Where the active host's DSH Web can be opened from.
sealed class DshWebAccess {
  const DshWebAccess();
}

/// 飞牛主机：DSH 网页版就在飞牛统一网关的 `/app/deepseek-harness/fngateway`
/// 上；WebView 与登录共用同一份 Cookie，打开即已登录。
final class FnOsDshWeb extends DshWebAccess {
  const FnOsDshWeb(this.url, this.hostName);
  final Uri url;
  final String hostName;
}

/// No web page right now; [reason] says why.
final class NoDshWeb extends DshWebAccess {
  const NoDshWeb(this.reason);
  final String reason;
}

/// The active host's DSH Web, if it has one the app can reach.
final dshWebAccessProvider = Provider.autoDispose<DshWebAccess>((ref) {
  final host = ref.watch(fnosHostProvider);
  final config = host.config;
  final name = config?.name ?? config?.fnconnectId;
  if (config == null || name == null || !host.signedIn) {
    return NoDshWeb(appL10n.webConnectHostFirst(name ?? appL10n.commonRemoteHost));
  }
  return FnOsDshWeb(config.target.dshBaseUri, name);
});

/// A page that decides how it is left for DSH Web: [openDshWeb] from inside
/// it (its rows that say 「在网页版编辑此项」) hands the target to [onOpen]
/// instead, which lands it and goes there when the page can be left — a page
/// whose own edits DSH Web would otherwise race (plugin_config_page.dart).
class DshWebOpenScope extends InheritedWidget {
  const DshWebOpenScope({super.key, required this.onOpen, required super.child});

  final void Function(DshWebTarget target) onOpen;

  static DshWebOpenScope? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<DshWebOpenScope>();

  @override
  bool updateShouldNotify(DshWebOpenScope oldWidget) => false;
}

/// Opens the active host's official DSH Web, landing on [target]. In
/// 网页模式 the home page itself goes there (no second page on top). Inside
/// a [DshWebOpenScope] the page around decides.
void openDshWeb(BuildContext context, WidgetRef ref, {DshWebTarget target = const DshWebTarget()}) {
  if (DshWebOpenScope.maybeOf(context) case final scope?) {
    scope.onOpen(target);
    return;
  }
  // A plugin's entry id is no name its card has: name its bundle.
  if (target.pluginItem.isNotEmpty) target = target.withPluginNames(ref.read(installedPluginsProvider).value);
  if (ref.read(uiModeProvider).web) {
    ref.read(webOpenProvider.notifier).request(target);
    return;
  }
  final access = ref.read(dshWebAccessProvider);
  if (access is NoDshWeb) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(access.reason)));
    return;
  }
  final web = access as FnOsDshWeb;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WebViewPage(
        url: web.url,
        title: context.l10n.webTitle,
        subtitle: web.hostName,
        // Android suspends the page in the background and its socket drops.
        reloadAfterBackground: const Duration(seconds: 60),
        dshWeb: true,
        phoneLayout: ref.read(settingsProvider).webPhoneLayout,
        openTarget: target,
      ),
    ),
  );
}
