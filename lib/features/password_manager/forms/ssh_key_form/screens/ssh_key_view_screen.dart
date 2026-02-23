import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/generated/l10n.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';

class SshKeyViewScreen extends ConsumerStatefulWidget {
  const SshKeyViewScreen({super.key, required this.sshKeyId});

  final String sshKeyId;

  @override
  ConsumerState<SshKeyViewScreen> createState() => _SshKeyViewScreenState();
}

class _SshKeyViewScreenState extends ConsumerState<SshKeyViewScreen> {
  bool _loading = true;
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
        Toaster.error(title: S.of(context).sshKeyNotFound);
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final ssh = row.$2;
      setState(() {
        _name = item.name;
        _publicKey = ssh.publicKey;
        _keyType = ssh.keyType;
        _fingerprint = ssh.fingerprint;
        _usage = ssh.usage;
        _description = item.description;
        _addedToAgent = ssh.addedToAgent;
      });
    } catch (e) {
      Toaster.error(title: S.of(context).commonLoadError, description: '$e');
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
          title: S.of(context).commonErrorGettingField(S.of(context).privateKeyLabel),
        );
        return;
      }
      setState(() {
        _privateKey = value;
        _showPrivateKey = true;
      });
    } catch (e) {
      Toaster.error(
        title: S.of(context).commonErrorGettingField(S.of(context).privateKeyLabel),
        description: '$e',
      );
    }
  }

  Future<void> _copyPrivateKey() async {
    final value = _privateKey;
    if (value == null || value.isEmpty) {
      Toaster.warning(title: S.of(context).revealPrivateKeyFirst);
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    Toaster.success(
      title: S.of(context).commonFieldCopied(S.of(context).privateKeyLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.viewSshKey),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            onPressed: () => context.push(
              AppRoutesPaths.dashboardEntityEdit(EntityType.sshKey, widget.sshKeyId),
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
                SelectableText(_publicKey),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.privateKeyLabel),
                  subtitle: SelectableText(
                    _showPrivateKey
                        ? (_privateKey ?? '')
                        : l10n.commonPressVisibilityToLoad,
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        onPressed: _revealPrivateKey,
                        icon: Icon(
                          _showPrivateKey ? Icons.visibility_off : Icons.visibility,
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
                  ListTile(title: Text(l10n.keyTypeLabel), subtitle: Text(_keyType!)),
                if (_fingerprint?.isNotEmpty == true)
                  ListTile(
                    title: Text(l10n.fingerprintLabel),
                    subtitle: Text(_fingerprint!),
                  ),
                if (_usage?.isNotEmpty == true)
                  ListTile(title: Text(l10n.usageLabel), subtitle: Text(_usage!)),
                ListTile(
                  title: Text(l10n.addedToSshAgentLabel),
                  subtitle: Text(
                    _addedToAgent ? l10n.commonAdded : l10n.commonNotAdded,
                  ),
                ),
                if (_description?.isNotEmpty == true)
                  ListTile(
                    title: Text(l10n.descriptionLabel),
                    subtitle: Text(_description!),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
    );
  }
}
