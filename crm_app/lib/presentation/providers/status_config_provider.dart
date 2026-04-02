import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/status_config_model.dart';
import '../../data/repositories/status_config_repository.dart';

final statusConfigProvider = FutureProvider<StatusConfig>((ref) async {
  final repo = ref.watch(statusConfigRepositoryProvider);
  return repo.getStatusConfig();
});
