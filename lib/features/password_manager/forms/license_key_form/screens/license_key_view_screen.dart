import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/generated/l10n.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
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
        Toaster.error(title: S.of(context).commonRecordNotFound);
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final license = row.$2;

      setState(() {
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
      Toaster.error(title: S.of(context).commonLoadError, description: '$e');
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
    final l10n = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.viewLicense),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            onPressed: () => context.push(
              AppRoutesPaths.dashboardEntityEdit(
                EntityType.licenseKey,
                widget.licenseKeyId,
              ),
            ),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(_name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                ListTile(title: Text(l10n.productLabel), subtitle: Text(_product)),
                ListTile(
                  title: Text(l10n.licenseKeyLabel),
                  subtitle: SelectableText(_licenseKey),
                ),
                if (_licenseType?.isNotEmpty == true)
                  ListTile(
                    title: Text(l10n.licenseTypeLabel),
                    subtitle: Text(_licenseType!),
                  ),
                if (_seats != null)
                  ListTile(
                    title: Text(l10n.seatsCountLabel),
                    subtitle: Text('$_seats'),
                  ),
                if (_maxActivations != null)
                  ListTile(
                    title: Text(l10n.maxActivationsLabel),
                    subtitle: Text('$_maxActivations'),
                  ),
                ListTile(
                  title: Text(l10n.activatedAtIsoLabel),
                  subtitle: Text(_fmt(_activatedOn)),
                ),
                ListTile(
                  title: Text(l10n.purchaseDateIsoLabel),
                  subtitle: Text(_fmt(_purchaseDate)),
                ),
                if (_purchaseFrom?.isNotEmpty == true)
                  ListTile(
                    title: Text(l10n.purchasedFromLabel),
                    subtitle: Text(_purchaseFrom!),
                  ),
                if (_orderId?.isNotEmpty == true)
                  ListTile(title: Text(l10n.orderIdLabel), subtitle: Text(_orderId!)),
                if (_licenseFileId?.isNotEmpty == true)
                  ListTile(
                    title: Text(l10n.licenseFileIdLabel),
                    subtitle: Text(_licenseFileId!),
                  ),
                ListTile(
                  title: Text(l10n.expiresAtIsoLabel),
                  subtitle: Text(_fmt(_expiresAt)),
                ),
                if (_supportContact?.isNotEmpty == true)
                  ListTile(
                    title: Text(l10n.supportContactLabel),
                    subtitle: Text(_supportContact!),
                  ),
                if (_description?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.descriptionLabel),
                    subtitle: Text(_description!),
                  ),
              ],
            ),
    );
  }
}
