// A fixed active host for widget tests that do not exercise host switching.

import 'package:dsh_app/state/hosts_state.dart';

class FixedActiveHost extends ActiveHostController {
  FixedActiveHost(this.host);

  final HostRef host;

  @override
  HostRef build() => host;
}
