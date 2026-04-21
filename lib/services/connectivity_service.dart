/*import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Small helper to gate network calls and surface a friendly offline message.
class ConnectivityService {
  ConnectivityService._();

  static final Connectivity _connectivity = Connectivity();

  /// Checks connectivity once. Shows a SnackBar if offline.
  static Future<bool> ensureConnected(
    BuildContext context, {
    String offlineMessage = 'Sin conexión a internet',
  }) async {
    final result = await _connectivity.checkConnectivity();
    // ignore: unrelated_type_equality_checks
    final isOnline = result != ConnectivityResult.none;
    if (!isOnline) {
      _showSnackBar(context, offlineMessage);
    }
    return isOnline;
  }

  /// Stream that emits true/false when connectivity changes.
  static Stream<bool> connectionStream() {
    return _connectivity.onConnectivityChanged.map(
      (status) => status != ConnectivityResult.none,
    );
  }

  /// Runs [action] only if online, otherwise shows a friendly message.
  static Future<T?> guard<T>(
    BuildContext context,
    Future<T> Function() action, {
    String offlineMessage = 'Sin conexión a internet',
  }) async {
    if (!await ensureConnected(context, offlineMessage: offlineMessage)) {
      return null;
    }
    return action();
  }

  static void _showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
*/