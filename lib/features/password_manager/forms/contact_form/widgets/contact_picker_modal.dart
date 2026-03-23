import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../services/contact_os_bridge.dart';

Future<Contact?> showOsContactPickerModal(
  BuildContext context, {
  required List<Contact> contacts,
}) {
  return WoltModalSheet.show<Contact>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (modalContext) => [
      WoltModalSheetPage(
        hasSabGradient: false,
        topBarTitle: Text(
          context.t.dashboard_forms.import_contact_from_os_tooltip,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        isTopBarLayerAlwaysVisible: true,
        trailingNavBarWidget: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(modalContext).pop(),
        ),
        child: _OsContactsPickerContent(contacts: contacts),
      ),
    ],
  );
}

class _OsContactsPickerContent extends StatefulWidget {
  const _OsContactsPickerContent({required this.contacts});

  final List<Contact> contacts;

  @override
  State<_OsContactsPickerContent> createState() =>
      _OsContactsPickerContentState();
}

class _OsContactsPickerContentState extends State<_OsContactsPickerContent> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredContacts = widget.contacts.where(_matchesQuery).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: primaryInputDecoration(
              context,
              labelText: context.t.dashboard_forms.contact_name_label,
              hintText: context.t.dashboard_forms.enter_name_hint,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: filteredContacts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(context.t.dashboard_forms.contact_not_found),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredContacts.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          ContactOsBridge.resolveName(contact),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _buildSubtitle(contact),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(contact),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  bool _matchesQuery(Contact contact) {
    if (_query.isEmpty) return true;

    final haystack = [
      ContactOsBridge.resolveName(contact),
      ContactOsBridge.normalize(contact.displayName),
      ContactOsBridge.normalize(contact.name?.nickname),
      ContactOsBridge.normalize(
        contact.organizations.isEmpty ? null : contact.organizations.first.name,
      ),
      ContactOsBridge.normalize(
        contact.phones.isEmpty ? null : contact.phones.first.number,
      ),
      ContactOsBridge.normalize(
        contact.emails.isEmpty ? null : contact.emails.first.address,
      ),
      ContactOsBridge.resolveAddress(
        contact.addresses.isEmpty ? null : contact.addresses.first,
      ),
    ].whereType<String>().join(' ').toLowerCase();

    return haystack.contains(_query);
  }

  String _buildSubtitle(Contact contact) {
    final parts = [
      ContactOsBridge.normalize(
        contact.organizations.isEmpty ? null : contact.organizations.first.name,
      ),
      ContactOsBridge.normalize(
        contact.phones.isEmpty ? null : contact.phones.first.number,
      ),
      ContactOsBridge.normalize(
        contact.emails.isEmpty ? null : contact.emails.first.address,
      ),
    ].whereType<String>().toList();

    if (parts.isEmpty) {
      return context.t.dashboard_forms.not_specified;
    }

    return parts.join(' | ');
  }
}
