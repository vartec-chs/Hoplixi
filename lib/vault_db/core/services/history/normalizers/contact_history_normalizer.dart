import 'package:hoplixi/vault_db/core/repositories/base/contact_repository.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/contact_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class ContactHistoryNormalizer implements VaultHistoryTypeNormalizer {
  ContactHistoryNormalizer({
    required this.contactHistoryDao,
    required this.contactRepository,
  });

  final ContactHistoryDao contactHistoryDao;
  final ContactRepository contactRepository;

  @override
  VaultItemType get type => VaultItemType.contact;

  @override
  AsyncDbResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await contactHistoryDao.getContactHistoryByHistoryIds([
          historyId,
        ]);
        if (rows.isEmpty) return const None();

        final item = rows.first;

        return Some(
          ContactHistoryPayload(
            firstName: item.firstName,
            middleName: item.middleName,
            lastName: item.lastName,
            phone: item.phone,
            email: item.email,
            company: item.company,
            jobTitle: item.jobTitle,
            address: item.address,
            website: item.website,
            birthday: item.birthday,
            isEmergencyContact: item.isEmergencyContact,
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации истории контакта',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  @override
  AsyncDbResult<Optional<HistoryPayload>> normalizeCurrent({
    required String itemId,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final viewOpt = (await contactRepository.getViewById(itemId))
            .getOrThrow();
        return viewOpt.fold(
          (view) {
            final item = view.contact;
            return Some(
              ContactHistoryPayload(
                firstName: item.firstName,
                middleName: item.middleName,
                lastName: item.lastName,
                phone: item.phone,
                email: item.email,
                company: item.company,
                jobTitle: item.jobTitle,
                address: item.address,
                website: item.website,
                birthday: item.birthday,
                isEmergencyContact: item.isEmergencyContact,
              ),
            );
          },
          () => const None(),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации текущего состояния контакта',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
