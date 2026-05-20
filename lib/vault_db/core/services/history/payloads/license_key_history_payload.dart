import '../../../tables/license_key/license_key_items.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class LicenseKeyHistoryPayload extends HistoryPayload {
  const LicenseKeyHistoryPayload({
    required this.productName,
    this.vendor,
    required this.licenseKey,
    this.licenseType,
    this.licenseTypeOther,
    this.accountEmail,
    this.accountUsername,
    this.purchaseEmail,
    this.orderNumber,
    this.purchaseDate,
    this.purchasePrice,
    this.currency,
    this.validFrom,
    this.validTo,
    this.renewalDate,
    this.seats,
    this.activationLimit,
    this.activationsUsed,
  });

  final String productName;
  final String? vendor;
  final String? licenseKey;
  final LicenseType? licenseType;
  final String? licenseTypeOther;
  final String? accountEmail;
  final String? accountUsername;
  final String? purchaseEmail;
  final String? orderNumber;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final String? currency;
  final DateTime? validFrom;
  final DateTime? validTo;
  final DateTime? renewalDate;
  final int? seats;
  final int? activationLimit;
  final int? activationsUsed;

  @override
  VaultItemType get type => VaultItemType.licenseKey;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(
        key: 'licenseKey.productName',
        label: 'Product name',
        value: productName,
      ),
      HistoryFieldSnapshot<String>(
        key: 'licenseKey.vendor',
        label: 'Vendor',
        value: vendor,
      ),
      HistoryFieldSnapshot<String>(
        key: 'licenseKey.licenseKey',
        label: 'License key',
        value: licenseKey,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'licenseKey.licenseType',
        label: 'License type',
        value: licenseType?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'licenseKey.licenseTypeOther',
        label: 'License type other',
        value: licenseTypeOther,
      ),
      HistoryFieldSnapshot<String>(
        key: 'licenseKey.accountEmail',
        label: 'Account email',
        value: accountEmail,
      ),
      HistoryFieldSnapshot<String>(
        key: 'licenseKey.accountUsername',
        label: 'Account username',
        value: accountUsername,
      ),
      HistoryFieldSnapshot<String>(
        key: 'licenseKey.purchaseEmail',
        label: 'Purchase email',
        value: purchaseEmail,
      ),
      HistoryFieldSnapshot<String>(
        key: 'licenseKey.orderNumber',
        label: 'Order number',
        value: orderNumber,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'licenseKey.purchaseDate',
        label: 'Purchase date',
        value: purchaseDate,
      ),
      HistoryFieldSnapshot<double>(
        key: 'licenseKey.purchasePrice',
        label: 'Purchase price',
        value: purchasePrice,
      ),
      HistoryFieldSnapshot<String>(
        key: 'licenseKey.currency',
        label: 'Currency',
        value: currency,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'licenseKey.validFrom',
        label: 'Valid from',
        value: validFrom,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'licenseKey.validTo',
        label: 'Valid to',
        value: validTo,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'licenseKey.renewalDate',
        label: 'Renewal date',
        value: renewalDate,
      ),
      HistoryFieldSnapshot<int>(
        key: 'licenseKey.seats',
        label: 'Seats',
        value: seats,
      ),
      HistoryFieldSnapshot<int>(
        key: 'licenseKey.activationLimit',
        label: 'Activation limit',
        value: activationLimit,
      ),
      HistoryFieldSnapshot<int>(
        key: 'licenseKey.activationsUsed',
        label: 'Activations used',
        value: activationsUsed,
      ),
    ];
  }
}
