import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class IdentitySnapshotHandler implements VaultSnapshotTypeHandler {
  IdentitySnapshotHandler({required this.identityHistoryDao});

  final IdentityHistoryDao identityHistoryDao;

  @override
  VaultItemType get type => VaultItemType.identity;

  @override
  Future<DbResult<Unit>> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) async {
    if (view is! IdentityViewDto) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.snapshot.invalid_view_type',
          message: 'Invalid view type for Identity snapshot',
          entity: 'identity',
        ),
      );
    }

    final identity = view.identity;

    await identityHistoryDao.insertIdentityHistory(
      IdentityHistoryCompanion.insert(
        historyId: historyId,
        firstName: Value(identity.firstName),
        middleName: Value(identity.middleName),
        lastName: Value(identity.lastName),
        displayName: Value(identity.displayName),
        username: Value(identity.username),
        email: Value(identity.email),
        phone: Value(identity.phone),
        address: Value(identity.address),
        birthday: Value(identity.birthday),
        company: Value(identity.company),
        jobTitle: Value(identity.jobTitle),
        website: Value(identity.website),
        taxId: Value(includeSecrets ? identity.taxId : null),
        nationalId: Value(includeSecrets ? identity.nationalId : null),
        passportNumber: Value(includeSecrets ? identity.passportNumber : null),
        driverLicenseNumber: Value(
          includeSecrets ? identity.driverLicenseNumber : null,
        ),
      ),
    );

    return const Success(unit);
  }
}
