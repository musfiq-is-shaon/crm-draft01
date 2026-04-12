import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'fcm_data_message_display.dart';
import 'notification_service.dart';

/// Firebase Cloud Messaging: real-time push alongside existing local notifications.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  bool _started = false;

  /// Returns false if Firebase failed to start (app still runs on local notifications only).
  Future<bool> initialize() async {
    if (_started) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e, st) {
      debugPrint('Firebase.initializeApp failed: $e\n$st');
      return false;
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);

    // Foreground: we show one notification via [NotificationService.showInstantNotification]
    // in [_onForegroundMessage]. Do not also enable iOS system banners here or users get
    // duplicate alerts when the payload includes a `notification` block.

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('FCM opened app: ${message.messageId}');
      }
    });

    messaging.onTokenRefresh.listen((token) {
      if (kDebugMode) {
        debugPrint('FCM token refreshed (len=${token.length})');
      }
    });

    try {
      final token = await messaging.getToken();
      if (kDebugMode && token != null) {
        final t = token.length > 32 ? '${token.substring(0, 32)}…' : token;
        debugPrint('FCM token (register with your backend if needed): $t');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM getToken failed (expected until Firebase is configured): $e');
      }
    }

    _started = true;
    return true;
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    // Data-only contract: title/body live under [RemoteMessage.data] (not [RemoteMessage.notification]).
    final parsed = FcmDataPayload.parse(message);
    if (parsed == null) return;

    final notifications = NotificationService();
    await notifications.initialize();
    await notifications.showFcmForegroundNotification(
      title: parsed.title,
      body: parsed.body,
      payload: message.data.isNotEmpty ? message.data.toString() : message.messageId,
    );
  }
}
