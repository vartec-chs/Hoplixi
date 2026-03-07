import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';

class IdentityViewScreen extends ConsumerStatefulWidget {
  const IdentityViewScreen({super.key, required this.identityId});

  final String identityId;

  @override
  ConsumerState<IdentityViewScreen> createState() => _IdentityViewScreenState();
}

class _IdentityViewScreenState extends ConsumerState<IdentityViewScreen> {
  bool _loading = true;

  String _name = '';
  String _idType = '';
  String _idNumber = '';
  String? _fullName;
  DateTime? _dateOfBirth;
  String? _placeOfBirth;
  String? _nationality;
  String? _issuingAuthority;
  DateTime? _issueDate;
  DateTime? _expiryDate;
  String? _mrz;
  String? _scanAttachmentId;
  String? _photoAttachmentId;
  String? _description;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(identityDaoProvider.future);
      final row = await dao.getById(widget.identityId);
      if (row == null) {
        Toaster.error(title: context.t.dashboard_forms.common_record_not_found);
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final identity = row.$2;

      setState(() {
        _name = item.name;
        _idType = identity.idType;
        _idNumber = identity.idNumber;
        _fullName = identity.fullName;
        _dateOfBirth = identity.dateOfBirth;
        _placeOfBirth = identity.placeOfBirth;
        _nationality = identity.nationality;
        _issuingAuthority = identity.issuingAuthority;
        _issueDate = identity.issueDate;
        _expiryDate = identity.expiryDate;
        _mrz = identity.mrz;
        _scanAttachmentId = identity.scanAttachmentId;
        _photoAttachmentId = identity.photoAttachmentId;
        _description = item.description;
        _verified = identity.verified;
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

  String _fmt(DateTime? value) {
    if (value == null) return '-';
    return value.toIso8601String();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.dashboard_forms;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.view_identity),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            onPressed: () => context.push(
              AppRoutesPaths.dashboardEntityEdit(
                EntityType.identity,
                widget.identityId,
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
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text(l10n.document_type_required_label),
                    subtitle: Text(_idType),
                  ),
                  ListTile(
                    title: Text(l10n.document_number_required_label),
                    subtitle: Text(_idNumber),
                  ),
                  if (_fullName?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.full_name_label),
                      subtitle: Text(_fullName!),
                    ),
                  ListTile(
                    title: Text(l10n.birth_date_iso_label),
                    subtitle: Text(_fmt(_dateOfBirth)),
                  ),
                  if (_placeOfBirth?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.place_of_birth_label),
                      subtitle: Text(_placeOfBirth!),
                    ),
                  if (_nationality?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.nationality_label),
                      subtitle: Text(_nationality!),
                    ),
                  if (_issuingAuthority?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.issuing_authority_label),
                      subtitle: Text(_issuingAuthority!),
                    ),
                  ListTile(
                    title: Text(l10n.issue_date_iso_label),
                    subtitle: Text(_fmt(_issueDate)),
                  ),
                  ListTile(
                    title: Text(l10n.expiry_date_iso_label),
                    subtitle: Text(_fmt(_expiryDate)),
                  ),
                  if (_mrz?.isNotEmpty == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.mrz_label),
                      subtitle: SelectableText(_mrz!),
                    ),
                  if (_scanAttachmentId?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.scan_id_label),
                      subtitle: Text(_scanAttachmentId!),
                    ),
                  if (_photoAttachmentId?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.photo_id_label),
                      subtitle: Text(_photoAttachmentId!),
                    ),
                  ListTile(
                    title: Text(l10n.verified_label),
                    subtitle: Text(
                      _verified ? l10n.common_yes : l10n.common_no,
                    ),
                  ),
                  if (_description?.isNotEmpty == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.description_label),
                      subtitle: Text(_description!),
                    ),
                ],
              ),
      ),
    );
  }
}
