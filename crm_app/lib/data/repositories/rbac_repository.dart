import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/rbac_model.dart';

class RbacRepository {
  RbacRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  static Map<String, dynamic> _asStringKeyMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw FormatException('RBAC payload must be a JSON object');
  }

  Future<RbacMe> fetchMe() async {
    final response = await _api.get(AppConstants.rbacMe);
    var map = _asStringKeyMap(response.data);
    // Common API shape: { "data": { "navPageKeys": ... } }
    final inner = map['data'];
    if (inner is Map) {
      map = Map<String, dynamic>.from(inner);
    }
    return RbacMe.fromJson(map);
  }
}

final rbacRepositoryProvider = Provider<RbacRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return RbacRepository(apiClient: api);
});
