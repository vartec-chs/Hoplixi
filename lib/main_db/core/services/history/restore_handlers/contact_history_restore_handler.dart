import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/contact_history_payload.dart';
import 'vault_history_restore_handler.dart';

class ContactHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  ContactHistoryRestoreHandler({required this.contactItemsDao});

  final ContactItemsDao contactItemsDao;

  @override
  VaultItemType get type => VaultItemType.contact;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    if (payload is! ContactHistoryPayload) {
      return Failure(
        DBCoreError.conflict(
          code: 'history.restore.invalid_payload',
          message: 'Invalid payload for Contact restore',
          entity: 'contact',
        ),
      );
    }

    await contactItemsDao.upsertContactItem(
      ContactItemsCompanion(
        itemId: Value(base.itemId),
        firstName: Value(payload.firstName),
        middleName: Value(payload.middleName),
        lastName: Value(payload.lastName),
        phone: Value(payload.phone),
        email: Value(payload.email),
        company: Value(payload.company),
        jobTitle: Value(payload.jobTitle),
        address: Value(payload.address),
        website: Value(payload.website),
        birthday: Value(payload.birthday),
        isEmergencyContact: Value(payload.isEmergencyContact),
      ),
    );

    return const Success(unit);
  }
}
