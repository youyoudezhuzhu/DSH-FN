// Leaves the app and comes back, the way Android reports it.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> awayAndBack(WidgetTester tester) async {
  for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  for (final state in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
