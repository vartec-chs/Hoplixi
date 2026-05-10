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
  String? _privateKey;

  String _name = '';
  String _publicKey = '';
  String? _keyType;
  String? _fingerprint;
  String? _usage;
  String? _description;
  bool _addedToAgent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(sshKeyDaoProvider.future);
      final row = await dao.getById(widget.sshKeyId);
      if (row == null) {
        Toaster.error(title: context.t.dashboard_forms.ssh_key_not_found);
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final ssh = row.$2;
      setState(() {
        _isDeleted = item.isDeleted;
        _name = item.name;
        _publicKey = ssh.publicKey;
        _keyType = ssh.keyType;
        _fingerprint = ssh.fingerprint;
        _usage = ssh.usage;
        _description = item.description;
        _addedToAgent = ssh.addedToAgent;
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

  Future<void> _revealPrivateKey() async {
    if (_privateKey != null) {
      setState(() => _showPrivateKey = !_showPrivateKey);
      return;
    }

    try {
      final dao = await ref.read(sshKeyDaoProvider.future);
      final value = await dao.getPrivateKeyFieldById(widget.sshKeyId);
      if (value == null) {
        Toaster.error(
          title: context.t.dashboard_forms.common_error_getting_field(
            Field: context.t.dashboard_forms.private_key_label,
          ),
        );
        return;
      }
      setState(() {
        _privateKey = value;
        _showPrivateKey = true;
      });
    } catch (e) {
      Toaster.error(
        title: context.t.dashboard_forms.common_error_getting_field(
          Field: context.t.dashboard_forms.private_key_label,
        ),
        description: '$e',
      );
    }
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
    Toaster.success(
      title: context.t.dashboard_forms.common_field_copied(
        Field: context.t.dashboard_forms.private_key_label,
      ),
    );
  }

  Future<void> _share() async {
    final l10n = context.t.dashboard_forms;
    String? privateKey = _privateKey;
    try {
      final dao = await ref.read(sshKeyDaoProvider.future);
      privateKey ??= await dao.getPrivateKeyFieldById(widget.sshKeyId);
    } catch (e) {
      Toaster.error(
        title: l10n.common_error_getting_field(Field: l10n.private_key_label),
        description: '$e',
      );
    }

    final customFields = await loadCustomShareableFields(ref, widget.sshKeyId);
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
          value: privateKey,
          isSensitive: true,
        ),
        shareableField(
          id: 'key_type',
          label: l10n.key_type_label,
          value: _keyType,
        ),
        shareableField(
          id: 'fingerprint',
          label: l10n.fingerprint_label,
          value: _fingerprint,
        ),
        shareableField(id: 'usage', label: l10n.usage_label, value: _usage),
        shareableField(
          id: 'added_to_agent',
          label: l10n.added_to_ssh_agent_label,
          value: _addedToAgent ? l10n.common_added : l10n.common_not_added,
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
                  SelectableText(_publicKey),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.private_key_label),
                    subtitle: SelectableText(
                      _showPrivateKey
                          ? (_privateKey ?? '')
                          : l10n.common_press_visibility_to_load,
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          onPressed: _revealPrivateKey,
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
                  if (_keyType?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.key_type_label),
                      subtitle: Text(_keyType!),
                    ),
                  if (_fingerprint?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.fingerprint_label),
                      subtitle: Text(_fingerprint!),
                    ),
                  if (_usage?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.usage_label),
                      subtitle: Text(_usage!),
                    ),
                  ListTile(
                    title: Text(l10n.added_to_ssh_agent_label),
                    subtitle: Text(
                      _addedToAgent ? l10n.common_added : l10n.common_not_added,
                    ),
                  ),
                  if (_description?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.description_label),
                      subtitle: Text(_description!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  CustomFieldsViewSection(itemId: widget.sshKeyId),
                ],
              ),
      ),
    );
  }
}
