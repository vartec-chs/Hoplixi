import '../../../tables/bank_card/bank_card_items.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class BankCardHistoryPayload extends HistoryPayload {
  const BankCardHistoryPayload({
    this.cardholderName,
    this.cardNumber,
    this.cardType,
    this.cardTypeOther,
    this.cardNetwork,
    this.cardNetworkOther,
    this.expiryMonth,
    this.expiryYear,
    this.cvv,
    this.bankName,
    this.accountNumber,
    this.routingNumber,
  });

  final String? cardholderName;
  final String? cardNumber;
  final CardType? cardType;
  final String? cardTypeOther;
  final CardNetwork? cardNetwork;
  final String? cardNetworkOther;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cvv;
  final String? bankName;
  final String? accountNumber;
  final String? routingNumber;

  @override
  VaultItemType get type => VaultItemType.bankCard;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(
        key: 'bankCard.cardholderName',
        label: 'Cardholder name',
        value: cardholderName,
      ),
      HistoryFieldSnapshot<String>(
        key: 'bankCard.cardNumber',
        label: 'Card number',
        value: cardNumber,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'bankCard.cardType',
        label: 'Card type',
        value: cardType?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'bankCard.cardTypeOther',
        label: 'Card type other',
        value: cardTypeOther,
      ),
      HistoryFieldSnapshot<String>(
        key: 'bankCard.cardNetwork',
        label: 'Card network',
        value: cardNetwork?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'bankCard.cardNetworkOther',
        label: 'Card network other',
        value: cardNetworkOther,
      ),
      HistoryFieldSnapshot<String>(
        key: 'bankCard.expiryMonth',
        label: 'Expiry month',
        value: expiryMonth,
      ),
      HistoryFieldSnapshot<String>(
        key: 'bankCard.expiryYear',
        label: 'Expiry year',
        value: expiryYear,
      ),
      HistoryFieldSnapshot<String>(
        key: 'bankCard.cvv',
        label: 'CVV',
        value: cvv,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'bankCard.bankName',
        label: 'Bank name',
        value: bankName,
      ),
      HistoryFieldSnapshot<String>(
        key: 'bankCard.accountNumber',
        label: 'Account number',
        value: accountNumber,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'bankCard.routingNumber',
        label: 'Routing number',
        value: routingNumber,
        isSensitive: true,
      ),
    ];
  }
}
