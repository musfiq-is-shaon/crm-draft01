import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/attendance_reminder_controller.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../providers/notification_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/crm_card.dart';
import '../../widgets/shift_reminders_android_card.dart';

/// In-app education: why reminders can be late on some phones and what to change
/// (battery / autostart / alarms). Paths vary slightly by OS version; labels may differ.
class ReminderReliabilityGuidePage extends ConsumerWidget {
  const ReminderReliabilityGuidePage({super.key});

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get _isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _rescheduleAfterExactAlarm(WidgetRef ref) async {
    final tasks = ref.read(tasksProvider).tasks;
    await ref.read(notificationSettingsProvider.notifier).rescheduleNotifications(tasks);
    await scheduleAttendanceReminders(ref.read);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = AppThemeColors.backgroundColor(context);
    final textPrimary = AppThemeColors.textPrimaryColor(context);
    final textSecondary = AppThemeColors.textSecondaryColor(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppThemeColors.appBarTitle(
        context,
        'Reminder help',
      ),
      body: ListView(
        padding: AppThemeColors.pagePaddingAll,
        children: [
          Text(
            'Task deadlines and shift check-in reminders are scheduled on your phone. '
            'Some manufacturers add extra battery limits; if reminders are late or missing, '
            'use the checklist below, then open the section for your phone brand.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          CRMCard(
            child: Padding(
              padding: AppThemeColors.cardInsetPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick checklist',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _checkRow(
                    textPrimary,
                    textSecondary,
                    '1. Notifications are allowed for this app (system settings + toggle in Notification Settings here).',
                  ),
                  _checkRow(
                    textPrimary,
                    textSecondary,
                    _isAndroid
                        ? '2. On Android 12+: Alarms & reminders (exact alarms) allowed — use “Shift reminders” below.'
                        : _isIos
                            ? '2. On iPhone: allow notifications and Background App Refresh; check Focus / Do Not Disturb (iOS section below).'
                            : '2. On Android 12+, allow Alarms & reminders for on-time shift alerts when using the Android app.',
                  ),
                  _checkRow(
                    textPrimary,
                    textSecondary,
                    '3. Turn off aggressive battery limits for this app (brand steps below).',
                  ),
                ],
              ),
            ),
          ),
          if (_isAndroid) ...[
            SizedBox(height: AppSpacing.md),
            ShiftRemindersAndroidCard(
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
              onChanged: () => _rescheduleAfterExactAlarm(ref),
            ),
          ],
          SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await openAppSettings();
              },
              icon: const Icon(Icons.open_in_new, size: 20),
              label: const Text("Open this app's system settings"),
            ),
          ),
          if (_isAndroid) ...[
            SizedBox(height: AppSpacing.xl),
            Text(
              'Instructions by brand (Android)',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Menu names change with updates; search Settings for “battery”, “autostart”, or your app name.',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            SizedBox(height: AppSpacing.md),
            ..._brandCards(textPrimary, textSecondary),
          ],
          if (_isIos) ...[
            SizedBox(height: AppSpacing.lg),
            _iosCard(context, textPrimary, textSecondary),
          ],
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _checkRow(
    Color textPrimary,
    Color textSecondary,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.4, color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _brandCards(
    Color textPrimary,
    Color textSecondary,
  ) {
    final data = <_BrandSection>[
      _BrandSection(
        title: 'Samsung (One UI)',
        hint: 'Galaxy, Galaxy A/S/Z series',
        steps: [
          'Open Settings → Apps → find this CRM app.',
          'Tap Battery → choose Unrestricted (or “Optimized” → “Unrestricted”).',
          'Tap Notifications → ensure notifications are ON; show on Lock screen if you want.',
          'If you use Sleeping apps / Deep sleeping: remove this app from those lists.',
        ],
      ),
      _BrandSection(
        title: 'Xiaomi / Redmi / POCO (MIUI / HyperOS)',
        hint: 'Often needs Autostart + battery',
        steps: [
          'Open Security (or Phone Manager) → Permissions → Autostart → enable this app.',
          'Settings → Apps → Manage apps → this app → enable Autostart (and “Background activity” if shown).',
          'Settings → Battery → Battery saver / App battery saver → set this app to No restrictions.',
          'Settings → Notifications → App notifications → this app → allow all.',
        ],
      ),
      _BrandSection(
        title: 'OPPO / Realme / OnePlus (ColorOS / OxygenOS)',
        hint: 'Names vary by version',
        steps: [
          'Settings → Battery → Power saving settings → App battery management → this app → Don’t optimize / Allow background activity.',
          'Settings → Apps → App management → this app → enable Autostart / “Allow background activity”.',
          'Settings → Notifications → App notifications → this app → allow all categories.',
        ],
      ),
      _BrandSection(
        title: 'vivo',
        hint: 'Funtouch OS',
        steps: [
          'i Manager (or Settings) → App manager → Autostart → enable this app.',
          'Settings → Battery → High background power consumption → enable this app.',
          'Settings → Notifications → App notifications → this app → allow.',
        ],
      ),
      _BrandSection(
        title: 'Huawei / Honor',
        hint: 'EMUI / HarmonyOS',
        steps: [
          'Settings → Battery → App launch → this app → Manage manually → turn ON Auto-launch, Secondary launch, Run in background.',
          'Phone Manager → App launch → same toggles for this app.',
          'Settings → Apps → Apps → this app → Notifications → allow.',
        ],
      ),
      _BrandSection(
        title: 'Google Pixel & stock Android',
        hint: 'Usually fewer extra steps',
        steps: [
          'Settings → Apps → this app → Notifications → allow.',
          'Android 12+: use Alarms & reminders (Shift reminders card on this screen or Notification Settings).',
          'Settings → Apps → this app → Battery → Unrestricted if reminders are still delayed.',
        ],
      ),
      _BrandSection(
        title: 'Motorola, Nokia, Asus, Sony, other Android',
        hint: 'Similar ideas',
        steps: [
          'Settings → Apps → this app → Battery → Unrestricted / Not optimized.',
          'Settings → Apps → this app → Notifications → allow.',
          'Look for “Auto-start”, “Background activity”, or “Startup” in Settings search.',
        ],
      ),
    ];

    return data
        .map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BrandExpansionTile(
              section: b,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
        )
        .toList();
  }

  Widget _iosCard(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    return CRMCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          initiallyExpanded: true,
          title: Text(
            'iPhone (iOS)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          subtitle: Text(
            'Fewer battery limits; Focus can block alerts',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          children: [
            numberedSteps(
              textPrimary,
              textSecondary,
              [
                'Settings → Notifications → this app → Allow Notifications ON; enable Lock Screen and Banners.',
                'Settings → General → Background App Refresh → ON for this app (helps timely delivery).',
                'If Focus or Do Not Disturb is on, allow this app or disable Focus for work hours.',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandSection {
  final String title;
  final String hint;
  final List<String> steps;

  _BrandSection({
    required this.title,
    required this.hint,
    required this.steps,
  });
}

class _BrandExpansionTile extends StatelessWidget {
  final _BrandSection section;
  final Color textPrimary;
  final Color textSecondary;

  const _BrandExpansionTile({
    required this.section,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return CRMCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 4),
          title: Text(
            section.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          subtitle: Text(
            section.hint,
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: numberedSteps(
                textPrimary,
                textSecondary,
                section.steps,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared numbered list for brand steps.
Widget numberedSteps(
  Color textPrimary,
  Color textSecondary,
  List<String> steps,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < steps.length; i++) ...[
        if (i > 0) const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                steps[i],
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    ],
  );
}
