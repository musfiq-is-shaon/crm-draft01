import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/company_model.dart';
import '../../data/models/renewal_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/company_repository.dart'
    show CompanyRepository, companyRepositoryProvider;
import '../../data/repositories/renewal_repository.dart';
import '../../data/repositories/user_repository.dart'
    show UserRepository, userRepositoryProvider;

class RenewalsState {
  final List<Renewal> renewals;
  final bool isLoading;
  final String? error;
  final String? listSearch;

  const RenewalsState({
    this.renewals = const [],
    this.isLoading = false,
    this.error,
    this.listSearch,
  });

  RenewalsState copyWith({
    List<Renewal>? renewals,
    bool? isLoading,
    String? error,
    String? listSearch,
    bool clearListSearch = false,
  }) {
    return RenewalsState(
      renewals: renewals ?? this.renewals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      listSearch: clearListSearch ? null : (listSearch ?? this.listSearch),
    );
  }
}

class RenewalsNotifier extends StateNotifier<RenewalsState> {
  final RenewalRepository _renewalRepository;
  final CompanyRepository _companyRepository;
  final UserRepository _userRepository;

  RenewalsNotifier(
    this._renewalRepository,
    this._companyRepository,
    this._userRepository,
  ) : super(const RenewalsState());

  Future<void> loadRenewals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final search = state.listSearch?.trim();
      final renewals = await _renewalRepository.getRenewals(
        search: search != null && search.isNotEmpty ? search : null,
      );

      final companyIds = <String>{};
      final userIds = <String>{};
      for (final r in renewals) {
        if (r.companyId != null) companyIds.add(r.companyId!);
        if (r.kamUserId != null) userIds.add(r.kamUserId!);
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

      final enriched = renewals.map((r) {
        Company? company;
        if (r.companyId != null && companiesMap.containsKey(r.companyId)) {
          company = companiesMap[r.companyId];
        }
        User? kam = r.kamUser;
        if (kam == null &&
            r.kamUserId != null &&
            usersMap.containsKey(r.kamUserId)) {
          kam = usersMap[r.kamUserId];
        }
        return r.copyWith(company: company, kamUser: kam);
      }).toList();

      state = state.copyWith(renewals: List<Renewal>.from(enriched), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setListSearchAndReload(String? search) async {
    final trimmed = search?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      state = state.copyWith(clearListSearch: true);
    } else {
      state = state.copyWith(listSearch: trimmed, clearListSearch: false);
    }
    await loadRenewals();
  }
}

final renewalsProvider =
    StateNotifierProvider<RenewalsNotifier, RenewalsState>((ref) {
  return RenewalsNotifier(
    ref.watch(renewalRepositoryProvider),
    ref.watch(companyRepositoryProvider),
    ref.watch(userRepositoryProvider),
  );
});
