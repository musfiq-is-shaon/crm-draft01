import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  NotificationRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<NotificationItem>> getMyNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _api.get(
      AppConstants.notifications,
      queryParameters: {'limit': limit, 'offset': offset},
    );
    var rows = _parseList(response.data);
    if (rows.isEmpty) {
      final fallback = await _api.get(AppConstants.notifications);
      rows = _parseList(fallback.data);
    }
    final items = <NotificationItem>[];
    for (final raw in rows) {
      try {
        final item = NotificationItem.fromJson(raw);
        if (item.id.isEmpty) continue;
        items.add(item);
      } catch (_) {
        // Skip malformed rows so one bad record does not break the list for everyone.
      }
    }
    return items;
  }

  Future<void> markAsRead(String notificationId) async {
    await _api.patch(AppConstants.notificationRead(notificationId));
  }

  Future<void> markAllRead() async {
    await _api.patch(AppConstants.notificationsReadAll);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _api.delete(AppConstants.notificationById(notificationId));
  }
}

List<Map<String, dynamic>> _parseList(dynamic body) {
  if (body is String) {
    final t = body.trim();
    if (t.isEmpty) return [];
    try {
      return _parseList(jsonDecode(t));
    } catch (_) {
      return [];
    }
  }
  final direct = _extractList(body);
  if (direct.isNotEmpty) return direct;
  return [];
}

List<Map<String, dynamic>> _extractList(dynamic node) {
  if (node is List) {
    return node
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  if (node is Map) {
    final m = Map<String, dynamic>.from(node);
    for (final key in const [
      'data',
      'notifications',
      'notification',
      'items',
      'results',
      'rows',
      'docs',
      'list',
      'payload',
      'result',
      'content',
      'records',
      'user_notifications',
    ]) {
      final v = m[key];
      if (v == null) continue;
      if (v is Map) {
        final got = _extractList(v);
        if (got.isNotEmpty) return got;
        continue;
      }
      final got = _extractList(v);
      if (got.isNotEmpty) return got;
    }
    // Single notification object at root (no wrapper list)
    if (_looksLikeNotificationRow(m)) {
      return [m];
    }
    for (final v in m.values) {
      final got = _extractList(v);
      if (got.isNotEmpty) return got;
    }
  }
  return const [];
}

bool _looksLikeNotificationRow(Map<String, dynamic> m) {
  final hasId = m['id'] != null ||
      m['_id'] != null ||
      m['notificationId'] != null ||
      m['notification_id'] != null;
  final hasText = m['title'] != null ||
      m['message'] != null ||
      m['body'] != null ||
      m['content'] != null ||
      m['subject'] != null;
  return hasId && hasText;
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(apiClient: ref.watch(apiClientProvider));
});
