import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/bank_card_history_payload.dart';
import 'vault_history_restore_handler.dart';

class BankCardHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  BankCardHistoryRestoreHandler({required this.bankCardItemsDao});

  final BankCardItemsDao bankCardItemsDao;

  @override
  VaultItemType get type => VaultItemType.bankCard;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    if (payload is! BankCardHistoryPayload) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.invalid_payload',
          message: 'Invalid payload for BankCard restore',
          entity: 'bankCard',
        ),
      );
    }

    if (payload.cardNumber == null) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.missing_field',
          message:
              'Нельзя восстановить карту: в снимке отсутствует обязательное поле "cardNumber"',
          entity: 'bankCard',
        ),
      );
    }

    await bankCardItemsDao.upsertBankCardItem(
      BankCardItemsCompanion(
        itemId: Value(base.itemId),
        cardholderName: Value(payload.cardholderName),
        cardNumber: Value(payload.cardNumber!),
        cardType: Value(payload.cardType),
        cardTypeOther: Value(payload.cardTypeOther),
        cardNetwork: Value(payload.cardNetwork),
        cardNetworkOther: Value(payload.cardNetworkOther),
        expiryMonth: Value(payload.expiryMonth),
        expiryYear: Value(payload.expiryYear),
        cvv: Value(payload.cvv),
        bankName: Value(payload.bankName),
        accountNumber: Value(payload.accountNumber),
        routingNumber: Value(payload.routingNumber),
      ),
    );

    return const Success(unit);
  }
}
