import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/new/providers/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/custom_fields/widgets/custom_fields_view_section.dart';

import '../models/contact_os_payload.dart';
import '../services/contact_os_bridge.dart';

class ContactViewScreen extends ConsumerStatefulWidget {
  const ContactViewScreen({super.key, required this.contactId});

  final String contactId;

  @override
  ConsumerState<ContactViewScreen> createState() => _ContactViewScreenState();
}

class _ContactViewScreenState extends ConsumerState<ContactViewScreen> {
  bool _loading = true;

  String _name = '';
  String? _phone;
  String? _email;
  String? _company;
  String? _jobTitle;
  String? _address;
  String? _website;
  DateTime? _birthday;
  String? _description;
  bool _isEmergencyContact = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(contactDaoProvider.future);
      final row = await dao.getById(widget.contactId);
      if (row == null) {
        Toaster.error(title: context.t.dashboard_forms.contact_not_found);
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final details = row.$2;
      setState(() {
        _name = item.name;
        _phone = details.phone;
        _email = details.email;
        _company = details.company;
        _jobTitle = details.jobTitle;
        _address = details.address;
        _website = details.website;
        _birthday = details.birthday;
        _description = item.description;
        _isEmergencyContact = details.isEmergencyContact;
      });
    } catch (e) {
      Toaster.error(
        title: context.t.dashboard_forms.common_load_error,
        description: '$e',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyValue(String? value, String label) async {
    if (value == null || value.isEmpty) {
      Toaster.warning(
        title: context.t.dashboard_forms.common_field_missing(Field: label),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    Toaster.success(
      title: context.t.dashboard_forms.common_field_copied(Field: label),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  }

  Future<void> _exportToOsContact() async {
    final l10n = context.t.dashboard_forms;

    if (!ContactOsBridge.supportsNativeOsContacts) {
      Toaster.info(
        title: l10n.os_contacts_unavailable,
        description: l10n.os_contacts_unavailable_description,
      );
      return;
    }

    final payload = ContactOsPayload(
      name: _name,
      phone: _phone,
      email: _email,
      company: _company,
      jobTitle: _jobTitle,
      address: _address,
      website: _website,
      birthday: _birthday,
    );

    if (ContactOsBridge.buildContact(payload) == null) {
      Toaster.warning(title: l10n.os_contact_export_requires_data);
      return;
    }

    try {
      final createdId = await ContactOsBridge.export(payload);
      if (!mounted || createdId == null) return;

      Toaster.success(title: l10n.os_contact_exported);
    } catch (error) {
      if (!mounted) return;
      Toaster.error(
        title: l10n.os_contact_export_failed,
        description: '$error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.dashboard_forms;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.view_contact),
        actions: [
          IconButton(
            tooltip: l10n.export_contact_to_os_tooltip,
            onPressed: _loading ? null : _exportToOsContact,
            icon: const Icon(Icons.upload_rounded),
          ),
          IconButton(
            tooltip: l10n.edit,
            onPressed: () => context.push(
              AppRoutesPaths.dashboardEntityEdit(
                EntityType.contact,
                widget.contactId,
              ),
            ),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(_name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  if (_company?.isNotEmpty == true)
                    Text(
                      _company!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  const SizedBox(height: 8),
                  if (_isEmergencyContact)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.warning_amber_rounded),
                      title: Text(l10n.emergency_contact_label),
                    ),
                  if (_phone?.isNotEmpty == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.phone_label),
                      subtitle: Text(_phone!),
                      trailing: IconButton(
                        onPressed: () => _copyValue(_phone, l10n.phone_label),
                        icon: const Icon(Icons.copy),
                      ),
                    ),
                  if (_email?.isNotEmpty == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.email_label),
                      subtitle: Text(_email!),
                      trailing: IconButton(
                        onPressed: () => _copyValue(_email, l10n.email_label),
                        icon: const Icon(Icons.copy),
                      ),
                    ),
                  if (_jobTitle?.isNotEmpty == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.job_title_label),
                      subtitle: Text(_jobTitle!),
                    ),
                  if (_address?.isNotEmpty == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.address_label),
                      subtitle: Text(_address!),
                    ),
                  if (_website?.isNotEmpty == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.website_label),
                      subtitle: Text(_website!),
                    ),
                  if (_birthday != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.birthday_label),
                      subtitle: Text(_formatDate(_birthday!)),
                    ),
                  if (_description?.isNotEmpty == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.description_label),
                      subtitle: Text(_description!),
                    ),
                  CustomFieldsViewSection(itemId: widget.contactId),
                ],
              ),
      ),
    );
  }
}
