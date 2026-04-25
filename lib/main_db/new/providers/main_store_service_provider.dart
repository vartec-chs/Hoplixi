import 'package:riverpod/riverpod.dart';

import '../main_store_service.dart';
import 'db_history_provider.dart';

final mainStoreServiceProvider = FutureProvider<MainStoreService>((ref) async {
  final dbHistoryService = await ref.watch(dbHistoryProvider.future);

  return MainStoreService(dbHistoryService: dbHistoryService);
});
