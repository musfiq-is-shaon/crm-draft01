import 'dart:convert';

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    required this.isRead,
    this.createdAt,
    this.updatedAt,
    this.actorDisplayName,
    this.actorUserId,
    this.relatedTaskId,
  });

  final String id;
  final String title;
  final String message;
  final String? type;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Resolved from API fields (e.g. nested user) so UI can show who acted.
  final String? actorDisplayName;

  /// When the API sends an id but no embedded name, the app resolves via [UserRepository].
  final String? actorUserId;

  /// Task id when the notification is about a task (used to load task logs for actor name).
  final String? relatedTaskId;

  /// True when text still uses a generic placeholder and we may enrich from APIs.
  bool get needsActorEnrichment {
    if (actorDisplayName != null && actorDisplayName!.trim().isNotEmpty) {
      return false;
    }
    final combined = '${title.toLowerCase()} ${message.toLowerCase()}';
    return combined.contains('someone') ||
        combined.contains('somebody') ||
        combined.contains('a user') ||
        combined.contains('another user');
  }

  NotificationItem copyWithResolvedActor(String name) {
    final n = name.trim();
    if (n.isEmpty) return this;
    if (actorDisplayName != null && actorDisplayName!.trim().isNotEmpty) {
      return this;
    }
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead,
      createdAt: createdAt,
      updatedAt: updatedAt,
      actorDisplayName: n,
      actorUserId: actorUserId,
      relatedTaskId: relatedTaskId,
    );
  }

  /// [title] with placeholders like "someone" replaced by [actorDisplayName] when present.
  String get displayTitle =>
      _substituteActorPlaceholders(title, actorDisplayName);

  /// [message] with placeholders like "someone" replaced by [actorDisplayName] when present.
  String get displayMessage =>
      _substituteActorPlaceholders(message, actorDisplayName);

  factory NotificationItem.fromJson(Map<String, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    final actor = _extractActorDisplayName(json);
    final actorId = _nonEmptyString(
      json['actorUserId'] ??
          json['actor_user_id'] ??
          json['changedByUserId'] ??
          json['changed_by_user_id'] ??
          json['performedByUserId'] ??
          json['createdByUserId'] ??
          json['created_by_user_id'],
    );
    var taskId = _extractRelatedTaskId(json);
    taskId ??= _deepFindRelatedTaskId(json);
    return NotificationItem(
      id: (json['id'] ??
              json['_id'] ??
              json['notificationId'] ??
              json['notification_id'] ??
              json['uuid'])
          ?.toString() ??
          '',
      title: _pickText(json, const ['title', 'subject', 'name']) ?? 'Notification',
      message: _pickText(json, const ['message', 'body', 'content']) ?? '',
      type: _pickText(json, const ['type', 'category']),
      isRead:
          _pickBool(json, const ['isRead', 'is_read', 'read']) ??
          ((json['readAt'] ?? json['read_at']) != null),
      createdAt: _pickDate(json, const ['createdAt', 'created_at', 'date']),
      updatedAt: _pickDate(json, const ['updatedAt', 'updated_at']),
      actorDisplayName: actor,
      actorUserId: actorId,
      relatedTaskId: taskId,
    );
  }

  static String? _extractRelatedTaskId(Map<String, dynamic> json) {
    final direct = _nonEmptyString(
      json['taskId'] ??
          json['task_id'] ??
          json['relatedId'] ??
          json['related_id'] ??
          json['entityId'] ??
          json['entity_id'] ??
          json['referenceId'] ??
          json['linkId'] ??
          json['resourceId'],
    );
    if (direct != null) return direct;

    for (final key in ['task', 'relatedTask', 'related', 'entity']) {
      final v = json[key];
      if (v is Map) {
        final m = Map<String, dynamic>.from(v);
        final tid = _nonEmptyString(m['id'] ?? m['taskId'] ?? m['task_id']);
        if (tid != null) return tid;
      }
    }
    for (final metaKey in ['metadata', 'data', 'payload', 'extra']) {
      final v = json[metaKey];
      if (v is Map) {
        final inner = _extractRelatedTaskId(Map<String, dynamic>.from(v));
        if (inner != null) return inner;
      }
      if (v is String && v.trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(v);
          if (decoded is Map) {
            final inner = _extractRelatedTaskId(
              Map<String, dynamic>.from(decoded),
            );
            if (inner != null) return inner;
          }
        } catch (_) {}
      }
    }
    return null;
  }

  static String _substituteActorPlaceholders(String text, String? name) {
    if (name == null || name.trim().isEmpty) return text;
    final n = name.trim();
    var t = text;
    t = t.replaceAll(RegExp(r'\bsomeone\b', caseSensitive: false), n);
    t = t.replaceAll(RegExp(r'\bsomebody\b', caseSensitive: false), n);
    t = t.replaceAll(RegExp(r'\ba user\b', caseSensitive: false), n);
    t = t.replaceAll(RegExp(r'\banother user\b', caseSensitive: false), n);
    return t;
  }

  static String? _extractActorDisplayName(Map<String, dynamic> json) {
    const flatKeys = [
      'actorName',
      'actorUserName',
      'changedByName',
      'changedByUserName',
      'userName',
      'fromName',
      'performedByName',
      'authorName',
      'senderName',
      'createdByName',
      'updatedByName',
    ];
    for (final k in flatKeys) {
      final s = _nonEmptyString(json[k]);
      if (s != null) return s;
    }
    const nestedKeys = [
      'actorUser',
      'changedByUser',
      'actor',
      'user',
      'fromUser',
      'sender',
      'createdByUser',
      'updatedByUser',
      'performedBy',
    ];
    for (final k in nestedKeys) {
      final v = json[k];
      if (v is Map) {
        final m = Map<String, dynamic>.from(v);
        final name =
            _nonEmptyString(m['name']) ?? _nonEmptyString(m['fullName']);
        if (name != null) return name;
      }
    }
    for (final metaKey in ['metadata', 'data', 'payload', 'extra']) {
      final v = json[metaKey];
      if (v is Map) {
        final inner = _extractActorDisplayName(Map<String, dynamic>.from(v));
        if (inner != null) return inner;
      }
      if (v is String) {
        final t = v.trim();
        if (t.startsWith('{')) {
          try {
            final decoded = jsonDecode(t);
            if (decoded is Map) {
              final inner = _extractActorDisplayName(
                Map<String, dynamic>.from(decoded),
              );
              if (inner != null) return inner;
            }
          } catch (_) {}
        }
      }
    }
    // Last resort: nested task / related objects (may include actor fields).
    for (final key in ['task', 'relatedTask', 'related']) {
      final v = json[key];
      if (v is Map) {
        final inner = _extractActorDisplayName(Map<String, dynamic>.from(v));
        if (inner != null) return inner;
      }
    }
    return null;
  }

  /// Picks up task ids nested under uncommon keys the backend might use.
  static String? _deepFindRelatedTaskId(dynamic node, [Set<int>? visited]) {
    if (node is Map) {
      final id = identityHashCode(node);
      visited ??= {};
      if (visited.contains(id)) return null;
      visited.add(id);
      final m = Map<String, dynamic>.from(node);
      for (final e in m.entries) {
        final k = e.key.toLowerCase();
        if ((k == 'taskid' ||
                k == 'task_id' ||
                k.endsWith('taskid') ||
                k == 'relatedid') &&
            e.value != null) {
          final s = _nonEmptyString(e.value);
          if (s != null && s.length >= 8) return s;
        }
        final inner = _deepFindRelatedTaskId(e.value, visited);
        if (inner != null) return inner;
      }
    } else if (node is List) {
      for (final e in node) {
        final inner = _deepFindRelatedTaskId(e, visited);
        if (inner != null) return inner;
      }
    }
    return null;
  }

  static String? _nonEmptyString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String? _pickText(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static bool? _pickBool(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    return null;
  }

  static DateTime? _pickDate(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      final d = DateTime.tryParse(v.toString());
      if (d != null) return d;
    }
    return null;
  }
}
