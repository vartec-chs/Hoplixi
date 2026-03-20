import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:universal_platform/universal_platform.dart';

import '../models/contact_os_payload.dart';

class ContactOsBridge {
  const ContactOsBridge._();

  static const Set<ContactProperty> importProperties = {
    ContactProperty.name,
    ContactProperty.phone,
    ContactProperty.email,
    ContactProperty.address,
    ContactProperty.organization,
    ContactProperty.website,
    ContactProperty.event,
    ContactProperty.identifiers,
  };

  static bool get supportsNativeOsContacts =>
      UniversalPlatform.isAndroid || UniversalPlatform.isIOS;

  static Future<PermissionStatus> requestReadPermission() {
    return FlutterContacts.permissions.request(PermissionType.read);
  }

  static Future<List<Contact>> loadImportCandidates() async {
    final contacts = await FlutterContacts.getAll(properties: importProperties);

    final mergedContacts = <String, Contact>{};
    for (final contact in contacts) {
      mergedContacts[contactIdentity(contact)] = contact;
    }

    if (UniversalPlatform.isAndroid) {
      final simContacts = await FlutterContacts.sim.get();
      for (final contact in simContacts) {
        mergedContacts.putIfAbsent(contactIdentity(contact), () => contact);
      }
    }

    final values = mergedContacts.values.toList()
      ..sort((a, b) => resolveName(a).compareTo(resolveName(b)));

    return values;
  }

  static Future<String?> export(ContactOsPayload payload) {
    final contact = buildContact(payload);
    if (contact == null) {
      return Future.value(null);
    }

    return FlutterContacts.native.showCreator(contact: contact);
  }

  static Contact? buildContact(ContactOsPayload payload) {
    final name = normalize(payload.name);
    final phone = normalize(payload.phone);
    final email = normalize(payload.email);
    final company = normalize(payload.company);
    final jobTitle = normalize(payload.jobTitle);
    final address = normalize(payload.address);
    final website = normalize(payload.website);
    final birthday = payload.birthday;

    final hasData = [
      name,
      phone,
      email,
      company,
      jobTitle,
      address,
      website,
      birthday,
    ].any((value) => value != null);

    if (!hasData) {
      return null;
    }

    return Contact(
      displayName: name,
      name: _buildStructuredName(name),
      phones: phone == null ? const [] : [Phone(number: phone)],
      emails: email == null ? const [] : [Email(address: email)],
      addresses: address == null ? const [] : [Address(formatted: address)],
      organizations: company == null && jobTitle == null
          ? const []
          : [Organization(name: company, jobTitle: jobTitle)],
      websites: website == null ? const [] : [Website(url: website)],
      events: birthday == null
          ? const []
          : [
              Event(
                year: birthday.year,
                month: birthday.month,
                day: birthday.day,
                label: const Label(EventLabel.birthday),
              ),
            ],
    );
  }

  static Name? _buildStructuredName(String? fullName) {
    final normalized = normalize(fullName);
    if (normalized == null) {
      return null;
    }

    final parts = normalized.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return Name(first: parts.first);
    }

    return Name(
      first: parts.first,
      middle: parts.length > 2 ? parts.sublist(1, parts.length - 1).join(' ') : null,
      last: parts.last,
    );
  }

  static ContactOsPayload toPayload(Contact contact) {
    return ContactOsPayload(
      name: resolveName(contact),
      phone: normalize(firstOrNull(contact.phones)?.number),
      email: normalize(firstOrNull(contact.emails)?.address),
      company: normalize(firstOrNull(contact.organizations)?.name),
      jobTitle: normalize(firstOrNull(contact.organizations)?.jobTitle),
      address: resolveAddress(firstOrNull(contact.addresses)),
      website: normalize(firstOrNull(contact.websites)?.url),
      birthday: resolveBirthday(contact),
    );
  }

  static String contactIdentity(Contact contact) {
    final primaryValue = normalize(firstOrNull(contact.phones)?.number) ??
        normalize(firstOrNull(contact.emails)?.address) ??
        resolveName(contact);

    return primaryValue.toLowerCase();
  }

  static String resolveName(Contact contact) {
    final displayName = normalize(contact.displayName);
    if (displayName != null) return displayName;

    final name = contact.name;
    if (name != null) {
      final composed = [
        name.prefix,
        name.first,
        name.middle,
        name.last,
        name.suffix,
      ].where((part) => normalize(part) != null).join(' ');

      if (composed.isNotEmpty) {
        return composed;
      }

      final nickname = normalize(name.nickname);
      if (nickname != null) return nickname;
    }

    return normalize(firstOrNull(contact.phones)?.number) ??
        normalize(firstOrNull(contact.emails)?.address) ??
        '';
  }

  static String? resolveAddress(Address? address) {
    if (address == null) return null;

    return normalize(address.formatted) ??
        normalize(
          [
            address.street,
            address.city,
            address.state,
            address.postalCode,
            address.country,
          ].where((part) => normalize(part) != null).join(', '),
        );
  }

  static DateTime? resolveBirthday(Contact contact) {
    for (final event in contact.events) {
      if (event.label.label == EventLabel.birthday && event.year != null) {
        return DateTime(event.year!, event.month, event.day);
      }
    }
    return null;
  }

  static String? normalize(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  static T? firstOrNull<T>(List<T> values) {
    return values.isEmpty ? null : values.first;
  }
}


