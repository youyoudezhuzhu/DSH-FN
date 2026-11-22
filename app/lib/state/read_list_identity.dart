import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dsh_client/dsh_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../runtime/local_paths.dart';
import '../runtime/runtime_bridge.dart';
import '../runtime/runtime_state.dart';
import 'connection_state.dart';
import 'hosts_state.dart';
import 'read_list_epoch.dart';

/// The source of a *display* snapshot. No endpoint token, password, header or
/// credential value is retained. The format version separates future DTOs.
class ReadListIdentity {
  const ReadListIdentity(this.digest);

  factory ReadListIdentity.of(List<Object?> fields) =>
      ReadListIdentity(sha256.convert(utf8.encode(jsonEncode([1, ...fields]))).toString());

  final String digest;

  @override
  bool operator ==(Object other) => other is ReadListIdentity && digest == other.digest;
  @override
  int get hashCode => digest.hashCode;
}

/// Resolve the real root asynchronously. An absent/unknown root is not an
/// identity. Installation changes retry the resolution; start/stop does not.
final localReadListRootProvider = FutureProvider<String?>((ref) async {
  ref.watch(
    localRuntimeProvider.select(
      (s) => (
        s.status.installedVersion,
        s.status.phase == RuntimePhase.installing || s.status.phase == RuntimePhase.notInstalled,
      ),
    ),
  );
  try {
    final root = LocalPaths.root ?? '${(await getApplicationSupportDirectory()).path}/runtime/rootfs';
    return await Directory(root).resolveSymbolicLinks();
  } on Object {
    return null;
  }
});

typedef _ReadListMux = ({DshConnectionState state, MuxGeneration? generation});

final _readListMuxProvider = StreamProvider.autoDispose.family<_ReadListMux, DshClient>(
  (ref, client) => Stream.multi((controller) {
    // Subscribe and sample without an await gap; a lost state must not be
    // missed between the initial value and the following events.
    final sub = client.mux.states.listen(
      (_) => controller.addSync((state: client.mux.state, generation: client.mux.generation)),
      onError: controller.addErrorSync,
      onDone: controller.closeSync,
    );
    controller.addSync((state: client.mux.state, generation: client.mux.generation));
    controller.onCancel = sub.cancel;
  }),
);

/// A previous connection carried through AsyncLoading is not a live source.
/// In particular, an unknown SSH selection can fall back to the local engine
/// in activeConnectionProvider; that fallback never qualifies for this cache.
HostConnection? readListConnection(AsyncValue<HostConnection?> value, HostRef selected) {
  if (value.isLoading || value.hasError) return null;
  final connection = value.value;
  if (connection == null || connection.kind != selected.kind) return null;
  if (!selected.isLocal && connection.hostId != selected.id) return null;
  return connection;
}

/// RemoteConnectionController can retain its last client during reconnect.
/// Observed mux loss therefore revokes the *live display authority* too.
/// Listening to states does not open/start a client or the local engine.
final readListLiveConnectionProvider = Provider<HostConnection?>((ref) {
  final connection = readListConnection(ref.watch(activeConnectionProvider), ref.watch(activeHostProvider));
  if (connection == null) return null;
  final status = ref.watch(_readListMuxProvider(connection.client)).value?.state ?? connection.client.mux.state;
  if (status == DshConnectionState.reconnecting ||
      status == DshConnectionState.unauthorized ||
      status == DshConnectionState.closed) {
    return null;
  }
  return connection;
});

final readListIdentityProvider = Provider<ReadListIdentity?>((ref) {
  final selected = ref.watch(activeHostProvider);
  final epoch = ref.watch(readListCredentialEpochProvider);
  final connection = readListConnection(ref.watch(activeConnectionProvider), selected);
  // Host credential events cover writes from other clients while connected.
  // Offline external changes are unknowable: cached rows remain explicitly
  // stale/read-only and expire, rather than claiming current authorization.
  if (connection != null) {
    // A ready generation can change without changing the client/API object or
    // retained account display fields. Its identity proof must recompute now,
    // before a model response can be stamped with the old account's key.
    ref.watch(_readListMuxProvider(connection.client));
    final sub = connection.client.hostEvents.listen((event) {
      if (event is CredentialUpdatedEvent || event is UnknownHostEvent && event.event == 'credentials/record-updated') {
        if (ref.mounted) ref.read(readListCredentialEpochProvider.notifier).advance();
      }
    });
    ref.onDispose(() => unawaited(sub.cancel()));
  }

  switch (selected.kind) {
    case HostKind.fnos:
      // One remote host: identity follows the fnconnect ID, this client and the
      // credential epoch. Nothing on the phone can change it behind the cache.
      final config = ref.watch(fnosHostProvider.select((s) => s.config));
      if (config == null) return null;
      final id = config.fnconnectId;
      if (id.isEmpty || id.length > 256) return null;
      return ReadListIdentity.of(['fnos', id, '${connection?.client.hashCode ?? 0}', epoch]);
  }
});
