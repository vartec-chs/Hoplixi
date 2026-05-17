import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class ContactHistoryPayload extends HistoryPayload {
  const ContactHistoryPayload({
    required this.firstName,
    this.middleName,
    this.lastName,
    this.phone,
    this.email,
    this.company,
    this.jobTitle,
    this.address,
    this.website,
    this.birthday,
    required this.isEmergencyContact,
  });

  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? company;
  final String? jobTitle;
  final String? address;
  final String? website;
  final DateTime? birthday;
  final bool isEmergencyContact;

  @override
  VaultItemType get type => VaultItemType.contact;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(
        key: 'contact.firstName',
        label: 'First name',
        value: firstName,
      ),
      HistoryFieldSnapshot<String>(
        key: 'contact.middleName',
        label: 'Middle name',
        value: middleName,
      ),
      HistoryFieldSnapshot<String>(
        key: 'contact.lastName',
        label: 'Last name',
        value: lastName,
      ),
      HistoryFieldSnapshot<String>(
        key: 'contact.phone',
        label: 'Phone',
        value: phone,
      ),
      HistoryFieldSnapshot<String>(
        key: 'contact.email',
        label: 'Email',
        value: email,
      ),
      HistoryFieldSnapshot<String>(
        key: 'contact.company',
        label: 'Company',
        value: company,
      ),
      HistoryFieldSnapshot<String>(
        key: 'contact.jobTitle',
        label: 'Job title',
        value: jobTitle,
      ),
      HistoryFieldSnapshot<String>(
        key: 'contact.address',
        label: 'Address',
        value: address,
      ),
      HistoryFieldSnapshot<String>(
        key: 'contact.website',
        label: 'Website',
        value: website,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'contact.birthday',
        label: 'Birthday',
        value: birthday,
      ),
      HistoryFieldSnapshot<bool>(
        key: 'contact.isEmergencyContact',
        label: 'Emergency contact',
        value: isEmergencyContact,
      ),
    ];
  }
}
