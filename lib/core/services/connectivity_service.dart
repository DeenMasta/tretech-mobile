import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity state
enum ConnectivityStatus { online, offline, unknown }

/// Riverpod provider for real-time connectivity monitoring
final connectivityProvider =
    StreamProvider<ConnectivityStatus>((ref) async* {
  final connectivity = Connectivity();

  await for (final result in connectivity.onConnectivityChanged) {
    if (result.contains(ConnectivityResult.none)) {
      yield ConnectivityStatus.offline;
    } else {
      yield ConnectivityStatus.online;
    }
  }
});

/// Convenience provider — is the device online?
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityProvider);
  return status.maybeWhen(
    data: (s) => s == ConnectivityStatus.online,
    orElse: () => true, // assume online until proven otherwise
  );
});
