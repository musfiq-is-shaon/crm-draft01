import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/company_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/company_repository.dart'
    show CompanyRepository, companyRepositoryProvider;
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/user_repository.dart'
    show UserRepository, userRepositoryProvider;

class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;
  final String? listSearch;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.listSearch,
  });

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    String? listSearch,
    bool clearListSearch = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      listSearch: clearListSearch ? null : (listSearch ?? this.listSearch),
    );
  }

  /// Orders list API has no `search` param; filter in the UI layer.
  List<Order> get visibleOrders {
    final q = listSearch?.trim().toLowerCase();
    if (q == null || q.isEmpty) return orders;
    return orders.where((o) {
      final companyName = (o.company?.name ?? '').toLowerCase();
      final details = o.orderDetails?.toLowerCase() ?? '';
      final status = o.status?.toLowerCase() ?? '';
      return companyName.contains(q) ||
          details.contains(q) ||
          status.contains(q);
    }).toList();
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderRepository _orderRepository;
  final CompanyRepository _companyRepository;
  final UserRepository _userRepository;

  OrdersNotifier(
    this._orderRepository,
    this._companyRepository,
    this._userRepository,
  ) : super(const OrdersState());

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await _orderRepository.getOrders();

      final companyIds = <String>{};
      final userIds = <String>{};
      for (final o in orders) {
        if (o.companyId != null) companyIds.add(o.companyId!);
        if (o.assignTo != null) userIds.add(o.assignTo!);
        if (o.forwardedTo != null) userIds.add(o.forwardedTo!);
      }

      final companiesFuture = companyIds.isNotEmpty
          ? _companyRepository.getCompaniesByIds(companyIds.toList())
          : Future.value(<String, Company>{});
      final usersFuture = userIds.isNotEmpty
          ? _userRepository.getUsersByIds(userIds.toList())
          : Future.value(<String, User>{});

      final results = await Future.wait([companiesFuture, usersFuture]);
      final companiesMap = results[0] as Map<String, Company>;
      final usersMap = results[1] as Map<String, User>;

      final enriched = orders.map((o) {
        Company? company;
        if (o.companyId != null && companiesMap.containsKey(o.companyId)) {
          company = companiesMap[o.companyId];
        }
        User? assignUser = o.assignToUser;
        if (assignUser == null &&
            o.assignTo != null &&
            usersMap.containsKey(o.assignTo)) {
          assignUser = usersMap[o.assignTo];
        }
        User? fwdUser = o.forwardedToUser;
        if (fwdUser == null &&
            o.forwardedTo != null &&
            usersMap.containsKey(o.forwardedTo)) {
          fwdUser = usersMap[o.forwardedTo];
        }
        return o.copyWith(
          company: company,
          assignToUser: assignUser,
          forwardedToUser: fwdUser,
        );
      }).toList();

      state = state.copyWith(orders: List<Order>.from(enriched), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setListSearch(String? search) {
    final trimmed = search?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      state = state.copyWith(clearListSearch: true);
    } else {
      state = state.copyWith(listSearch: trimmed, clearListSearch: false);
    }
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(
    ref.watch(orderRepositoryProvider),
    ref.watch(companyRepositoryProvider),
    ref.watch(userRepositoryProvider),
  );
});
