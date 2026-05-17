import '../../../tables/loyalty_card/loyalty_card_items.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class LoyaltyCardHistoryPayload extends HistoryPayload {
  const LoyaltyCardHistoryPayload({
    required this.programName,
    this.cardNumber,
    this.barcodeValue,
    this.password,
    this.barcodeType,
    this.barcodeTypeOther,
    this.issuer,
    this.website,
    this.phone,
    this.email,
    this.validFrom,
    this.validTo,
  });

  final String programName;
  final String? cardNumber;
  final String? barcodeValue;
  final String? password;
  final LoyaltyBarcodeType? barcodeType;
  final String? barcodeTypeOther;
  final String? issuer;
  final String? website;
  final String? phone;
  final String? email;
  final DateTime? validFrom;
  final DateTime? validTo;

  @override
  VaultItemType get type => VaultItemType.loyaltyCard;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(
        key: 'loyaltyCard.programName',
        label: 'Program name',
        value: programName,
      ),
      HistoryFieldSnapshot<String>(
        key: 'loyaltyCard.cardNumber',
        label: 'Card number',
        value: cardNumber,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'loyaltyCard.barcodeValue',
        label: 'Barcode value',
        value: barcodeValue,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'loyaltyCard.password',
        label: 'Password',
        value: password,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'loyaltyCard.barcodeType',
        label: 'Barcode type',
        value: barcodeType?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'loyaltyCard.barcodeTypeOther',
        label: 'Barcode type other',
        value: barcodeTypeOther,
      ),
      HistoryFieldSnapshot<String>(
        key: 'loyaltyCard.issuer',
        label: 'Issuer',
        value: issuer,
      ),
      HistoryFieldSnapshot<String>(
        key: 'loyaltyCard.website',
        label: 'Website',
        value: website,
      ),
      HistoryFieldSnapshot<String>(
        key: 'loyaltyCard.phone',
        label: 'Phone',
        value: phone,
      ),
      HistoryFieldSnapshot<String>(
        key: 'loyaltyCard.email',
        label: 'Email',
        value: email,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'loyaltyCard.validFrom',
        label: 'Valid from',
        value: validFrom,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'loyaltyCard.validTo',
        label: 'Valid to',
        value: validTo,
      ),
    ];
  }
}
