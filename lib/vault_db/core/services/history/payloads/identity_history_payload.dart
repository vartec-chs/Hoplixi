import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class IdentityHistoryPayload extends HistoryPayload {
  const IdentityHistoryPayload({
    this.firstName,
    this.middleName,
    this.lastName,
    this.displayName,
    this.username,
    this.email,
    this.phone,
    this.address,
    this.birthday,
    this.company,
    this.jobTitle,
    this.website,
    this.taxId,
    this.nationalId,
    this.passportNumber,
    this.driverLicenseNumber,
  });

  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? displayName;
  final String? username;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime? birthday;
  final String? company;
  final String? jobTitle;
  final String? website;
  final String? taxId;
  final String? nationalId;
  final String? passportNumber;
  final String? driverLicenseNumber;

  @override
  VaultItemType get type => VaultItemType.identity;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(
        key: 'identity.firstName',
        label: 'First name',
        value: firstName,
      ),
      HistoryFieldSnapshot<String>(
        key: 'identity.middleName',
        label: 'Middle name',
        value: middleName,
      ),
      HistoryFieldSnapshot<String>(
        key: 'identity.lastName',
        label: 'Last name',
        value: lastName,
      ),
      HistoryFieldSnapshot<String>(
        key: 'identity.displayName',
        label: 'Display name',
        value: displayName,
      ),
      HistoryFieldSnapshot<String>(
        key: 'identity.username',
        label: 'Username',
        value: username,
      ),
      HistoryFieldSnapshot<String>(
        key: 'identity.email',
        label: 'Email',
        value: email,
      ),
      HistoryFieldSnapshot<String>(
        key: 'identity.phone',
        label: 'Phone',
        value: phone,
      ),
      HistoryFieldSnapshot<String>(
        key: 'identity.address',
        label: 'Address',
        value: address,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'identity.birthday',
        label: 'Birthday',
        value: birthday,
      ),
      HistoryFieldSnapshot<String>(
        key: 'identity.company',
        label: 'Company',
        value: company,
      ),
      HistoryFieldSnapshot<String>(
        key: 'identity.jobTitle',
        label: 'Job title',
        value: jobTitle,
      ),
      HistoryFieldSnapshot<String>(
        key: 'identity.website',
        label: 'Website',
        value: website,
      ),
      HistoryFieldSnapshot<String>(
        key: 'identity.taxId',
        label: 'Tax ID',
        value: taxId,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'identity.nationalId',
        label: 'National ID',
        value: nationalId,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'identity.passportNumber',
        label: 'Passport number',
        value: passportNumber,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'identity.driverLicenseNumber',
        label: 'Driver license number',
        value: driverLicenseNumber,
        isSensitive: true,
      ),
    ];
  }
}
