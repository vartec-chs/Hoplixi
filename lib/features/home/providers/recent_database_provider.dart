import 'package:riverpod/riverpod.dart';
import 'package:hoplixi/db_core/models/db_history_model.dart';
import 'package:hoplixi/db_core/provider/db_history_provider.dart';

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
