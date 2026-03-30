import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/location_service.dart';
import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../providers/auth_provider.dart';

/// Sentinel so [AttendanceState.copyWith] can distinguish "omit" from explicit null.
enum _LocalField { unset }

class AttendanceState {
  final TodayAttendance? todayAttendance;
  final List<AttendanceRecord> records;
  final bool isLoading;
  final String? error;
  final String period; // 'today', 'week', 'month', etc.

  /// Shown when API omits [TodayAttendance.locationIn] after check-in.
  final String? localCheckInLocation;

  /// Shown when API omits [TodayAttendance.locationOut] after check-out.
  final String? localCheckOutLocation;

  const AttendanceState({
    this.todayAttendance,
    this.records = const [],
    this.isLoading = false,
    this.error,
    this.period = 'month',
    this.localCheckInLocation,
    this.localCheckOutLocation,
  });

  AttendanceState copyWith({
    TodayAttendance? todayAttendance,
    List<AttendanceRecord>? records,
    bool? isLoading,
    String? error,
    String? period,
    Object? localCheckInLocation = _LocalField.unset,
    Object? localCheckOutLocation = _LocalField.unset,
  }) {
    return AttendanceState(
      todayAttendance: todayAttendance ?? this.todayAttendance,
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      period: period ?? this.period,
      localCheckInLocation: localCheckInLocation == _LocalField.unset
          ? this.localCheckInLocation
          : localCheckInLocation as String?,
      localCheckOutLocation: localCheckOutLocation == _LocalField.unset
          ? this.localCheckOutLocation
          : localCheckOutLocation as String?,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AttendanceRepository _repository;
  final Ref ref;

  /// Last user id we merged local fallbacks for; used to drop stale locals on account switch.
  String? _lastLoadedUserId;

  AttendanceNotifier(this._repository, this.ref)
    : super(const AttendanceState()) {
    // Initial load
    loadToday();
  }

  /// Load today's attendance status with validation
  Future<void> loadToday() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      _lastLoadedUserId = null;
      state = const AttendanceState(
        isLoading: false,
        error: 'User not authenticated',
      );
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final today = await _repository.getTodayAttendance();

      final prevDate = state.todayAttendance?.date ?? '';
      final newDate = today.date;
      final dateChanged =
          prevDate.isNotEmpty && newDate.isNotEmpty && prevDate != newDate;

      final userChanged = _lastLoadedUserId != null &&
          _lastLoadedUserId != currentUserId;

      final serverIn = today.locationIn?.trim() ?? '';
      final serverOut = today.locationOut?.trim() ?? '';

      String? mergedLocalIn;
      String? mergedLocalOut;
      if (dateChanged || userChanged) {
        mergedLocalIn = null;
        mergedLocalOut = null;
      } else {
        mergedLocalIn = serverIn.isEmpty
            ? state.localCheckInLocation
            : (LocationService.looksLikeCoordinatesString(serverIn)
                  ? state.localCheckInLocation
                  : null);
        mergedLocalOut = serverOut.isEmpty
            ? state.localCheckOutLocation
            : (LocationService.looksLikeCoordinatesString(serverOut)
                  ? state.localCheckOutLocation
                  : null);
      }

      _lastLoadedUserId = currentUserId;
      state = AttendanceState(
        todayAttendance: today,
        records: state.records,
        isLoading: false,
        error: null,
        period: state.period,
        localCheckInLocation: mergedLocalIn,
        localCheckOutLocation: mergedLocalOut,
      );
    } catch (e) {
      debugPrint('❌ Attendance load error: $e');
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
      _lastLoadedUserId = null;
      state = const AttendanceState(
        isLoading: false,
        error: 'User not authenticated',
      );
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final records = await _repository.getRecords(period: period);
      state = state.copyWith(
        records: records,
        period: period,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// [coordinatesPayload] is sent to the API (e.g. `lat, lng`).
  /// [placeLabel] is shown on the dashboard when the API omits a human address.
  Future<void> checkIn(String coordinatesPayload, String placeLabel) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }
    try {
      debugPrint(
        '🟢 Check-in API call: userId=$currentUserId location=$coordinatesPayload',
      );
      await _repository.checkIn(coordinatesPayload);
      final label = placeLabel.trim();
      state = state.copyWith(
        localCheckInLocation: label.isNotEmpty ? label : null,
      );
      debugPrint('🔄 Reloading after check-in...');
      // Multiple refreshes to ensure backend sync
      await Future.delayed(const Duration(seconds: 1));
      await loadToday();
      await Future.delayed(const Duration(seconds: 1));
      await loadToday();
      state = state.copyWith();
      debugPrint('✅ Check-in complete, state: ${state.todayAttendance?.safeStatus}');
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

  /// [coordinatesPayload] is sent to the API (e.g. `lat, lng`).
  /// [placeLabel] is shown on the dashboard when the API omits a human address.
  Future<void> checkOut(String coordinatesPayload, String placeLabel) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }
    try {
      debugPrint(
        '🔴 Check-out API call: userId=$currentUserId location=$coordinatesPayload',
      );
      await _repository.checkOut(coordinatesPayload);
      final label = placeLabel.trim();
      state = state.copyWith(
        localCheckOutLocation: label.isNotEmpty ? label : null,
      );
      debugPrint('🔄 Reloading after check-out...');
      // Multiple refreshes to ensure backend sync
      await Future.delayed(const Duration(seconds: 1));
      await loadToday();
      await Future.delayed(const Duration(seconds: 1));
      await loadToday();
      state = state.copyWith();
      debugPrint(
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
