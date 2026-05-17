import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/vault_items/vault_item_custom_fields.dart';

class CustomFieldsSnapshotService {
  CustomFieldsSnapshotService({
    required this.customFieldsDao,
    required this.customFieldsHistoryDao,
  });

  final VaultItemCustomFieldsDao customFieldsDao;
  final VaultItemCustomFieldsHistoryDao customFieldsHistoryDao;

  Future<DbResult<Unit>> snapshotCustomFieldsForItem({
    required String snapshotHistoryId,
    required String itemId,
    bool includeSecrets = true,
  }) async {
    try {
      final fields = await customFieldsDao.getCustomFieldsByItemId(itemId);
      if (fields.isEmpty) return Success(unit);

      final companions = fields.map((f) {
        final isSecret = f.isSecret || f.fieldType == CustomFieldType.concealed;
        final value = (!includeSecrets && isSecret) ? null : f.value;

        return VaultItemCustomFieldsHistoryCompanion(
          snapshotHistoryId: Value(snapshotHistoryId),
          originalFieldId: Value(f.id),
          label: Value(f.label),
          value: Value(value),
          fieldType: Value(f.fieldType),
          isSecret: Value(f.isSecret),
          sortOrder: Value(f.sortOrder),
          createdAt: Value(f.createdAt),
          modifiedAt: Value(f.modifiedAt),
          historyCreatedAt: Value(DateTime.now()),
        );
      }).toList();

      await customFieldsHistoryDao.insertCustomFieldsHistoryBatch(companions);
      return Success(unit);
    } catch (e, s) {
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s),
      );
    }
  }
}
