import 'company_model.dart';
import 'user_model.dart';

class Task {
  final String id;
  final String title;
  final String? note;
  final String? companyId;
  final Company? company;
  final DateTime? dueDatetime;
  final String? assignByUserId;
  final User? assignByUser;
  final String? assignToUserId;
  final User? assignToUser;
  final String status;
  final String? actorUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    this.note,
    this.companyId,
    this.company,
    this.dueDatetime,
    this.assignByUserId,
    this.assignByUser,
    this.assignToUserId,
    this.assignToUser,
    required this.status,
    this.actorUserId,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      note: json['note'],
      companyId: json['companyId']?.toString(),
      company: json['company'] != null
          ? Company.fromJson(json['company'])
          : null,
      dueDatetime: json['dueDatetime'] != null
          ? DateTime.tryParse(json['dueDatetime'].toString())
          : null,
      assignByUserId: json['assignByUserId']?.toString(),
      assignByUser: json['assignByUser'] != null
          ? User.fromJson(json['assignByUser'])
          : null,
      assignToUserId: json['assignToUserId']?.toString(),
      assignToUser: json['assignToUser'] != null
          ? User.fromJson(json['assignToUser'])
          : null,
      status: json['status'] ?? 'pending',
      actorUserId: json['actorUserId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'companyId': companyId,
      'dueDatetime': dueDatetime?.toIso8601String(),
      'assignByUserId': assignByUserId,
      'assignToUserId': assignToUserId,
      'status': status,
      'actorUserId': actorUserId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isOverdue {
    if (dueDatetime == null) return false;
    return DateTime.now().isAfter(dueDatetime!) && !isCompleted;
  }
}

class TaskLog {
  final String id;
  final String taskId;
  final String? note;
  final String? status;
  final String? actorUserId;
  final User? actorUser;
  final DateTime? createdAt;

  TaskLog({
    required this.id,
    required this.taskId,
    this.note,
    this.status,
    this.actorUserId,
    this.actorUser,
    this.createdAt,
  });

  factory TaskLog.fromJson(Map<String, dynamic> json) {
    return TaskLog(
      id: json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      note: json['note'],
      status: json['status'],
      actorUserId: json['actorUserId']?.toString(),
      actorUser: json['actorUser'] != null
          ? User.fromJson(json['actorUser'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
