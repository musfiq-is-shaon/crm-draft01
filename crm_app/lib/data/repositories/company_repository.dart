import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/company_model.dart';

class CompanyRepository {
  final ApiClient _apiClient;

  CompanyRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Company>> getCompanies({
    String? search,
    String? country,
    String? kamUserId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (country != null && country.isNotEmpty) queryParams['country'] = country;
    if (kamUserId != null && kamUserId.isNotEmpty) {
      queryParams['kamUserId'] = kamUserId;
    }

    final response = await _apiClient.get(
      AppConstants.companies,
      queryParameters: queryParams,
    );
    final List<dynamic> data = response.data;
    return data.map((json) => Company.fromJson(json)).toList();
  }

  Future<Company> getCompanyById(String id) async {
    final response = await _apiClient.get('${AppConstants.companies}/$id');
    return Company.fromJson(response.data);
  }

  Future<Company> createCompany({
    required String name,
    String? location,
    String? country,
    required String kamUserId,
    required String currencyId,
  }) async {
    final response = await _apiClient.post(
      AppConstants.companies,
      data: {
        'name': name,
        'kamUserId': kamUserId,
        'currencyId': currencyId,
        'location': location,
        'country': country,
      },
    );
    return Company.fromJson(response.data);
  }

  Future<Company> updateCompany({
    required String id,
    String? name,
    String? location,
    String? country,
    String? kamUserId,
  }) async {
    final response = await _apiClient.put(
      '${AppConstants.companies}/$id',
      data: {
        'name': name,
        'location': location,
        'country': country,
        'kamUserId': kamUserId,
      },
    );
    return Company.fromJson(response.data);
  }

  Future<void> deleteCompany(String id) async {
    await _apiClient.delete('${AppConstants.companies}/$id');
  }
}

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CompanyRepository(apiClient: apiClient);
});
