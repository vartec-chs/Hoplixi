import 'package:result_dart/result_dart.dart';

import '../../../errors/db_result.dart';
import '../../../scheme/tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/document_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class DocumentHistoryNormalizer implements VaultHistoryTypeNormalizer {
  @override
  VaultItemType get type => VaultItemType.document;

  @override
  AsyncDBResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) async {
    return const Success(Some(DocumentHistoryPayload()));
  }

  @override
  AsyncDBResult<Optional<HistoryPayload>> normalizeCurrent({
    required String itemId,
  }) async {
    return const Success(Some(DocumentHistoryPayload()));
  }
}
