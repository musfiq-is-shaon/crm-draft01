import 'user_model.dart';

class Activity {
  final String id;
  final String? saleId;
  final String title;
  final String? note;
  final DateTime? date;
  final String? createdByUserId;
  final User? createdByUser;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Activity({
    required this.id,
    this.saleId,
    required this.title,
    this.note,
    this.date,
    this.createdByUserId,
    this.createdByUser,
    this.createdAt,
    this.updatedAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id']?.toString() ?? '',
      saleId: json['saleId']?.toString(),
      title: json['title'] ?? '',
      note: json['note'],
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
      createdByUserId: json['createdByUserId']?.toString(),
      createdByUser: json['createdByUser'] != null
          ? User.fromJson(json['createdByUser'])
          : null,
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
      'saleId': saleId,
      'title': title,
      'note': note,
      'date': date?.toIso8601String(),
      'createdByUserId': createdByUserId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class SaleLog {
  final String id;
  final String? saleId;
  final String? status;
  final String? note;
  final String? changedByUserId;
  final User? changedByUser;
  final DateTime? createdAt;

  SaleLog({
    required this.id,
    this.saleId,
    this.status,
    this.note,
    this.changedByUserId,
    this.changedByUser,
    this.createdAt,
  });

  factory SaleLog.fromJson(Map<String, dynamic> json) {
    return SaleLog(
      id: json['id']?.toString() ?? '',
      saleId: json['saleId']?.toString(),
      status: json['status'],
      note: json['note'],
      changedByUserId: json['changedByUserId']?.toString(),
      changedByUser: json['changedByUser'] != null
          ? User.fromJson(json['changedByUser'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
