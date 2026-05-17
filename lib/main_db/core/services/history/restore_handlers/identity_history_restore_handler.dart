import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/identity_history_payload.dart';
import 'vault_history_restore_handler.dart';

class IdentityHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  IdentityHistoryRestoreHandler({required this.identityItemsDao});

  final IdentityItemsDao identityItemsDao;

  @override
  VaultItemType get type => VaultItemType.identity;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    if (payload is! IdentityHistoryPayload) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.invalid_payload',
          message: 'Invalid payload for Identity restore',
          entity: 'identity',
        ),
      );
    }

    await identityItemsDao.upsertIdentityItem(
      IdentityItemsCompanion(
        itemId: Value(base.itemId),
        firstName: Value(payload.firstName),
        middleName: Value(payload.middleName),
        lastName: Value(payload.lastName),
        displayName: Value(payload.displayName),
        username: Value(payload.username),
        email: Value(payload.email),
        phone: Value(payload.phone),
        address: Value(payload.address),
        birthday: Value(payload.birthday),
        company: Value(payload.company),
        jobTitle: Value(payload.jobTitle),
        website: Value(payload.website),
        taxId: Value(payload.taxId),
        nationalId: Value(payload.nationalId),
        passportNumber: Value(payload.passportNumber),
        driverLicenseNumber: Value(payload.driverLicenseNumber),
      ),
    );

    return const Success(unit);
  }
}
