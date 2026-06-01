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
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
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
  String _productName = '';
  String? _vendor;
  String _licenseKey = '';
  String? _licenseType;
  String? _orderNumber;
  DateTime? _purchaseDate;
  DateTime? _validFrom;
  DateTime? _validTo;
  int? _seats;
  int? _activationLimit;
  String? _description;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repos = await ref.read(vaultRepositories.future);
      if (!mounted) return;
      final viewResult = await repos.licenseKey.getViewById(widget.licenseKeyId);
      final view = viewResult.getOrNull()?.getOrNull();
      if (view == null) {
        if (mounted) {
          Toaster.error(title: context.t.dashboard_forms.common_record_not_found);
          context.pop();
        }
        return;
      }
      final item = view.item;
      final licenseKey = view.licenseKey;

      setState(() {
        _isDeleted = item.isDeleted;
        _name = item.name;
        _productName = licenseKey.productName;
        _vendor = licenseKey.vendor;
        _licenseKey = licenseKey.licenseKey;
        _licenseType = licenseKey.licenseType?.name;
        _orderNumber = licenseKey.orderNumber;
        _purchaseDate = licenseKey.purchaseDate;
        _validFrom = licenseKey.validFrom;
        _validTo = licenseKey.validTo;
        _seats = licenseKey.seats;
        _activationLimit = licenseKey.activationLimit;
        _description = item.description;
      });
    } catch (e) {
      if (mounted) {
        Toaster.error(
          title: context.t.dashboard_forms.common_load_error,
          description: '$e',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(DateTime? value) {
    if (value == null) return '-';
    return value.toIso8601String().split('T')[0];
  }

  Future<void> _share() async {
    final l10n = context.t.dashboard_forms;
    final customFields = await loadCustomShareableFields(
      ref,
      widget.licenseKeyId,
    );
    if (!mounted) return;
    final fields = [
      ...compactShareableFields([
        shareableField(id: 'name', label: l10n.share_name_label, value: _name),
        shareableField(
          id: 'product',
          label: l10n.product_label,
          value: _productName,
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
          id: 'activation_limit',
          label: 'Лимит активаций',
          value: _activationLimit,
        ),
        shareableField(
          id: 'valid_from',
          label: 'Действителен с',
          value: _validFrom,
        ),
        shareableField(
          id: 'purchase_date',
          label: l10n.purchase_date_iso_label,
          value: _purchaseDate,
        ),
        shareableField(
          id: 'vendor',
          label: 'Продавец',
          value: _vendor,
        ),
        shareableField(
          id: 'order_number',
          label: 'Номер заказа',
          value: _orderNumber,
        ),
        shareableField(
          id: 'valid_to',
          label: 'Действителен до',
          value: _validTo,
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
                    subtitle: Text(_productName),
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
                   if (_activationLimit != null)
                    ListTile(
                      title: const Text('Лимит активаций'),
                      subtitle: Text('$_activationLimit'),
                    ),
                  if (_validFrom != null)
                    ListTile(
                      title: const Text('Действителен с'),
                      subtitle: Text(_fmt(_validFrom)),
                    ),
                  if (_purchaseDate != null)
                    ListTile(
                      title: Text(l10n.purchase_date_iso_label),
                      subtitle: Text(_fmt(_purchaseDate)),
                    ),
                  if (_vendor?.isNotEmpty == true)
                    ListTile(
                      title: const Text('Продавец'),
                      subtitle: Text(_vendor!),
                    ),
                  if (_orderNumber?.isNotEmpty == true)
                    ListTile(
                      title: const Text('Номер заказа'),
                      subtitle: Text(_orderNumber!),
                    ),
                  if (_validTo != null)
                    ListTile(
                      title: const Text('Действителен до'),
                      subtitle: Text(_fmt(_validTo)),
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
