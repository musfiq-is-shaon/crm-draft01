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
          ? Company.fromJson(json['company'])
          : null,
      prospect: json['prospect'] ?? '',
      category: json['category'],
      expectedClosingDate: json['expectedClosingDate'] != null
          ? DateTime.tryParse(json['expectedClosingDate'].toString())
          : null,
      expectedRevenue: json['expectedRevenue'] != null
          ? double.tryParse(json['expectedRevenue'].toString())
          : null,
      status: json['status'] ?? 'lead',
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
      'companyId': companyId,
      'prospect': prospect,
      'category': category,
      'expectedClosingDate': expectedClosingDate?.toIso8601String().split(
        'T',
      )[0],
      'expectedRevenue': expectedRevenue,
      'status': status,
      'createdByUserId': createdByUserId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
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
    if (expectedRevenue == null) return '\$0';
    return '\$${expectedRevenue!.toStringAsFixed(0)}';
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
