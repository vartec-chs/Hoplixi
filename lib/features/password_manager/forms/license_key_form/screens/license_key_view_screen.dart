import 'package:hoplixi/shared/ui/background_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_view_section.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';

class LicenseKeyViewScreen extends ConsumerStatefulWidget {
  const LicenseKeyViewScreen({super.key, required this.licenseKeyId});

  final String licenseKeyId;

  @override
  ConsumerState<LicenseKeyViewScreen> createState() =>
      _LicenseKeyViewScreenState();
}

class _LicenseKeyViewScreenState extends ConsumerState<LicenseKeyViewScreen> {
  bool _loading = true;
  bool _isDeleted = false;

  String _name = '';
  String _product = '';
  String _licenseKey = '';
  String? _licenseType;
  int? _seats;
  int? _maxActivations;
  DateTime? _activatedOn;
  DateTime? _purchaseDate;
  String? _purchaseFrom;
  String? _orderId;
  String? _licenseFileId;
  DateTime? _expiresAt;
  String? _supportContact;
  String? _description;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(licenseKeyDaoProvider.future);
      final row = await dao.getById(widget.licenseKeyId);
      if (row == null) {
        Toaster.error(title: context.t.dashboard_forms.common_record_not_found);
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final license = row.$2;

      setState(() {
        _isDeleted = item.isDeleted;
        _name = item.name;
        _product = license.product;
        _licenseKey = license.licenseKey;
        _licenseType = license.licenseType;
        _seats = license.seats;
        _maxActivations = license.maxActivations;
        _activatedOn = license.activatedOn;
        _purchaseDate = license.purchaseDate;
        _purchaseFrom = license.purchaseFrom;
        _orderId = license.orderId;
        _licenseFileId = license.licenseFileId;
        _expiresAt = license.expiresAt;
        _supportContact = license.supportContact;
        _description = item.description;
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

  Future<void> _share() async {
    final l10n = context.t.dashboard_forms;
    final customFields = await loadCustomShareableFields(
      ref,
      widget.licenseKeyId,
    );
    final fields = [
      ...compactShareableFields([
        shareableField(id: 'name', label: l10n.share_name_label, value: _name),
        shareableField(
          id: 'product',
          label: l10n.product_label,
          value: _product,
        ),
        shareableField(
          id: 'license_key',
          label: l10n.license_key_label,
          value: _licenseKey,
          isSensitive: true,
        ),
        shareableField(
          id: 'license_type',
          label: l10n.license_type_label,
          value: _licenseType,
        ),
        shareableField(
          id: 'seats',
          label: l10n.seats_count_label,
          value: _seats,
        ),
        shareableField(
          id: 'max_activations',
          label: l10n.max_activations_label,
          value: _maxActivations,
        ),
        shareableField(
          id: 'activated_on',
          label: l10n.activated_at_iso_label,
          value: _activatedOn,
        ),
        shareableField(
          id: 'purchase_date',
          label: l10n.purchase_date_iso_label,
          value: _purchaseDate,
        ),
        shareableField(
          id: 'purchase_from',
          label: l10n.purchased_from_label,
          value: _purchaseFrom,
        ),
        shareableField(
          id: 'order_id',
          label: l10n.order_id_label,
          value: _orderId,
        ),
        shareableField(
          id: 'license_file',
          label: l10n.license_file_id_label,
          value: _licenseFileId,
        ),
        shareableField(
          id: 'expires_at',
          label: l10n.expires_at_iso_label,
          value: _expiresAt,
        ),
        shareableField(
          id: 'support_contact',
          label: l10n.support_contact_label,
          value: _supportContact,
        ),
        shareableField(
          id: 'description',
          label: l10n.description_label,
          value: _description,
        ),
      ]),
      ...customFields,
    ];

    await shareEntityFields(
      context: context,
      entity: ShareableEntity(
        title: _name,
        entityTypeLabel: EntityType.licenseKey.label,
        fields: fields,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.dashboard_forms;

    return Scaffold(
      backgroundColor: getScreenBackgroundColor(context, ref),
      appBar: AppBar(
        title: Text(l10n.view_license),
        actions: [
          IconButton(
            tooltip: l10n.share_action,
            onPressed: _loading || _isDeleted ? null : _share,
            icon: const Icon(Icons.share),
          ),
          IconButton(
            tooltip: l10n.edit,
            onPressed: _isDeleted
                ? null
                : () => context.push(
                    AppRoutesPaths.dashboardEntityEdit(
                      EntityType.licenseKey,
                      widget.licenseKeyId,
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
                    title: Text(l10n.product_label),
                    subtitle: Text(_product),
                  ),
                  ListTile(
                    title: Text(l10n.license_key_label),
                    subtitle: SelectableText(_licenseKey),
                  ),
                  if (_licenseType?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.license_type_label),
                      subtitle: Text(_licenseType!),
                    ),
                  if (_seats != null)
                    ListTile(
                      title: Text(l10n.seats_count_label),
                      subtitle: Text('$_seats'),
                    ),
                  if (_maxActivations != null)
                    ListTile(
                      title: Text(l10n.max_activations_label),
                      subtitle: Text('$_maxActivations'),
                    ),
                  ListTile(
                    title: Text(l10n.activated_at_iso_label),
                    subtitle: Text(_fmt(_activatedOn)),
                  ),
                  ListTile(
                    title: Text(l10n.purchase_date_iso_label),
                    subtitle: Text(_fmt(_purchaseDate)),
                  ),
                  if (_purchaseFrom?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.purchased_from_label),
                      subtitle: Text(_purchaseFrom!),
                    ),
                  if (_orderId?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.order_id_label),
                      subtitle: Text(_orderId!),
                    ),
                  if (_licenseFileId?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.license_file_id_label),
                      subtitle: Text(_licenseFileId!),
                    ),
                  ListTile(
                    title: Text(l10n.expires_at_iso_label),
                    subtitle: Text(_fmt(_expiresAt)),
                  ),
                  if (_supportContact?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.support_contact_label),
                      subtitle: Text(_supportContact!),
                    ),
                  if (_description?.isNotEmpty == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.description_label),
                      subtitle: Text(_description!),
                    ),
                  CustomFieldsViewSection(itemId: widget.licenseKeyId),
                ],
              ),
      ),
    );
  }
}
