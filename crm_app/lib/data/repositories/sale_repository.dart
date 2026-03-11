import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/sale_model.dart';

class SaleRepository {
  final ApiClient _apiClient;

  SaleRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Sale>> getSales({
    String? status,
    String? companyId,
    String? category,
    String? createdByUserId,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (companyId != null && companyId.isNotEmpty) {
      queryParams['companyId'] = companyId;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (createdByUserId != null && createdByUserId.isNotEmpty) {
      queryParams['createdByUserId'] = createdByUserId;
    }
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _apiClient.get(
      AppConstants.sales,
      queryParameters: queryParams,
    );
    final List<dynamic> data = response.data;
    return data.map((json) => Sale.fromJson(json)).toList();
  }

  Future<Sale> getSaleById(String id) async {
    final response = await _apiClient.get('${AppConstants.sales}/$id');
    return Sale.fromJson(response.data);
  }

  Future<Sale> createSale({
    required String companyId,
    required String prospect,
    required DateTime expectedClosingDate,
    String? category,
    double? expectedRevenue,
    String? status,
    String? createdByUserId,
  }) async {
    final response = await _apiClient.post(
      AppConstants.sales,
      data: {
        'companyId': companyId,
        'prospect': prospect,
        'expectedClosingDate': expectedClosingDate.toIso8601String().split(
          'T',
        )[0],
        'category': category,
        'expectedRevenue': expectedRevenue,
        'status': status,
        'createdByUserId': createdByUserId,
      },
    );
    return Sale.fromJson(response.data);
  }

  Future<Sale> updateSale({
    required String id,
    String? companyId,
    String? prospect,
    String? category,
    DateTime? expectedClosingDate,
    double? expectedRevenue,
  }) async {
    final response = await _apiClient.put(
      '${AppConstants.sales}/$id',
      data: {
        'companyId': companyId,
        'prospect': prospect,
        'category': category,
        if (expectedClosingDate != null)
          'expectedClosingDate': expectedClosingDate.toIso8601String().split(
            'T',
          )[0],
        'expectedRevenue': expectedRevenue,
      },
    );
    return Sale.fromJson(response.data);
  }

  Future<Sale> changeSaleStatus({
    required String id,
    required String status,
    String? note,
    String? changedByUserId,
  }) async {
    final response = await _apiClient.patch(
      '${AppConstants.sales}/$id/status',
      data: {
        'status': status,
        'note': note,
        'changedByUserId': changedByUserId,
      },
    );
    return Sale.fromJson(response.data);
  }

  Future<List<SaleLog>> getSaleLogs(String saleId) async {
    final response = await _apiClient.get('${AppConstants.sales}/$saleId/logs');
    final List<dynamic> data = response.data;
    return data.map((json) => SaleLog.fromJson(json)).toList();
  }

  Future<List<SaleActivity>> getSaleActivities(String saleId) async {
    final response = await _apiClient.get(
      '${AppConstants.sales}/$saleId/activities',
    );
    final List<dynamic> data = response.data;
    return data.map((json) => SaleActivity.fromJson(json)).toList();
  }

  Future<SaleActivity> createSaleActivity({
    required String saleId,
    required String title,
    required DateTime date,
    String? note,
    String? createdByUserId,
  }) async {
    final response = await _apiClient.post(
      '${AppConstants.sales}/$saleId/activities',
      data: {
        'title': title,
        'date': date.toIso8601String().split('T')[0],
        'note': note,
        'createdByUserId': createdByUserId,
      },
    );
    return SaleActivity.fromJson(response.data);
  }

  Future<SaleActivity> updateSaleActivity({
    required String saleId,
    required String activityId,
    String? title,
    String? note,
    DateTime? date,
  }) async {
    final response = await _apiClient.put(
      '${AppConstants.sales}/$saleId/activities/$activityId',
      data: {
        'title': title,
        'note': note,
        if (date != null) 'date': date.toIso8601String().split('T')[0],
      },
    );
    return SaleActivity.fromJson(response.data);
  }

  Future<void> deleteSaleActivity({
    required String saleId,
    required String activityId,
  }) async {
    await _apiClient.delete(
      '${AppConstants.sales}/$saleId/activities/$activityId',
    );
  }

  Future<void> deleteSale(String id) async {
    await _apiClient.delete('${AppConstants.sales}/$id');
  }
}

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SaleRepository(apiClient: apiClient);
});
