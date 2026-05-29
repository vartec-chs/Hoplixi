import 'package:result_dart/result_dart.dart';

import '../../../errors/db_result.dart';
import '../../../scheme/tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';

abstract interface class VaultHistoryRestoreHandler {
  VaultItemType get type;

  Future<DBResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  });
}
