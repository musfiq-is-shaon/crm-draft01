import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart' show ApiClient, apiClientProvider;
import '../models/status_config_model.dart';

class StatusConfigRepository {
  final ApiClient _apiClient;

  StatusConfigRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<StatusConfig> getStatusConfig() async {
    final response = await _apiClient.get(AppConstants.statusConfig);
    final raw = response.data;
    final map = _asConfigMap(raw);
    return StatusConfig.fromJson(map);
  }

  static Map<String, dynamic> _asConfigMap(dynamic raw) {
    if (raw is! Map) return {};
    final m = Map<String, dynamic>.from(raw);
    final inner = m['data'];
    if (inner is Map) return Map<String, dynamic>.from(inner);
    return m;
  }
}

final statusConfigRepositoryProvider = Provider<StatusConfigRepository>((ref) {
  return StatusConfigRepository(apiClient: ref.watch(apiClientProvider));
});
