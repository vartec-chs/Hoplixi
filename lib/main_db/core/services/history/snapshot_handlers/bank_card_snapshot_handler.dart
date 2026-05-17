import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class BankCardSnapshotHandler implements VaultSnapshotTypeHandler {
  BankCardSnapshotHandler({required this.bankCardHistoryDao});

  final BankCardHistoryDao bankCardHistoryDao;

  @override
  VaultItemType get type => VaultItemType.bankCard;

  @override
  Future<DbResult<Unit>> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) async {
    if (view is! BankCardViewDto) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.snapshot.invalid_view_type',
          message: 'Invalid view type for BankCard snapshot',
          entity: 'bankCard',
        ),
      );
    }

    final bankCard = view.bankCard;

    await bankCardHistoryDao.insertBankCardHistory(
      BankCardHistoryCompanion.insert(
        historyId: historyId,
        cardholderName: Value(bankCard.cardholderName),
        cardNumber: Value(includeSecrets ? bankCard.cardNumber : null),
        cardType: Value(bankCard.cardType),
        cardTypeOther: Value(bankCard.cardTypeOther),
        cardNetwork: Value(bankCard.cardNetwork),
        cardNetworkOther: Value(bankCard.cardNetworkOther),
        expiryMonth: Value(bankCard.expiryMonth),
        expiryYear: Value(bankCard.expiryYear),
        cvv: Value(includeSecrets ? bankCard.cvv : null),
        bankName: Value(bankCard.bankName),
        accountNumber: Value(includeSecrets ? bankCard.accountNumber : null),
        routingNumber: Value(includeSecrets ? bankCard.routingNumber : null),
      ),
    );

    return const Success(unit);
  }
}
