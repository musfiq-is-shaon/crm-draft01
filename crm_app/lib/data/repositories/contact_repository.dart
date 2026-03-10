import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/contact_model.dart';

class ContactRepository {
  final ApiClient _apiClient;

  ContactRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Contact>> getContacts({String? companyId, String? search}) async {
    final queryParams = <String, dynamic>{};
    if (companyId != null && companyId.isNotEmpty) {
      queryParams['companyId'] = companyId;
    }
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _apiClient.get(
      AppConstants.contacts,
      queryParameters: queryParams,
    );
    final List<dynamic> data = response.data;
    return data.map((json) => Contact.fromJson(json)).toList();
  }

  Future<Contact> getContactById(String id) async {
    final response = await _apiClient.get('${AppConstants.contacts}/$id');
    return Contact.fromJson(response.data);
  }

  Future<Contact> createContact({
    required String name,
    required String companyId,
    String? designation,
    String? mobile,
    String? email,
  }) async {
    final response = await _apiClient.post(
      AppConstants.contacts,
      data: {
        'name': name,
        'companyId': companyId,
        'designation': ?designation,
        'mobile': ?mobile,
        'email': ?email,
      },
    );
    return Contact.fromJson(response.data);
  }

  Future<Contact> updateContact({
    required String id,
    String? name,
    String? companyId,
    String? designation,
    String? mobile,
    String? email,
  }) async {
    final response = await _apiClient.put(
      '${AppConstants.contacts}/$id',
      data: {
        'name': ?name,
        'companyId': ?companyId,
        'designation': ?designation,
        'mobile': ?mobile,
        'email': ?email,
      },
    );
    return Contact.fromJson(response.data);
  }

  Future<void> deleteContact(String id) async {
    await _apiClient.delete('${AppConstants.contacts}/$id');
  }
}

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ContactRepository(apiClient: apiClient);
});
