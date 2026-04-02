import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/user_repository.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  final List<NotificationItem> items;
  final bool isLoading;
  final String? error;

  int get unreadCount => items.where((e) => !e.isRead).length;

  NotificationsState copyWith({
    List<NotificationItem>? items,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}

const Object _sentinel = Object();

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(
    this._repository,
    this._userRepository,
    this._taskRepository,
  ) : super(const NotificationsState());

  final NotificationRepository _repository;
  final UserRepository _userRepository;
  final TaskRepository _taskRepository;

  Future<List<NotificationItem>> _resolveActorNames(
    List<NotificationItem> items,
  ) async {
    final needIds = <String>{};
    for (final i in items) {
      if (i.actorDisplayName != null && i.actorDisplayName!.trim().isNotEmpty) {
        continue;
      }
      final id = i.actorUserId;
      if (id != null && id.isNotEmpty) needIds.add(id);
    }
    if (needIds.isEmpty) return items;

    try {
      final users = await _userRepository.getUsers();
      final idToName = {for (final u in users) u.id: u.name};
      return items.map((i) {
        final id = i.actorUserId;
        if (id == null || id.isEmpty) return i;
        final name = idToName[id];
        if (name == null || name.isEmpty) return i;
        return i.copyWithResolvedActor(name);
      }).toList();
    } catch (_) {
      return items;
    }
  }

  /// When the API only sends "someone" but includes a task id, use the latest task log actor.
  Future<List<NotificationItem>> _enrichActorFromTaskLogs(
    List<NotificationItem> items,
  ) async {
    final taskIds = <String>{};
    for (final i in items) {
      if (!i.needsActorEnrichment) continue;
      final tid = i.relatedTaskId;
      if (tid != null && tid.isNotEmpty) taskIds.add(tid);
    }
    if (taskIds.isEmpty) return items;

    final taskIdToName = <String, String>{};
    for (final tid in taskIds) {
      try {
        final logs = await _taskRepository.getTaskLogs(tid);
        if (logs.isEmpty) continue;
        final sorted = [...logs]..sort(
            (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
          );
        for (final log in sorted) {
          final n = log.actorUser?.name.trim();
          if (n != null && n.isNotEmpty) {
            taskIdToName[tid] = n;
            break;
          }
          final uid = log.actorUserId;
          if (uid != null && uid.isNotEmpty) {
            try {
              final u = await _userRepository.getUserById(uid);
              if (u != null && u.name.trim().isNotEmpty) {
                taskIdToName[tid] = u.name.trim();
                break;
              }
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
    if (taskIdToName.isEmpty) return items;

    return items.map((i) {
      if (!i.needsActorEnrichment) return i;
      final tid = i.relatedTaskId;
      if (tid == null) return i;
      final n = taskIdToName[tid];
      if (n == null || n.isEmpty) return i;
      return i.copyWithResolvedActor(n);
    }).toList();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      var items = await _repository.getMyNotifications();
      items = await _resolveActorNames(items);
      items = await _enrichActorFromTaskLogs(items);
      state = NotificationsState(items: items, isLoading: false);
    } catch (e) {
      state = NotificationsState(
        items: state.items,
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    await load(silent: true);
  }

  Future<void> markAllRead() async {
    await _repository.markAllRead();
    await load(silent: true);
  }

  Future<void> deleteOne(String id) async {
    await _repository.deleteNotification(id);
    await load(silent: true);
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(
    ref.watch(notificationRepositoryProvider),
    ref.watch(userRepositoryProvider),
    ref.watch(taskRepositoryProvider),
  );
});
