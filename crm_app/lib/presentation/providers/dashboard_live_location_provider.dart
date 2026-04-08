import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented each time the main shell switches to the Dashboard tab (including first open).
/// Used to refresh the attendance “live location” strip without a timer.
final dashboardVisitLiveLocationRefreshTickProvider = StateProvider<int>(
  (ref) => 0,
);
