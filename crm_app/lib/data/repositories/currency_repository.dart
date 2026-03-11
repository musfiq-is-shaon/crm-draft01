import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/currency_model.dart';

class CurrencyRepository {
  final ApiClient _apiClient;

  CurrencyRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Currency>> getCurrencies() async {
    final response = await _apiClient.get(AppConstants.currencies);
    final List<dynamic> data = response.data;
    return data.map((json) => Currency.fromJson(json)).toList();
  }
}

final currencyRepositoryProvider = Provider<CurrencyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CurrencyRepository(apiClient: apiClient);
});
