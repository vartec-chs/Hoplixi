import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../scheme/tables/vault_items/vault_item_custom_fields.dart';

class CustomFieldsSnapshotService {
  CustomFieldsSnapshotService({
    required this.customFieldsDao,
    required this.customFieldsHistoryDao,
  });

  final VaultItemCustomFieldsDao customFieldsDao;
  final VaultItemCustomFieldsHistoryDao customFieldsHistoryDao;

  AsyncDbResult<Unit> snapshotCustomFieldsForItem({
    required String snapshotHistoryId,
    required String itemId,
    bool includeSecrets = true,
  }) {
    return tryCatchAsync(
      () async {
        final fields = await customFieldsDao.getCustomFieldsByItemId(itemId);
        if (fields.isEmpty) return unit;

        final companions = fields.map((f) {
          final isSecret =
              f.isSecret || f.fieldType == CustomFieldType.concealed;
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
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании снимка настраиваемых полей',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
