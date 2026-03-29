import 'user_model.dart';

class TodayAttendance {
  final String userId;
  final String status; // 'pending', 'checked_in', 'checked_out', 'completed'
  final String date; // '2025-01-20'
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final bool isLate;
  final int? lateMinutes;
  final double? totalHours;
  final String? locationIn;
  final String? locationOut;

  TodayAttendance({
    required this.userId,
    required this.status,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.isLate,
    this.lateMinutes,
    this.totalHours,
    this.locationIn,
    this.locationOut,
  });

  factory TodayAttendance.fromJson(Map<String, dynamic> json) {
    DateTime? checkInTime;
    if (json['checkInTime'] != null) {
      checkInTime = DateTime.tryParse(json['checkInTime'].toString());
      if (checkInTime != null) {
        // Fix timezone offset (UTC to local)
        checkInTime = checkInTime.add(const Duration(hours: 6));
      }
    }
    DateTime? checkOutTime;
    if (json['checkOutTime'] != null) {
      checkOutTime = DateTime.tryParse(json['checkOutTime'].toString());
      if (checkOutTime != null) {
        // Fix timezone offset (UTC to local)
        checkOutTime = checkOutTime.add(const Duration(hours: 6));
      }
    }
    return TodayAttendance(
      userId: json['userId'] ?? '',
      status: json['status'] ?? 'pending',
      date: json['date'] ?? '',
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      isLate: json['isLate'] ?? false,
      lateMinutes: json['lateMinutes'],
      totalHours: json['totalHours']?.toDouble(),
      locationIn: json['locationIn'],
      locationOut: json['locationOut'],
    );
  }

  bool get isPending => status == 'pending';
  bool get isCheckedIn => status == 'checked_in';
  bool get isCheckedOut => status == 'checked_out' || status == 'completed';

  /// Returns true if this attendance record is for the device's current calendar day.
  bool get isToday {
    if (date.isEmpty) return true;
    final today = DateTime.now();
    final recordDate = DateTime.tryParse(date);
    if (recordDate != null) {
      return recordDate.year == today.year &&
          recordDate.month == today.month &&
          recordDate.day == today.day;
    }
    final dayPart = date.contains('T') ? date.split('T').first : date;
    final parts = dayPart.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return y == today.year && m == today.month && d == today.day;
      }
    }
    // Lenient: unknown format on /today payload — still drive UI from times/status
    return true;
  }

  /// Returns true if attendance has valid complete cycle
  bool get hasValidAttendance {
    return (checkInTime != null && checkOutTime != null) ||
        status == 'completed';
  }

  /// Returns true if checked in but not checked out
  bool get isIncomplete => isCheckedIn && !isCheckedOut;

  String get _statusNorm => status.toLowerCase().trim();

  /// Both check-in and check-out are done (times and/or API status).
  bool get isAttendanceFlowCompleted {
    if (checkInTime != null && checkOutTime != null) return true;
    return _statusNorm == 'checked_out' || _statusNorm == 'completed';
  }

  /// Checked in for today but checkout still required.
  bool get needsCheckOut {
    if (isAttendanceFlowCompleted) return false;
    return checkInTime != null || _statusNorm == 'checked_in';
  }

  /// Safe status for UI: pending → checked_in (still pending day) → completed.
  String get safeStatus {
    if (!isToday) return 'pending';
    if (isAttendanceFlowCompleted) return 'completed';
    if (needsCheckOut) return 'checked_in';
    return 'pending';
  }
}

class AttendanceRecord {
  final String userId;
  final String id;
  final String date; // '2025-01-20'
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? durationHours;
  final String status; // 'present', 'late', 'early_leave', 'absent', 'half_day'
  final String? locationIn;
  final String? locationOut;
  final DateTime createdAt;
  final User? user; // for admin all-users view

  AttendanceRecord({
    required this.userId,
    required this.id,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.durationHours,
    required this.status,
    this.locationIn,
    this.locationOut,
    required this.createdAt,
    this.user,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      userId: json['userId'] ?? '',
      id: json['id']?.toString() ?? '',
      date: json['date'] ?? '',
      checkInTime: json['checkInTime'] != null
          ? DateTime.tryParse(json['checkInTime'].toString())
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.tryParse(json['checkOutTime'].toString())
          : null,
      durationHours: json['durationHours']?.toDouble(),
      status: json['status'] ?? 'absent',
      locationIn: json['locationIn'],
      locationOut: json['locationOut'],
      createdAt:
          DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now(),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}
