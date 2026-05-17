import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:result_dart/result_dart.dart';

import '../../../errors/db_result.dart';
import '../../../tables/vault_items/vault_items.dart';

abstract interface class VaultSnapshotTypeHandler {
  VaultItemType get type;

  Future<DbResult<Unit>> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  });
}
