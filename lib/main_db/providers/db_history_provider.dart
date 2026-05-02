import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/db_history_services/db_history_services.dart';

final dbHistoryProvider = FutureProvider<DatabaseHistoryService>((ref) async {
  final databaseHistoryService = DatabaseHistoryService();
  await databaseHistoryService.initialize();
  return databaseHistoryService;
});
