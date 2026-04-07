import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task_model.dart';
import '../../../core/services/attendance_reminder_controller.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../providers/notification_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/crm_card.dart';

Future<void> _rescheduleTasksAndShiftAlerts(WidgetRef ref, List<Task> tasks) async {
  await ref.read(notificationSettingsProvider.notifier).rescheduleNotifications(tasks);
  await scheduleAttendanceReminders(ref.read);
}

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final settingsNotifier = ref.read(notificationSettingsProvider.notifier);
    final tasksState = ref.watch(tasksProvider);

    final bgColor = AppThemeColors.backgroundColor(context);
    final textPrimary = AppThemeColors.textPrimaryColor(context);
    final textSecondary = AppThemeColors.textSecondaryColor(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppThemeColors.appBarTitle(context, 'Notification Settings'),
      body: ListView(
        padding: AppThemeColors.pagePaddingAll,
        children: [
          // Enable/Disable Notifications Section
          _buildSection(
            title: 'Notifications',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            children: [
              Padding(
                padding: AppThemeColors.cardRowPadding,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Notifications',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Task deadlines and shift check-in reminders',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: settings.enabled,
                      onChanged: (value) async {
                        await settingsNotifier.setEnabled(value);
                        await _rescheduleTasksAndShiftAlerts(
                          ref,
                          tasksState.tasks,
                        );
                      },
                      activeThumbColor: primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppThemeColors.sectionGap),

          // Notification Timing Section
          _buildSection(
            title: 'When to notify',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            children: [
              _buildTimingOption(
                title: 'On due date',
                subtitle: 'Get notified when the task is due today',
                value: 0,
                selectedValue: settings.daysBefore,
                onTap: () async {
                  await settingsNotifier.setDaysBefore(0);
                  await _rescheduleTasksAndShiftAlerts(ref, tasksState.tasks);
                },
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                primaryColor: primaryColor,
              ),
              Divider(height: 1, color: AppThemeColors.borderColor(context)),
              _buildTimingOption(
                title: '1 day before',
                subtitle: 'Get notified one day before the deadline',
                value: 1,
                selectedValue: settings.daysBefore,
                onTap: () async {
                  await settingsNotifier.setDaysBefore(1);
                  await _rescheduleTasksAndShiftAlerts(ref, tasksState.tasks);
                },
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                primaryColor: primaryColor,
              ),
              Divider(height: 1, color: AppThemeColors.borderColor(context)),
              _buildTimingOption(
                title: '3 days before',
                subtitle: 'Get notified three days before the deadline',
                value: 3,
                selectedValue: settings.daysBefore,
                onTap: () async {
                  await settingsNotifier.setDaysBefore(3);
                  await _rescheduleTasksAndShiftAlerts(ref, tasksState.tasks);
                },
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                primaryColor: primaryColor,
              ),
              Divider(height: 1, color: AppThemeColors.borderColor(context)),
              _buildTimingOption(
                title: '7 days before',
                subtitle: 'Get notified one week before the deadline',
                value: 7,
                selectedValue: settings.daysBefore,
                onTap: () async {
                  await settingsNotifier.setDaysBefore(7);
                  await _rescheduleTasksAndShiftAlerts(ref, tasksState.tasks);
                },
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                primaryColor: primaryColor,
              ),
            ],
          ),
          SizedBox(height: AppThemeColors.sectionGap),

          // Info Card
          CRMCard(
            child: Padding(
              padding: AppThemeColors.cardInsetPadding,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Task alerts use your timing below. Shift check-in reminders notify 15 minutes before your shift, at shift start, and again 15 minutes after start (late threshold) when you have an assigned shift. '
                      'On Android 12 or newer, allow Alarms & reminders for this app; otherwise the system may delay or merge reminders when the app is not running.',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
            SizedBox(height: AppThemeColors.sectionGap),
            _AndroidExactAlarmsCard(
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
              onChanged: () async {
                await _rescheduleTasksAndShiftAlerts(
                  ref,
                  tasksState.tasks,
                );
              },
            ),
          ],
          SizedBox(height: AppThemeColors.sectionGap),

          // Test Notification Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final notificationService = NotificationService();
                await notificationService.sendTestNotification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Test Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor:
                    Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    Color? textPrimary,
    Color? textSecondary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppThemeColors.sectionHeaderLabelPadding,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ),
        CRMCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTimingOption({
    required String title,
    required String subtitle,
    required int value,
    required int selectedValue,
    required VoidCallback onTap,
    Color? textPrimary,
    Color? textSecondary,
    Color? primaryColor,
  }) {
    final isSelected = value == selectedValue;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: AppThemeColors.cardRowPadding,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: primaryColor, size: 22)
            else
              Icon(
                Icons.circle_outlined,
                color: textSecondary?.withValues(alpha: 0.3),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

/// Android 12+: [SCHEDULE_EXACT_ALARM] helps the shift-start reminder fire on time.
class _AndroidExactAlarmsCard extends StatefulWidget {
  const _AndroidExactAlarmsCard({
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
    required this.onChanged,
  });

  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;
  final Future<void> Function() onChanged;

  @override
  State<_AndroidExactAlarmsCard> createState() =>
      _AndroidExactAlarmsCardState();
}

class _AndroidExactAlarmsCardState extends State<_AndroidExactAlarmsCard> {
  bool? _exactOk;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final v = await NotificationService().canScheduleExactAlarmsAndroid();
    if (mounted) {
      setState(() {
        _exactOk = v;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CRMCard(
      child: Padding(
        padding: AppThemeColors.cardInsetPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alarm, color: widget.primaryColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Shift reminders (Android)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Shift-start check-in reminders use exact alarms. If this is off, Android may delay them when the app is closed.',
              style: TextStyle(fontSize: 13, color: widget.textSecondary),
            ),
            const SizedBox(height: 12),
            if (_loading)
              Text(
                'Checking…',
                style: TextStyle(fontSize: 13, color: widget.textSecondary),
              )
            else
              Row(
                children: [
                  Icon(
                    _exactOk == true ? Icons.check_circle : Icons.warning_amber_rounded,
                    size: 20,
                    color: _exactOk == true
                        ? widget.primaryColor
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _exactOk == true
                          ? 'Alarms & reminders allowed'
                          : 'Alarms & reminders not allowed — tap to fix',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () async {
                        await NotificationService().requestExactAlarmsAndroid();
                        await _refresh();
                        await widget.onChanged();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _exactOk == true
                                    ? 'Exact alarms enabled. Shift reminders rescheduled.'
                                    : 'If you turned on Alarms & reminders, shift reminders were rescheduled.',
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.settings_suggest_outlined, size: 20),
                label: const Text('Open alarm permission'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
