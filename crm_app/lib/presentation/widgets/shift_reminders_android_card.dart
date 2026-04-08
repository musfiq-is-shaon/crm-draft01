import 'package:flutter/material.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme_colors.dart';
import 'crm_card.dart';

/// Android 12+: [SCHEDULE_EXACT_ALARM] helps shift-start reminders fire on time.
class ShiftRemindersAndroidCard extends StatefulWidget {
  const ShiftRemindersAndroidCard({
    super.key,
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
  State<ShiftRemindersAndroidCard> createState() =>
      _ShiftRemindersAndroidCardState();
}

class _ShiftRemindersAndroidCardState extends State<ShiftRemindersAndroidCard> {
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
                    _exactOk == true
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
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
