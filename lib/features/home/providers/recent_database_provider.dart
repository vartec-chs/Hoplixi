import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_db/providers/db_history_provider.dart';
import 'package:hoplixi/main_db/services/db_history_services/model/db_history_model.dart';

final recentDatabaseProvider = FutureProvider.autoDispose<DatabaseEntry?>((
  ref,
) async {
  final historyService = await ref.watch(dbHistoryProvider.future);
  final recent = await historyService.getRecent(limit: 1);
  if (recent.isNotEmpty) {
    return recent.first;
  }
  return null;
});
