import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/loyalty_card_history_payload.dart';
import 'vault_history_restore_handler.dart';

class LoyaltyCardHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  LoyaltyCardHistoryRestoreHandler({required this.loyaltyCardItemsDao});

  final LoyaltyCardItemsDao loyaltyCardItemsDao;

  @override
  VaultItemType get type => VaultItemType.loyaltyCard;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    if (payload is! LoyaltyCardHistoryPayload) {
      return Failure(
        DBCoreError.conflict(
          code: 'history.restore.invalid_payload',
          message: 'Invalid payload for LoyaltyCard restore',
          entity: 'loyaltyCard',
        ),
      );
    }

    if (payload.programName == null) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.missing_field',
          message:
              'Нельзя восстановить карту: в снимке отсутствует обязательное поле "programName"',
          entity: 'loyaltyCard',
        ),
      );
    }

    await loyaltyCardItemsDao.upsertLoyaltyCardItem(
      LoyaltyCardItemsCompanion(
        itemId: Value(base.itemId),
        programName: Value(payload.programName),
        cardNumber: Value(payload.cardNumber),
        barcodeValue: Value(payload.barcodeValue),
        password: Value(payload.password),
        barcodeType: Value(payload.barcodeType),
        barcodeTypeOther: Value(payload.barcodeTypeOther),
        issuer: Value(payload.issuer),
        website: Value(payload.website),
        phone: Value(payload.phone),
        email: Value(payload.email),
        validFrom: Value(payload.validFrom),
        validTo: Value(payload.validTo),
      ),
    );

    return const Success(unit);
  }
}
