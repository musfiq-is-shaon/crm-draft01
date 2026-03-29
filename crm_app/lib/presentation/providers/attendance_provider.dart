import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../providers/auth_provider.dart';
import 'dart:async' show Timer;

class AttendanceState {
  final TodayAttendance? todayAttendance;
  final List<AttendanceRecord> records;
  final bool isLoading;
  final String? error;
  final String period; // 'today', 'week', 'month', etc.

  const AttendanceState({
    this.todayAttendance,
    this.records = const [],
    this.isLoading = false,
    this.error,
    this.period = 'month',
  });

  AttendanceState copyWith({
    TodayAttendance? todayAttendance,
    List<AttendanceRecord>? records,
    bool? isLoading,
    String? error,
    String? period,
  }) {
    return AttendanceState(
      todayAttendance: todayAttendance ?? this.todayAttendance,
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      period: period ?? this.period,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AttendanceRepository _repository;
  final Ref ref;
  Timer? _refreshTimer;

  AttendanceNotifier(this._repository, this.ref)
    : super(const AttendanceState()) {
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      loadToday();
    });
    // Initial load
    loadToday();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Load today's attendance status with validation
  Future<void> loadToday() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      state = state.copyWith(isLoading: false, error: 'User not authenticated');
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final today = await _repository.getTodayAttendance(currentUserId);
      // Validate: use safeStatus and log if suspicious
      print(
        '📅 Attendance loaded: ${today.safeStatus} for date ${today.date} (isToday: ${today.isToday})',
      );
      if (!today.isToday) {
        print('⚠️  Warning: Attendance date ${today.date} != today');
      }
      state = state.copyWith(todayAttendance: today, isLoading: false);
    } catch (e) {
      print('❌ Attendance load error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Manual refresh trigger
  Future<void> refreshNow() async {
    await loadToday();
  }

  /// Load attendance records for period
  Future<void> loadRecords({String period = 'month'}) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      state = state.copyWith(isLoading: false, error: 'User not authenticated');
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final records = await _repository.getRecords(
        currentUserId,
        period: period,
      );
      state = state.copyWith(
        records: records,
        period: period,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Perform check-in
  Future<void> checkIn(String location) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }
    try {
      print('🟢 Check-in API call: userId=$currentUserId location=$location');
      await _repository.checkIn(currentUserId, location);
      print('🔄 Reloading after check-in...');
      // Multiple refreshes to ensure backend sync
      await Future.delayed(const Duration(seconds: 1));
      await loadToday();
      await Future.delayed(const Duration(seconds: 1));
      await loadToday();
      state = state.copyWith();
      print('✅ Check-in complete, state: ${state.todayAttendance?.safeStatus}');
    } catch (e) {
      String errorMsg = 'Something went wrong. Please try again.';
      if (e.toString().contains('Already checked in')) {
        errorMsg = 'Already checked in today';
      } else if (e.toString().contains('Already checked out')) {
        errorMsg = 'Already checked out today';
      }
      state = state.copyWith(error: errorMsg);
      // Auto clear error after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        state = state.copyWith(error: null);
      });
    }
  }

  /// Perform check-out
  Future<void> checkOut(String location) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }
    try {
      print('🔴 Check-out API call: userId=$currentUserId location=$location');
      await _repository.checkOut(currentUserId, location);
      print('🔄 Reloading after check-out...');
      // Multiple refreshes to ensure backend sync
      await Future.delayed(const Duration(seconds: 1));
      await loadToday();
      await Future.delayed(const Duration(seconds: 1));
      await loadToday();
      state = state.copyWith();
      print(
        '✅ Check-out complete, state: ${state.todayAttendance?.safeStatus}',
      );
    } catch (e) {
      String errorMsg = 'Something went wrong. Please try again.';
      if (e.toString().contains('Already checked out')) {
        errorMsg = 'Already checked out today';
      }
      state = state.copyWith(error: errorMsg);
      // Auto clear error after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        state = state.copyWith(error: null);
      });
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
      final repository = ref.watch(attendanceRepositoryProvider);
      return AttendanceNotifier(repository, ref);
    });
