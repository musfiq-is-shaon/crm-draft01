import 'package:flutter/widgets.dart';

/// Root [Navigator] key for [MaterialApp] — used for in-app banners when the app is
/// foregrounded (system tray behavior varies by OEM/OS).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
