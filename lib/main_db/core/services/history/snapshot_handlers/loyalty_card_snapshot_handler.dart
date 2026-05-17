import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class LoyaltyCardSnapshotHandler implements VaultSnapshotTypeHandler {
  LoyaltyCardSnapshotHandler({required this.loyaltyCardHistoryDao});

  final LoyaltyCardHistoryDao loyaltyCardHistoryDao;

  @override
  VaultItemType get type => VaultItemType.loyaltyCard;

  @override
  Future<DbResult<Unit>> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) async {
    if (view is! LoyaltyCardViewDto) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.snapshot.invalid_view_type',
          message: 'Invalid view type for LoyaltyCard snapshot',
          entity: 'loyaltyCard',
        ),
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

    return const Success(unit);
  }
}
