import 'package:hoplixi/vault_db/core/repositories/base/loyalty_card_repository.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../scheme/tables/vault_items/vault_items.dart';
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
  AsyncDbResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) {
    return tryCatchAsync(
      () async {
        final rows = await loyaltyCardHistoryDao
            .getLoyaltyCardHistoryByHistoryIds([historyId]);
        if (rows.isEmpty) return const None();

        final item = rows.first;

        return Some(
          LoyaltyCardHistoryPayload(
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
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации истории карты лояльности',
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
        final viewOpt = (await loyaltyCardRepository.getViewById(
          itemId,
        )).getOrThrow();
        return viewOpt.fold((view) {
          final item = view.loyaltyCard;
          return Some(
            LoyaltyCardHistoryPayload(
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
            ),
          );
        }, () => const None());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message:
                  'Ошибка при нормализации текущего состояния карты лояльности',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
