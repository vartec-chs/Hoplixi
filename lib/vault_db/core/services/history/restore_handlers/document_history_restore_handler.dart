import 'package:result_dart/result_dart.dart';

import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import 'vault_history_restore_handler.dart';

class DocumentHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  @override
  VaultItemType get type => VaultItemType.document;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    return const Failure(
      DBCoreError.validation(
        code: 'history.restore.document_not_supported_yet',
        message: 'Восстановление документов из истории пока не поддерживается',
        entity: 'document',
      ),
    );
  }
}
