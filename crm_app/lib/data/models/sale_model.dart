import '../../core/constants/app_constants.dart';
import 'company_model.dart';
import 'user_model.dart';

class Sale {
  final String id;
  final String? companyId;
  final Company? company;
  final String prospect;
  final String? category;
  final DateTime? expectedClosingDate;
  final double? expectedRevenue;
  final String status;
  final String? nextAction;
  final DateTime? nextActionDate;
  final String? createdByUserId;
  final User? createdByUser;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Sale({
    required this.id,
    this.companyId,
    this.company,
    required this.prospect,
    this.category,
    this.expectedClosingDate,
    this.expectedRevenue,
    required this.status,
    this.nextAction,
    this.nextActionDate,
    this.createdByUserId,
    this.createdByUser,
    this.createdAt,
    this.updatedAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString(),
      company: json['company'] != null
          ? Company.fromJson(Map<String, dynamic>.from(json['company'] as Map))
          : null,
      prospect: json['prospect'] ?? '',
      category: json['category']?.toString(),
      expectedClosingDate: json['expectedClosingDate'] != null
          ? DateTime.tryParse(json['expectedClosingDate'].toString())
          : null,
      expectedRevenue: json['expectedRevenue'] != null
          ? double.tryParse(json['expectedRevenue'].toString())
          : null,
      status: json['status']?.toString() ?? 'lead',
      nextAction: json['nextAction']?.toString(),
      nextActionDate: json['nextActionDate'] != null
          ? DateTime.tryParse(json['nextActionDate'].toString())
          : null,
      createdByUserId: json['createdByUserId']?.toString(),
      createdByUser: json['createdByUser'] != null
          ? User.fromJson(Map<String, dynamic>.from(json['createdByUser'] as Map))
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
      'companyId': companyId,
      'prospect': prospect,
      'category': category,
      'expectedClosingDate': expectedClosingDate?.toIso8601String().split('T')[0],
      'expectedRevenue': expectedRevenue,
      'status': status,
      'nextAction': nextAction,
      'nextActionDate': nextActionDate?.toIso8601String().split('T')[0],
      'createdByUserId': createdByUserId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Sale copyWith({
    String? id,
    String? companyId,
    Company? company,
    String? prospect,
    String? category,
    DateTime? expectedClosingDate,
    double? expectedRevenue,
    String? status,
    String? nextAction,
    DateTime? nextActionDate,
    String? createdByUserId,
    User? createdByUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearCompany = false,
    bool clearCreatedByUser = false,
    bool clearNextAction = false,
    bool clearNextActionDate = false,
  }) {
    return Sale(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      company: clearCompany ? null : (company ?? this.company),
      prospect: prospect ?? this.prospect,
      category: category ?? this.category,
      expectedClosingDate: expectedClosingDate ?? this.expectedClosingDate,
      expectedRevenue: expectedRevenue ?? this.expectedRevenue,
      status: status ?? this.status,
      nextAction: clearNextAction ? null : (nextAction ?? this.nextAction),
      nextActionDate:
          clearNextActionDate ? null : (nextActionDate ?? this.nextActionDate),
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByUser:
          clearCreatedByUser ? null : (createdByUser ?? this.createdByUser),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isHot => category == 'hot';
  bool get isWarm => category == 'warm';
  bool get isCold => category == 'cold';

  bool get isLead => status == 'lead';
  bool get isProspect => status == 'prospect';
  bool get isNegotiation => status == 'negotiation';
  bool get isClosed => status == 'closed';
  bool get isClosedWon => status == 'closed_won';
  bool get isClosedLost => status == 'closed_lost';
  bool get isDisqualified => status == 'disqualified';

  String get formattedRevenue {
    if (expectedRevenue == null) {
      return '${AppConstants.currencySymbol}0';
    }
    return '${AppConstants.currencySymbol}'
        '${expectedRevenue!.toStringAsFixed(0)}';
  }
}

class SaleLog {
  final String id;
  final String saleId;
  final String? status;
  final String? note;
  final String? changedByUserId;
  final User? changedByUser;
  final DateTime? createdAt;

  SaleLog({
    required this.id,
    required this.saleId,
    this.status,
    this.note,
    this.changedByUserId,
    this.changedByUser,
    this.createdAt,
  });

  factory SaleLog.fromJson(Map<String, dynamic> json) {
    return SaleLog(
      id: json['id']?.toString() ?? '',
      saleId: json['saleId']?.toString() ?? '',
      status: json['status']?.toString(),
      note: json['note']?.toString(),
      changedByUserId: json['changedByUserId']?.toString(),
      changedByUser: json['changedByUser'] != null
          ? User.fromJson(
              Map<String, dynamic>.from(json['changedByUser'] as Map),
            )
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class SaleActivity {
  final String id;
  final String saleId;
  final String title;
  final String? note;
  final DateTime? date;
  final String? createdByUserId;
  final User? createdByUser;
  final DateTime? createdAt;

  SaleActivity({
    required this.id,
    required this.saleId,
    required this.title,
    this.note,
    this.date,
    this.createdByUserId,
    this.createdByUser,
    this.createdAt,
  });

  factory SaleActivity.fromJson(Map<String, dynamic> json) {
    return SaleActivity(
      id: json['id']?.toString() ?? '',
      saleId: json['saleId']?.toString() ?? '',
      title: json['title'] ?? '',
      note: json['note']?.toString(),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
      createdByUserId: json['createdByUserId']?.toString(),
      createdByUser: json['createdByUser'] != null
          ? User.fromJson(
              Map<String, dynamic>.from(json['createdByUser'] as Map),
            )
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'title': title,
      'note': note,
      'date': date?.toIso8601String().split('T')[0],
      'createdByUserId': createdByUserId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
