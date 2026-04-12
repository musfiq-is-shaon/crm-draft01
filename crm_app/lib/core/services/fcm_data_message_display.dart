import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// FCM **data** payload (not `notification`) — matches server JSON:
/// `"data": { "title": "...", "body": "..." }` with HTTP `priority: "high"`.
///
/// Server must send **data-only** messages so Flutter receives [RemoteMessage.data]
/// in foreground, background, and terminated states (behavior differs from
/// notification+data hybrid messages on some platforms).
class FcmDataPayload {
  const FcmDataPayload({required this.title, required this.body});

  final String title;
  final String body;

  /// Reads only [RemoteMessage.data] (no [RemoteMessage.notification]).
  static FcmDataPayload? parse(RemoteMessage message) {
    final d = message.data;
    final title = d['title']?.toString().trim() ?? '';
    final body = d['body']?.toString().trim() ?? '';
    if (title.isEmpty && body.isEmpty) {
      return null;
    }
    return FcmDataPayload(
      title: title.isEmpty ? 'Notification' : title,
      body: body,
    );
  }
}

/// Shows a local notification from **data-only** FCM — required in the background
/// isolate because the system does not render a tray notification for data-only
/// payloads (unlike messages that include a `notification` block).
Future<void> showFcmDataMessageAsLocalNotification(RemoteMessage message) async {
  final parsed = FcmDataPayload.parse(message);
  if (parsed == null) {
    if (kDebugMode) {
      debugPrint(
        'FCM data message skipped: empty data.title/data.body keys=${message.data.keys}',
      );
    }
    return;
  }

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  const channel = AndroidNotificationChannel(
    'crm_fcm_default',
    'Push notifications',
    description: 'Real-time data messages (Firebase)',
    importance: Importance.high,
    playSound: true,
    showBadge: true,
  );
  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final nid = _notificationIdFor(message);

  await plugin.show(
    nid,
    parsed.title,
    parsed.body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'crm_fcm_default',
        'Push notifications',
        channelDescription: 'Real-time data messages (Firebase)',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        channelShowBadge: true,
        visibility: NotificationVisibility.public,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: message.data.isNotEmpty ? message.data.toString() : message.messageId,
  );
}

int _notificationIdFor(RemoteMessage message) {
  final mid = message.messageId;
  if (mid != null && mid.isNotEmpty) {
    return mid.hashCode & 0x3fffffff;
  }
  return message.hashCode & 0x3fffffff;
}
