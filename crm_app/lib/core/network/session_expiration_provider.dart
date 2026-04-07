import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented when a protected API call returns 401 so the UI can sign out without
/// [apiClientProvider] depending on [authProvider] (would be circular).
final sessionExpirationTickProvider =
    StateNotifierProvider<SessionExpirationNotifier, int>((ref) {
  return SessionExpirationNotifier();
});

class SessionExpirationNotifier extends StateNotifier<int> {
  SessionExpirationNotifier() : super(0);

  void notifySessionExpired() => state++;
}
