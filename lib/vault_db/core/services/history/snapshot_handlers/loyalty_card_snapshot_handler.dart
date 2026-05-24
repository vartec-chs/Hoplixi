import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../scheme/tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class LoyaltyCardSnapshotHandler implements VaultSnapshotTypeHandler {
  LoyaltyCardSnapshotHandler({required this.loyaltyCardHistoryDao});

  final LoyaltyCardHistoryDao loyaltyCardHistoryDao;

  @override
  VaultItemType get type => VaultItemType.loyaltyCard;

  @override
  AsyncDbResult<Unit> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        if (view is! LoyaltyCardViewDto) {
          throw const DBCoreError.conflict(
            code: 'history.snapshot.invalid_view_type',
            message: 'Invalid view type for LoyaltyCard snapshot',
            entity: 'loyaltyCard',
          );
        }

        final card = view.loyaltyCard;

        await loyaltyCardHistoryDao.insertLoyaltyCardHistory(
          LoyaltyCardHistoryCompanion.insert(
            historyId: historyId,
            programName: card.programName,
            cardNumber: Value(includeSecrets ? card.cardNumber : null),
            barcodeValue: Value(includeSecrets ? card.barcodeValue : null),
            password: Value(includeSecrets ? card.password : null),
            barcodeType: Value(card.barcodeType),
            barcodeTypeOther: Value(card.barcodeTypeOther),
            issuer: Value(card.issuer),
            website: Value(card.website),
            phone: Value(card.phone),
            email: Value(card.email),
            validFrom: Value(card.validFrom),
            validTo: Value(card.validTo),
          ),
        );

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при записи снимка карты лояльности',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
