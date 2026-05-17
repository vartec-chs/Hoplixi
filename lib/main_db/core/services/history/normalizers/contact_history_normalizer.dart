import 'package:hoplixi/main_db/core/repositories/base/contact_repository.dart';

import '../../../daos/daos.dart';
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
  Future<HistoryPayload?> normalizeHistory({required String historyId}) async {
    final rows = await contactHistoryDao.getContactHistoryByHistoryIds([
      historyId,
    ]);
    if (rows.isEmpty) return null;

    final item = rows.first;

    return ContactHistoryPayload(
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
    );
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({required String itemId}) async {
    final view = await contactRepository.getViewById(itemId);
    if (view == null) return null;

    final item = view.contact;

    return ContactHistoryPayload(
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
    );
  }
}
