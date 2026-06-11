import 'package:hoplixi/vault_db/core/errors/db_error.dart';
import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/item_links_graph/item_links_graph_models.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

abstract interface class ItemLinksGraphRepository {
  AsyncDBResult<List<ItemGraphSqlRecord>> loadGraphRecords(
    ItemLinksGraphMode mode,
  );
}

final class DriftItemLinksGraphRepository implements ItemLinksGraphRepository {
  const DriftItemLinksGraphRepository(this.db);

  final VaultDB db;

  @override
  AsyncDBResult<List<ItemGraphSqlRecord>> loadGraphRecords(
    ItemLinksGraphMode mode,
  ) {
    return tryCatchAsync(
      () {
        return switch (mode) {
          AllItemLinksGraphMode() => db.itemLinksGraphDao.loadAllGraphRecords(),
          RelationTypesItemLinksGraphMode(:final relationTypes) =>
            db.itemLinksGraphDao.loadGraphRecordsByRelationTypes(relationTypes),
        };
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении графа связей элементов',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
