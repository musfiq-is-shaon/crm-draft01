class Currency {
  final String id;
  final String code;
  final String name;
  final String? symbol;
  final int? sortOrder;

  Currency({
    required this.id,
    required this.code,
    required this.name,
    this.symbol,
    this.sortOrder,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'],
      sortOrder: json['sortOrder'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'symbol': symbol,
      'sortOrder': sortOrder,
    };
  }

  @override
  String toString() => '$code - $name';
}
