import 'company_model.dart';
import 'user_model.dart';

class Renewal {
  final String id;
  final String? companyId;
  final Company? company;
  final String? productDetails;
  final String? renewalType;
  final String? source;
  final DateTime? renewalDate;
  final String? kamUserId;
  final User? kamUser;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Renewal({
    required this.id,
    this.companyId,
    this.company,
    this.productDetails,
    this.renewalType,
    this.source,
    this.renewalDate,
    this.kamUserId,
    this.kamUser,
    this.createdAt,
    this.updatedAt,
  });

  factory Renewal.fromJson(Map<String, dynamic> json) {
    return Renewal(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString(),
      company: json['company'] != null
          ? Company.fromJson(Map<String, dynamic>.from(json['company'] as Map))
          : null,
      productDetails: json['productDetails']?.toString(),
      renewalType: json['renewalType']?.toString(),
      source: json['source']?.toString(),
      renewalDate: json['renewalDate'] != null
          ? DateTime.tryParse(json['renewalDate'].toString())
          : null,
      kamUserId: json['kamUserId']?.toString(),
      kamUser: json['kamUser'] != null
          ? User.fromJson(Map<String, dynamic>.from(json['kamUser'] as Map))
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Renewal copyWith({
    String? id,
    String? companyId,
    Company? company,
    String? productDetails,
    String? renewalType,
    String? source,
    DateTime? renewalDate,
    String? kamUserId,
    User? kamUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearCompany = false,
    bool clearKamUser = false,
  }) {
    return Renewal(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      company: clearCompany ? null : (company ?? this.company),
      productDetails: productDetails ?? this.productDetails,
      renewalType: renewalType ?? this.renewalType,
      source: source ?? this.source,
      renewalDate: renewalDate ?? this.renewalDate,
      kamUserId: kamUserId ?? this.kamUserId,
      kamUser: clearKamUser ? null : (kamUser ?? this.kamUser),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
