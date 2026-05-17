import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';

class CustomFieldsRestoreService {
  CustomFieldsRestoreService({
    required this.customFieldsDao,
    required this.customFieldsHistoryDao,
  });

  final VaultItemCustomFieldsDao customFieldsDao;
  final VaultItemCustomFieldsHistoryDao customFieldsHistoryDao;

  Future<DbResult<Unit>> restoreCustomFieldsForSnapshot({
    required String itemId,
    required String snapshotHistoryId,
  }) async {
    try {
      final historyFields = await customFieldsHistoryDao
          .getCustomFieldsHistoryBySnapshotHistoryId(snapshotHistoryId);

      final companions = historyFields.map((h) {
        return VaultItemCustomFieldsCompanion(
          id: Value(h.originalFieldId ?? const Uuid().v4()),
          itemId: Value(itemId),
          label: Value(h.label),
          value: Value(h.value),
          fieldType: Value(h.fieldType),
          isSecret: Value(h.isSecret),
          sortOrder: Value(h.sortOrder),
          createdAt: Value(h.createdAt),
          modifiedAt: Value(h.modifiedAt),
        );
      }).toList();

      await customFieldsDao.replaceCustomFieldsForItem(
        itemId: itemId,
        fields: companions,
      );

      return const Success(unit);
    } catch (e, s) {
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s),
      );
    }
  }
}
