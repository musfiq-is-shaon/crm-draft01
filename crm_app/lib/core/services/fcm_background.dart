import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../firebase_options.dart';
import 'fcm_data_message_display.dart';

/// Must be a top-level function; registered before [runApp].
///
/// **Data-only** messages (`data.title` / `data.body`, no `notification` block) do not
/// show a system notification by themselves — we display them with
/// [showFcmDataMessageAsLocalNotification] (same as production apps using silent push + local UI).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  if (kDebugMode) {
    debugPrint(
      'FCM background data keys=${message.data.keys} '
      'messageId=${message.messageId}',
    );
  }
  await showFcmDataMessageAsLocalNotification(message);
}
