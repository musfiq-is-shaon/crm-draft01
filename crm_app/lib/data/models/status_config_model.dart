class StatusConfig {
  final List<String> taskStatuses;
  final List<String> salesCategories;
  final List<String> salesStatuses;

  StatusConfig({
    required this.taskStatuses,
    required this.salesCategories,
    required this.salesStatuses,
  });

  factory StatusConfig.fromJson(Map<String, dynamic> json) {
    return StatusConfig(
      taskStatuses: json['taskStatuses'] != null
          ? List<String>.from(json['taskStatuses'])
          : ['pending', 'in_progress', 'completed', 'cancelled'],
      salesCategories: json['salesCategories'] != null
          ? List<String>.from(json['salesCategories'])
          : ['hot', 'warm', 'cold'],
      salesStatuses: json['salesStatuses'] != null
          ? List<String>.from(json['salesStatuses'])
          : ['lead', 'prospect', 'negotiation', 'closed', 'disqualified'],
    );
  }

  static StatusConfig get defaultConfig => StatusConfig(
    taskStatuses: ['pending', 'in_progress', 'completed', 'cancelled'],
    salesCategories: ['hot', 'warm', 'cold'],
    salesStatuses: [
      'lead',
      'prospect',
      'negotiation',
      'closed',
      'disqualified',
    ],
  );
}

class CompanyProfile {
  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? website;
  final String? address;
  final String? city;
  final String? country;
  final String? industry;
  final String? taxId;
  final String? description;
  final String? logo;

  CompanyProfile({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.website,
    this.address,
    this.city,
    this.country,
    this.industry,
    this.taxId,
    this.description,
    this.logo,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      id: json['id']?.toString(),
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      website: json['website'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      industry: json['industry'],
      taxId: json['taxId'],
      description: json['description'],
      logo: json['logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'website': website,
      'address': address,
      'city': city,
      'country': country,
      'industry': industry,
      'taxId': taxId,
      'description': description,
      'logo': logo,
    };
  }
}
