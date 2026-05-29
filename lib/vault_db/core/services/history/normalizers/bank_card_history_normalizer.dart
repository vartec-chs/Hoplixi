import 'package:hoplixi/vault_db/core/repositories/base/bank_card_repository.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../scheme/tables/vault_items/vault_items.dart';
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
  AsyncDbResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) {
    return tryCatchAsync(
      () async {
        final rows = await bankCardHistoryDao.getBankCardHistoryByHistoryIds([
          historyId,
        ]);
        if (rows.isEmpty) return const None();

        final item = rows.first;

        return Some(
          BankCardHistoryPayload(
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
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации истории банковской карты',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  @override
  AsyncDbResult<Optional<HistoryPayload>> normalizeCurrent({
    required String itemId,
  }) {
    return tryCatchAsync(
      () async {
        final viewOpt = (await bankCardRepository.getViewById(
          itemId,
        )).getOrThrow();
        return viewOpt.fold((view) {
          final item = view.bankCard;
          return Some(
            BankCardHistoryPayload(
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
            ),
          );
        }, () => const None());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message:
                  'Ошибка при нормализации текущего состояния банковской карты',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
