import 'package:hoplixi/main_db/core/repositories/base/bank_card_repository.dart';

import '../../../daos/daos.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/bank_card_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class BankCardHistoryNormalizer implements VaultHistoryTypeNormalizer {
  BankCardHistoryNormalizer({
    required this.bankCardHistoryDao,
    required this.bankCardRepository,
  });

  final BankCardHistoryDao bankCardHistoryDao;
  final BankCardRepository bankCardRepository;

  @override
  VaultItemType get type => VaultItemType.bankCard;

  @override
  Future<HistoryPayload?> normalizeHistory({
    required String historyId,
  }) async {
    final rows = await bankCardHistoryDao.getBankCardHistoryByHistoryIds([historyId]);
    if (rows.isEmpty) return null;

    final item = rows.first;

    return BankCardHistoryPayload(
      cardholderName: item.cardholderName,
      cardNumber: item.cardNumber,
      cardType: item.cardType,
      cardTypeOther: item.cardTypeOther,
      cardNetwork: item.cardNetwork,
      cardNetworkOther: item.cardNetworkOther,
      expiryMonth: item.expiryMonth,
      expiryYear: item.expiryYear,
      cvv: item.cvv,
      bankName: item.bankName,
      accountNumber: item.accountNumber,
      routingNumber: item.routingNumber,
    );
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({
    required String itemId,
  }) async {
    final view = await bankCardRepository.getViewById(itemId);
    if (view == null) return null;

    final item = view.bankCard;

    return BankCardHistoryPayload(
      cardholderName: item.cardholderName,
      cardNumber: item.cardNumber,
      cardType: item.cardType,
      cardTypeOther: item.cardTypeOther,
      cardNetwork: item.cardNetwork,
      cardNetworkOther: item.cardNetworkOther,
      expiryMonth: item.expiryMonth,
      expiryYear: item.expiryYear,
      cvv: item.cvv,
      bankName: item.bankName,
      accountNumber: item.accountNumber,
      routingNumber: item.routingNumber,
    );
  }
}
