import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<User>> getUsers() async {
    final response = await _apiClient.get(AppConstants.users);
    final List<dynamic> data = response.data;
    return data.map((json) => User.fromJson(json)).toList();
  }

  Future<User> getUserById(String id) async {
    final response = await _apiClient.get('${AppConstants.users}/$id');
    return User.fromJson(response.data);
  }

  Future<User> updateMe({String? name, String? phone}) async {
    final response = await _apiClient.patch(
      AppConstants.usersMe,
      data: {'name': name, 'phone': phone},
    );
    return User.fromJson(response.data);
  }

  Future<User> createUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? role,
  }) async {
    final response = await _apiClient.post(
      AppConstants.users,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      },
    );
    return User.fromJson(response.data);
  }

  Future<User> updateUser({
    required String id,
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
  }) async {
    final response = await _apiClient.put(
      '${AppConstants.users}/$id',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'isActive': isActive,
      },
    );
    return User.fromJson(response.data);
  }

  Future<void> setUserPassword({
    required String id,
    required String newPassword,
  }) async {
    await _apiClient.put(
      '${AppConstants.users}/$id/password',
      data: {'newPassword': newPassword},
    );
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserRepository(apiClient: apiClient);
});
