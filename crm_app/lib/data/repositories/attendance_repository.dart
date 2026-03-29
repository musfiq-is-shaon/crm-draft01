import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/attendance_model.dart';

class AttendanceRepository {
  final ApiClient _apiClient;

  AttendanceRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get today's attendance status for user
  Future<TodayAttendance> getTodayAttendance(String userId) async {
    final response = await _apiClient.get(
      AppConstants.attendanceToday,
      queryParameters: {'userId': userId},
    );
    return TodayAttendance.fromJson(response.data);
  }

  /// Check-in for today
  Future<void> checkIn(String userId, String location) async {
    await _apiClient.post(
      AppConstants.attendanceCheckIn,
      data: {'userId': userId, 'location': location},
    );
  }

  /// Check-out for today
  Future<void> checkOut(String userId, String location) async {
    await _apiClient.post(
      AppConstants.attendanceCheckOut,
      data: {'userId': userId, 'location': location},
    );
  }

  /// Get attendance records for user
  Future<List<AttendanceRecord>> getRecords(
    String userId, {
    String period = 'month',
  }) async {
    final response = await _apiClient.get(
      AppConstants.attendanceRecords,
      queryParameters: {'userId': userId, 'period': period},
    );
    final List<dynamic> data = response.data;
    return data.map((json) => AttendanceRecord.fromJson(json)).toList();
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AttendanceRepository(apiClient: apiClient);
});
