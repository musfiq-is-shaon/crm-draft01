import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/renewal_model.dart';

class RenewalRepository {
  final ApiClient _apiClient;

  RenewalRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  static dynamic _unwrap(dynamic raw) {
    if (raw is Map && raw['data'] != null) return raw['data'];
    return raw;
  }

  static Map<String, dynamic> _asRenewalMap(dynamic raw) {
    final u = _unwrap(raw);
    if (u is! Map) {
      throw FormatException('Expected renewal object, got $u');
    }
    return Map<String, dynamic>.from(u);
  }

  static List<dynamic> _asList(dynamic raw) {
    final u = _unwrap(raw);
    if (u is List) return u;
    return [];
  }

  Future<List<Renewal>> getRenewals({
    String? companyId,
    String? kamUserId,
    String? source,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (companyId != null && companyId.isNotEmpty) {
      queryParams['companyId'] = companyId;
    }
    if (kamUserId != null && kamUserId.isNotEmpty) {
      queryParams['kamUserId'] = kamUserId;
    }
    if (source != null && source.isNotEmpty) queryParams['source'] = source;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _apiClient.get(
      AppConstants.renewals,
      queryParameters: queryParams,
    );
    final data = _asList(response.data);
    return data
        .map(
          (json) => Renewal.fromJson(Map<String, dynamic>.from(json as Map)),
        )
        .toList();
  }

  Future<Renewal> getRenewalById(String id) async {
    final response = await _apiClient.get('${AppConstants.renewals}/$id');
    return Renewal.fromJson(_asRenewalMap(response.data));
  }

  Future<Renewal> createRenewal({
    required String companyId,
    required String productDetails,
    required String renewalType,
    String? source,
    required DateTime renewalDate,
  }) async {
    final body = <String, dynamic>{
      'companyId': companyId,
      'productDetails': productDetails,
      'renewalType': renewalType,
      'source': source,
      'renewalDate': renewalDate.toIso8601String().split('T')[0],
    };
    body.removeWhere((k, v) => v == null);

    final response = await _apiClient.post(
      AppConstants.renewals,
      data: body,
    );
    return Renewal.fromJson(_asRenewalMap(response.data));
  }

  Future<Renewal> updateRenewal({
    required String id,
    String? companyId,
    String? productDetails,
    String? renewalType,
    String? source,
    DateTime? renewalDate,
  }) async {
    final body = <String, dynamic>{
      'companyId': companyId,
      'productDetails': productDetails,
      'renewalType': renewalType,
      'source': source,
      'renewalDate': renewalDate?.toIso8601String().split('T')[0],
    };
    body.removeWhere((k, v) => v == null);

    final response = await _apiClient.put(
      '${AppConstants.renewals}/$id',
      data: body,
    );
    return Renewal.fromJson(_asRenewalMap(response.data));
  }

  Future<void> deleteRenewal(String id) async {
    await _apiClient.delete('${AppConstants.renewals}/$id');
  }

  Future<List<Renewal>> getRenewalsBin() async {
    final response = await _apiClient.get(AppConstants.renewalsBin);
    final data = _asList(response.data);
    return data
        .map(
          (json) => Renewal.fromJson(Map<String, dynamic>.from(json as Map)),
        )
        .toList();
  }

  Future<void> restoreRenewals(List<String> ids) async {
    await _apiClient.post(
      AppConstants.renewalsRestore,
      data: {'ids': ids},
    );
  }
}

final renewalRepositoryProvider = Provider<RenewalRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RenewalRepository(apiClient: apiClient);
});
