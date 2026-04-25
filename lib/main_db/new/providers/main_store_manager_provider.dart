import 'package:riverpod/riverpod.dart';

import '../main_store_manager.dart';
import 'db_history_provider.dart';

final mainStoreManagerProvider = FutureProvider<MainStoreManager>((ref) async {
  final dbHistoryService = await ref.watch(dbHistoryProvider.future);

  return MainStoreManager(dbHistoryService: dbHistoryService);
});
