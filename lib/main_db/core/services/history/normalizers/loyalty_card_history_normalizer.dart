import 'package:hoplixi/main_db/core/repositories/base/loyalty_card_repository.dart';

import '../../../daos/daos.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/loyalty_card_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class LoyaltyCardHistoryNormalizer implements VaultHistoryTypeNormalizer {
  LoyaltyCardHistoryNormalizer({
    required this.loyaltyCardHistoryDao,
    required this.loyaltyCardRepository,
  });

  final LoyaltyCardHistoryDao loyaltyCardHistoryDao;
  final LoyaltyCardRepository loyaltyCardRepository;

  @override
  VaultItemType get type => VaultItemType.loyaltyCard;

  @override
  Future<HistoryPayload?> normalizeHistory({
    required String historyId,
  }) async {
    final rows = await loyaltyCardHistoryDao.getLoyaltyCardHistoryByHistoryIds([historyId]);
    if (rows.isEmpty) return null;

    final item = rows.first;

    return LoyaltyCardHistoryPayload(
      programName: item.programName,
      cardNumber: item.cardNumber,
      barcodeValue: item.barcodeValue,
      password: item.password,
      barcodeType: item.barcodeType,
      barcodeTypeOther: item.barcodeTypeOther,
      issuer: item.issuer,
      website: item.website,
      phone: item.phone,
      email: item.email,
      validFrom: item.validFrom,
      validTo: item.validTo,
    );
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({
    required String itemId,
  }) async {
    final view = await loyaltyCardRepository.getViewById(itemId);
    if (view == null) return null;

    final item = view.loyaltyCard;

    return LoyaltyCardHistoryPayload(
      programName: item.programName,
      cardNumber: item.cardNumber,
      barcodeValue: item.barcodeValue,
      password: item.password,
      barcodeType: item.barcodeType,
      barcodeTypeOther: item.barcodeTypeOther,
      issuer: item.issuer,
      website: item.website,
      phone: item.phone,
      email: item.email,
      validFrom: item.validFrom,
      validTo: item.validTo,
    );
  }
}
