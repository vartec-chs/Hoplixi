import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class ApiKeyViewScreen extends ConsumerStatefulWidget {
  const ApiKeyViewScreen({super.key, required this.apiKeyId});

  final String apiKeyId;

  @override
  ConsumerState<ApiKeyViewScreen> createState() => _ApiKeyViewScreenState();
}

class _ApiKeyViewScreenState extends ConsumerState<ApiKeyViewScreen> {
  bool _loading = true;
  bool _isDeleted = false;
  bool _revealingKey = false;
  String? _realKey;

  String _name = '';
  String _service = '';
  String? _maskedKey;
  String? _tokenType;
  String? _environment;
  String? _description;
  bool _revoked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(apiKeyDaoProvider.future);
      final row = await dao.getById(widget.apiKeyId);
      if (row == null) {
        Toaster.error(title: context.t.dashboard_forms.api_key_not_found);
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final details = row.$2;
      setState(() {
        _isDeleted = item.isDeleted;
        _name = item.name;
        _service = details.service;
        _maskedKey = details.maskedKey;
        _tokenType = details.tokenType;
        _environment = details.environment;
        _description = item.description;
        _revoked = details.revoked;
      });
    } catch (e) {
      Toaster.error(
        title: context.t.dashboard_forms.api_key_load_error,
        description: '$e',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revealKey() async {
    if (_realKey != null) {
      setState(() => _revealingKey = !_revealingKey);
      return;
    }

    try {
      final dao = await ref.read(apiKeyDaoProvider.future);
      final key = await dao.getKeyFieldById(widget.apiKeyId);
      if (key == null) {
        Toaster.error(title: context.t.dashboard_forms.api_key_reveal_error);
        return;
      }
      setState(() {
        _realKey = key;
        _revealingKey = true;
      });
    } catch (e) {
      Toaster.error(
        title: context.t.dashboard_forms.api_key_get_key_error,
        description: '$e',
      );
    }
  }

  Future<void> _copyKey() async {
    final value = _realKey ?? _maskedKey;
    if (value == null || value.isEmpty) {
      Toaster.warning(title: context.t.dashboard_forms.api_key_empty);
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    Toaster.success(title: context.t.dashboard_forms.api_key_copied);
  }

  Future<void> _share() async {
    final l10n = context.t.dashboard_forms;
    String? key = _realKey;
    try {
      final dao = await ref.read(apiKeyDaoProvider.future);
      key ??= await dao.getKeyFieldById(widget.apiKeyId);
    } catch (e) {
      Toaster.error(
        title: l10n.common_error_getting_field(Field: l10n.api_key_label),
        description: '$e',
      );
    }

    final customFields = await loadCustomShareableFields(ref, widget.apiKeyId);
    final fields = [
      ...compactShareableFields([
        shareableField(id: 'name', label: l10n.share_name_label, value: _name),
        shareableField(
          id: 'service',
          label: l10n.api_key_service_label,
          value: _service,
        ),
        shareableField(
          id: 'api_key',
          label: l10n.api_key_label,
          value: key ?? _maskedKey,
          isSensitive: true,
        ),
        shareableField(
          id: 'token_type',
          label: l10n.token_type_label,
          value: _tokenType,
        ),
        shareableField(
          id: 'environment',
          label: l10n.environment_label,
          value: _environment,
        ),
        shareableField(
          id: 'status',
          label: l10n.api_key_status_label,
          value: _revoked
              ? l10n.api_key_revoked_status
              : l10n.api_key_active_status,
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
        entityTypeLabel: EntityType.apiKey.label,
        fields: fields,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.dashboard_forms.view_api_key),
        actions: [
          IconButton(
            tooltip: context.t.dashboard_forms.share_action,
            onPressed: _loading || _isDeleted ? null : _share,
            icon: const Icon(Icons.share),
          ),
          IconButton(
            tooltip: context.t.dashboard_forms.edit,
            onPressed: _isDeleted
                ? null
                : () => context.push(
                    AppRoutesPaths.dashboardEntityEdit(
                      EntityType.apiKey,
                      widget.apiKeyId,
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
                  Text(
                    _service,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.t.dashboard_forms.api_key_label),
                    subtitle: Text(
                      _revealingKey
                          ? (_realKey ?? '')
                          : (_maskedKey ?? '••••••••'),
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          onPressed: _revealKey,
                          icon: Icon(
                            _revealingKey
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                        IconButton(
                          onPressed: _copyKey,
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  ),
                  if (_tokenType?.isNotEmpty == true)
                    ListTile(
                      title: Text(context.t.dashboard_forms.token_type_label),
                      subtitle: Text(_tokenType!),
                    ),
                  if (_environment?.isNotEmpty == true)
                    ListTile(
                      title: Text(context.t.dashboard_forms.environment_label),
                      subtitle: Text(_environment!),
                    ),
                  ListTile(
                    title: Text(context.t.dashboard_forms.api_key_status_label),
                    subtitle: Text(
                      _revoked
                          ? context.t.dashboard_forms.api_key_revoked_status
                          : context.t.dashboard_forms.api_key_active_status,
                    ),
                  ),
                  if (_description?.isNotEmpty == true)
                    ListTile(
                      title: Text(context.t.dashboard_forms.description_label),
                      subtitle: Text(_description!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  CustomFieldsViewSection(itemId: widget.apiKeyId),
                ],
              ),
      ),
    );
  }
}
