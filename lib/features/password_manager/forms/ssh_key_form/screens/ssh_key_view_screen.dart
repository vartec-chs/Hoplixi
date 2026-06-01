import 'package:hoplixi/shared/ui/background_utils.dart';
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
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/ssh_key/ssh_key_items.dart';

class SshKeyViewScreen extends ConsumerStatefulWidget {
  const SshKeyViewScreen({super.key, required this.sshKeyId});

  final String sshKeyId;

  @override
  ConsumerState<SshKeyViewScreen> createState() => _SshKeyViewScreenState();
}

class _SshKeyViewScreenState extends ConsumerState<SshKeyViewScreen> {
  bool _loading = true;
  bool _isDeleted = false;
  bool _showPrivateKey = false;

  String _name = '';
  String _publicKey = '';
  String? _privateKey;
  SshKeyType? _keyType;
  String? _keyTypeOther;
  int? _keySize;
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
      final viewResult = await repos.sshKey.getViewById(widget.sshKeyId);
      final view = viewResult.getOrNull()?.getOrNull();
      if (view == null) {
        if (mounted) {
          Toaster.error(title: context.t.dashboard_forms.ssh_key_not_found);
          context.pop();
        }
        return;
      }
      final item = view.item;
      final sshKey = view.sshKey;
      setState(() {
        _isDeleted = item.isDeleted;
        _name = item.name;
        _publicKey = sshKey.publicKey ?? '';
        _privateKey = sshKey.privateKey;
        _keyType = sshKey.keyType;
        _keyTypeOther = sshKey.keyTypeOther;
        _keySize = sshKey.keySize;
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

  Future<void> _togglePrivateKey() async {
    setState(() => _showPrivateKey = !_showPrivateKey);
  }

  Future<void> _copyPrivateKey() async {
    final value = _privateKey;
    if (value == null || value.isEmpty) {
      Toaster.warning(
        title: context.t.dashboard_forms.reveal_private_key_first,
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      Toaster.success(
        title: context.t.dashboard_forms.common_field_copied(
          Field: context.t.dashboard_forms.private_key_label,
        ),
      );
    }
  }

  Future<void> _share() async {
    final l10n = context.t.dashboard_forms;

    final customFields = await loadCustomShareableFields(ref, widget.sshKeyId);
    if (!mounted) return;

    final keyTypeLabel = _keyType?.name ?? _keyTypeOther;
    final fields = [
      ...compactShareableFields([
        shareableField(id: 'name', label: l10n.share_name_label, value: _name),
        shareableField(
          id: 'public_key',
          label: l10n.share_public_key_label,
          value: _publicKey,
        ),
        shareableField(
          id: 'private_key',
          label: l10n.private_key_label,
          value: _privateKey,
          isSensitive: true,
        ),
        shareableField(
          id: 'key_type',
          label: l10n.key_type_label,
          value: keyTypeLabel,
        ),
        if (_keySize != null)
          shareableField(
            id: 'key_size',
            label: l10n.key_size_label,
            value: '$_keySize',
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
        entityTypeLabel: EntityType.sshKey.label,
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
        title: Text(l10n.view_ssh_key),
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
                      EntityType.sshKey,
                      widget.sshKeyId,
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
                  if (_publicKey.isNotEmpty) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.share_public_key_label),
                      subtitle: SelectableText(_publicKey),
                    ),
                  ],
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.private_key_label),
                    subtitle: SelectableText(
                      _showPrivateKey
                          ? (_privateKey ?? l10n.common_not_set)
                          : l10n.common_press_visibility_to_load,
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          onPressed: _togglePrivateKey,
                          icon: Icon(
                            _showPrivateKey
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                        IconButton(
                          onPressed: _copyPrivateKey,
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  ),
                  if (_keyType != null)
                    ListTile(
                      title: Text(l10n.key_type_label),
                      subtitle: Text(_keyType!.name),
                    )
                  else if (_keyTypeOther?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.key_type_label),
                      subtitle: Text(_keyTypeOther!),
                    ),
                  if (_keySize != null)
                    ListTile(
                      title: Text(l10n.key_size_label),
                      subtitle: Text('$_keySize bits'),
                    ),
                  if (_description?.isNotEmpty == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.description_label),
                      subtitle: Text(_description!),
                    ),
                  CustomFieldsViewSection(itemId: widget.sshKeyId),
                ],
              ),
      ),
    );
  }
}
