/// Mirrors `GET /api/status-config` (and optional `{ "data": { ... } }` wrapper).
class StatusConfig {
  final List<String> taskStatuses;
  final List<String> salesCategories;
  final List<String> salesStatuses;

  StatusConfig({
    required this.taskStatuses,
    required this.salesCategories,
    required this.salesStatuses,
  });

  /// Parses a list of plain strings or `{ "value", "isActive" }` objects (skips inactive).
  static List<String> parseValueList(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List) return [];
    final out = <String>[];
    for (final e in raw) {
      if (e is String) {
        if (e.isNotEmpty) out.add(e);
        continue;
      }
      if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        if (m['isActive'] == false) continue;
        final v = m['value']?.toString();
        if (v != null && v.isNotEmpty) out.add(v);
      }
    }
    return out;
  }

  factory StatusConfig.fromJson(Map<String, dynamic> json) {
    final tasks = parseValueList(json['taskStatuses']);
    final cats = parseValueList(json['salesCategories']);
    final sales = parseValueList(json['salesStatuses']);

    return StatusConfig(
      taskStatuses: tasks.isNotEmpty
          ? List<String>.from(tasks)
          : List<String>.from(
              ['pending', 'in_progress', 'completed', 'cancelled'],
            ),
      salesCategories: cats.isNotEmpty
          ? List<String>.from(cats)
          : List<String>.from(['hot', 'warm', 'cold']),
      salesStatuses: sales.isNotEmpty
          ? List<String>.from(sales)
          : List<String>.from(defaultDealPipelineStatuses),
    );
  }

  /// Default funnel when the API returns nothing (matches current CRM app + Postman samples).
  static const List<String> defaultDealPipelineStatuses = [
    'lead',
    'prospect',
    'proposal',
    'negotiation',
    'closed_won',
    'closed_lost',
    'disqualified',
  ];

  static StatusConfig get defaultConfig => StatusConfig(
        taskStatuses:
            List<String>.from(['pending', 'in_progress', 'completed', 'cancelled']),
        salesCategories: List<String>.from(['hot', 'warm', 'cold']),
        salesStatuses: List<String>.from(defaultDealPipelineStatuses),
      );
}
