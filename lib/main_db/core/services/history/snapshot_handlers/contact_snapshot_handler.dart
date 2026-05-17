import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class ContactSnapshotHandler implements VaultSnapshotTypeHandler {
  ContactSnapshotHandler({required this.contactHistoryDao});

  final ContactHistoryDao contactHistoryDao;

  @override
  VaultItemType get type => VaultItemType.contact;

  @override
  Future<DbResult<Unit>> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) async {
    if (view is! ContactViewDto) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.snapshot.invalid_view_type',
          message: 'Invalid view type for Contact snapshot',
          entity: 'contact',
        ),
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

    return const Success(unit);
  }
}
