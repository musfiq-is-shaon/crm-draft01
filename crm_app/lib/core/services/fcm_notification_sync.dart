import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/notification_model.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/notifications_provider.dart';
import 'notification_service.dart';

/// Poll `/api/notifications` while the app is **foregrounded** so alerts appear even when the
/// backend does not send FCM (or FCM is delayed). Call on a timer + on resume.
///
/// Shows a tray notification only when a **new** row appears (id not seen before last fetch).
Future<void> pollForNewInAppNotifications(WidgetRef ref) async {
  if (ref.read(authProvider).status != AuthStatus.authenticated) return;

  final before = ref.read(notificationsProvider).items;
  final idsBefore = {for (final x in before) x.id};

  await ref.read(notificationsProvider.notifier).load(silent: true);

  final after = ref.read(notificationsProvider).items;

  NotificationItem? toShow;
  for (final i in after) {
    if (!i.isRead && !idsBefore.contains(i.id)) {
      toShow = i;
      break;
    }
  }
  if (toShow == null) return;

  // First-ever load: many rows at once — don't spam one tray per row.
  if (before.isEmpty && after.length > 2) {
    return;
  }

  final ns = NotificationService();
  await ns.initialize();
  await ns.showFcmForegroundNotification(
    title: toShow.displayTitle,
    body: toShow.displayMessage.isNotEmpty ? toShow.displayMessage : toShow.title,
    payload: toShow.id,
  );
}

/// After any FCM while the app is in the foreground: sync [notificationsProvider] from the API.
///
/// Server-driven attendance (and similar) alerts often create rows in `/api/notifications` while
/// sending a **silent** or minimal FCM (`data` only with `notificationId`, no title/body). The tray
/// only appeared after opening the app because that was the first time the list loaded.
Future<void> syncNotificationsAndMaybeShowTrayFromApi(
  WidgetRef ref,
  RemoteMessage message,
  bool alreadyShowedTrayFromFcmPayload,
) async {
  if (ref.read(authProvider).status != AuthStatus.authenticated) return;

  await ref.read(notificationsProvider.notifier).load(silent: true);

  if (alreadyShowedTrayFromFcmPayload) return;

  final data = message.data;
  final idHint = data['notificationId']?.toString().trim() ??
      data['notification_id']?.toString().trim() ??
      data['id']?.toString().trim();

  final items = ref.read(notificationsProvider).items;

  NotificationItem? pick;
  if (idHint != null && idHint.isNotEmpty) {
    for (final i in items) {
      if (i.id == idHint) {
        pick = i;
        break;
      }
    }
  }

  pick ??= _newestUnreadAttendanceRelated(items);
  pick ??= _newestUnreadByTime(items);

  if (pick == null) return;

  final ns = NotificationService();
  await ns.initialize();
  await ns.showFcmForegroundNotification(
    title: pick.displayTitle,
    body: pick.displayMessage.isNotEmpty ? pick.displayMessage : pick.title,
    payload: pick.id,
  );
}

NotificationItem? _newestUnreadAttendanceRelated(List<NotificationItem> items) {
  NotificationItem? best;
  DateTime? bestTime;
  for (final i in items) {
    if (i.isRead) continue;
    final blob = '${i.type ?? ''} ${i.title} ${i.message}'.toLowerCase();
    if (!blob.contains('attendance') &&
        !blob.contains('check-in') &&
        !blob.contains('check in') &&
        !blob.contains('shift') &&
        !blob.contains('check out') &&
        !blob.contains('checkout')) {
      continue;
    }
    final t = i.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final prev = bestTime;
    if (prev == null || t.isAfter(prev)) {
      bestTime = t;
      best = i;
    }
  }
  return best;
}

NotificationItem? _newestUnreadByTime(List<NotificationItem> items) {
  NotificationItem? best;
  DateTime? bestTime;
  for (final i in items) {
    if (i.isRead) continue;
    final t = i.createdAt;
    if (t == null) continue;
    final prev = bestTime;
    if (prev == null || t.isAfter(prev)) {
      bestTime = t;
      best = i;
    }
  }
  return best;
}
