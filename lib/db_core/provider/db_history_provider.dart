import 'package:riverpod/riverpod.dart';
import '../services/db_history_services.dart';

final dbHistoryProvider = FutureProvider<DatabaseHistoryService>((ref) async {
  final databaseHistoryService = DatabaseHistoryService();
  await databaseHistoryService.initialize();
  return databaseHistoryService;
});
