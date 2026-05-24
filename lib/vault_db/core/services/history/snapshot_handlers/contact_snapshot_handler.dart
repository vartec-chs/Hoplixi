import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../scheme/tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class ContactSnapshotHandler implements VaultSnapshotTypeHandler {
  ContactSnapshotHandler({required this.contactHistoryDao});

  final ContactHistoryDao contactHistoryDao;

  @override
  VaultItemType get type => VaultItemType.contact;

  @override
  AsyncDbResult<Unit> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        if (view is! ContactViewDto) {
          throw const DBCoreError.conflict(
            code: 'history.snapshot.invalid_view_type',
            message: 'Invalid view type for Contact snapshot',
            entity: 'contact',
          );
        }

        final contact = view.contact;

        await contactHistoryDao.insertContactHistory(
          ContactHistoryCompanion.insert(
            historyId: historyId,
            firstName: contact.firstName,
            middleName: Value(contact.middleName),
            lastName: Value(contact.lastName),
            phone: Value(contact.phone),
            email: Value(contact.email),
            company: Value(contact.company),
            jobTitle: Value(contact.jobTitle),
            address: Value(contact.address),
            website: Value(contact.website),
            birthday: Value(contact.birthday),
            isEmergencyContact: Value(contact.isEmergencyContact),
          ),
        );

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при записи снимка контакта',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
