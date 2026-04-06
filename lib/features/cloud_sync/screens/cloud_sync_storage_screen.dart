import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/cloud_sync/auth/widgets/show_cloud_sync_auth_sheet.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_move_copy_target.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_ref.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/features/cloud_sync/storage/providers/cloud_storage_provider.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CloudSyncStorageScreen extends ConsumerStatefulWidget {
  const CloudSyncStorageScreen({super.key, this.initialProvider});

  final CloudSyncProvider? initialProvider;

  @override
  ConsumerState<CloudSyncStorageScreen> createState() =>
      _CloudSyncStorageScreenState();
}

class _CloudSyncStorageScreenState
    extends ConsumerState<CloudSyncStorageScreen> {
  static const String _logTag = 'CloudSyncStorageScreen';
  static const Duration _initialLoadTimeout = Duration(seconds: 20);
  static const List<CloudSyncProvider> _providers = <CloudSyncProvider>[
    CloudSyncProvider.yandex,
    CloudSyncProvider.dropbox,
    CloudSyncProvider.google,
    CloudSyncProvider.onedrive,
  ];

  late CloudSyncProvider _selectedProvider;
  late CloudResourceRef _currentFolder;
  AuthTokenEntry? _activeToken;
  List<CloudResource> _items = const <CloudResource>[];
  bool _isLoading = false;
  bool _isPromptingAuth = false;
  String? _error;
  final Set<CloudSyncProvider> _authPromptedProviders = <CloudSyncProvider>{};

  @override
  void initState() {
    super.initState();
    _selectedProvider = widget.initialProvider ?? CloudSyncProvider.yandex;
    _currentFolder = _rootRefForProvider(_selectedProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_ensureProviderAccessAndLoad());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.cloud_sync_storage;
    final isImplemented = _isStorageImplemented(_selectedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screen_title),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutesPaths.cloudSync);
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: l10n.refresh_tooltip,
            onPressed: _isLoading
                ? null
                : () => unawaited(_loadCurrentFolder()),
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _ProviderSelector(
              providers: _providers,
              selectedProvider: _selectedProvider,
              onSelected: (provider) => unawaited(_selectProvider(provider)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _TokenInfoCard(
              provider: _selectedProvider,
              token: _activeToken,
              missingTokenLabel: l10n.token_not_found,
              accountLabelBuilder: (account) =>
                  l10n.account_label(Account: account),
              signInLabel: l10n.sign_in_button,
              onAuthorize: _selectedProvider.metadata.supportsAuth
                  ? () => unawaited(_openAuthForSelectedProvider())
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          if (_activeToken != null && isImplemented)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StorageToolbar(
                currentFolderPath: _displayCurrentFolderPath(_currentFolder),
                currentFolderLabelBuilder: (path) =>
                    l10n.current_folder_label(Path: path),
                goUpLabel: l10n.go_up_button,
                createFolderLabel: l10n.create_folder_button,
                uploadLabel: l10n.upload_button,
                onGoUp: _canGoUp(_currentFolder)
                    ? () => unawaited(_goUp())
                    : null,
                onCreateFolder: () => unawaited(_createFolder()),
                onUpload: () => unawaited(_uploadFile()),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildBody(context: context, isImplemented: isImplemented),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required bool isImplemented,
  }) {
    final l10n = context.t.cloud_sync_storage;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeToken == null) {
      return _CenteredMessage(
        icon: LucideIcons.shieldAlert,
        title: l10n.auth_required_title,
        description: l10n.auth_required_description(
          Provider: _selectedProvider.metadata.displayName,
        ),
        actionLabel: _selectedProvider.metadata.supportsAuth
            ? l10n.authorize_button
            : null,
        onAction: _selectedProvider.metadata.supportsAuth
            ? () => unawaited(_openAuthForSelectedProvider(forcePrompt: true))
            : null,
      );
    }

    if (!isImplemented) {
      return _CenteredMessage(
        icon: LucideIcons.construction,
        title: l10n.provider_not_implemented_title,
        description: l10n.provider_not_implemented_description(
          Provider: _selectedProvider.metadata.displayName,
        ),
      );
    }

    if (_error != null) {
      return _CenteredMessage(
        icon: LucideIcons.circleAlert,
        title: l10n.cloud_error_title,
        description: _error!,
        actionLabel: l10n.retry_button,
        onAction: () => unawaited(_loadCurrentFolder()),
      );
    }

    if (_items.isEmpty) {
      return _CenteredMessage(
        icon: LucideIcons.folderOpen,
        title: l10n.empty_folder_title,
        description: l10n.empty_folder_description,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCurrentFolder,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final resource = _items[index];
          return Card(
            child: ListTile(
              onTap: resource.isFolder
                  ? () => unawaited(_openFolder(resource))
                  : () => unawaited(_downloadResource(resource)),
              leading: Icon(
                resource.isFolder ? LucideIcons.folder : LucideIcons.file,
              ),
              title: Text(resource.name),
              subtitle: Text(_resourceSubtitle(resource)),
              trailing: PopupMenuButton<_StorageAction>(
                onSelected: (action) =>
                    unawaited(_handleResourceAction(action, resource)),
                itemBuilder: (context) => _buildResourceMenu(resource),
              ),
            ),
          );
        },
      ),
    );
  }

  List<PopupMenuEntry<_StorageAction>> _buildResourceMenu(
    CloudResource resource,
  ) {
    final l10n = context.t.cloud_sync_storage;

    return <PopupMenuEntry<_StorageAction>>[
      if (resource.isFolder)
        PopupMenuItem<_StorageAction>(
          value: _StorageAction.open,
          child: Text(l10n.action_open),
        ),
      if (resource.isFile)
        PopupMenuItem<_StorageAction>(
          value: _StorageAction.download,
          child: Text(l10n.action_download),
        ),
      PopupMenuItem<_StorageAction>(
        value: _StorageAction.copy,
        child: Text(l10n.action_copy_as),
      ),
      PopupMenuItem<_StorageAction>(
        value: _StorageAction.move,
        child: Text(l10n.action_move_rename),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<_StorageAction>(
        value: _StorageAction.delete,
        child: Text(l10n.action_delete),
      ),
    ];
  }

  Future<void> _selectProvider(CloudSyncProvider provider) async {
    if (provider == _selectedProvider) {
      return;
    }

    setState(() {
      _selectedProvider = provider;
      _currentFolder = _rootRefForProvider(provider);
      _activeToken = null;
      _items = const <CloudResource>[];
      _error = null;
      _isLoading = false;
    });

    await _ensureProviderAccessAndLoad();
  }

  Future<void> _ensureProviderAccessAndLoad({bool forcePrompt = false}) async {
    logInfo(
      'Ensuring storage access for provider ${_selectedProvider.id}',
      tag: _logTag,
      data: {'provider': _selectedProvider.id, 'forcePrompt': forcePrompt},
    );
    final tokens = await _loadTokensForProvider(_selectedProvider);
    if (!mounted) {
      return;
    }

    final activeToken = tokens.isNotEmpty ? tokens.first : null;
    setState(() {
      _activeToken = activeToken;
      if (activeToken == null) {
        _items = const <CloudResource>[];
        _error = null;
      }
    });

    logInfo(
      'Resolved storage token for provider ${_selectedProvider.id}',
      tag: _logTag,
      data: {
        'provider': _selectedProvider.id,
        'tokenFound': activeToken != null,
        'tokenId': activeToken?.id,
      },
    );

    if (activeToken == null &&
        _selectedProvider.metadata.supportsAuth &&
        (forcePrompt || !_authPromptedProviders.contains(_selectedProvider))) {
      await _openAuthForSelectedProvider(forcePrompt: forcePrompt);
      return;
    }

    if (activeToken != null && _isStorageImplemented(_selectedProvider)) {
      await _loadCurrentFolder();
    }
  }

  Future<void> _openAuthForSelectedProvider({bool forcePrompt = false}) async {
    if (_isPromptingAuth) {
      return;
    }

    if (!forcePrompt) {
      _authPromptedProviders.add(_selectedProvider);
    }

    _isPromptingAuth = true;
    try {
      await showCloudSyncAuthSheet(
        context: context,
        container: ProviderScope.containerOf(context, listen: false),
        previousRoute: _storageRouteFor(_selectedProvider),
        initialProvider: _selectedProvider,
      );
      await ref.read(authTokensProvider.notifier).reload();
      await _ensureProviderAccessAndLoad(forcePrompt: false);
    } finally {
      _isPromptingAuth = false;
    }
  }

  Future<void> _loadCurrentFolder() async {
    final token = _activeToken;
    if (token == null || !_isStorageImplemented(_selectedProvider)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      logInfo(
        'Loading cloud folder',
        tag: _logTag,
        data: {
          'provider': _selectedProvider.id,
          'tokenId': token.id,
          'path': _currentFolder.path,
          'resourceId': _currentFolder.resourceId,
          'isRoot': _currentFolder.isRoot,
        },
      );

      final page = await ref
          .read(cloudStorageRepositoryProvider)
          .listFolder(token.id, _currentFolder, pageSize: 100)
          .timeout(_initialLoadTimeout);

      if (!mounted) {
        return;
      }

      logInfo(
        'Cloud folder loaded',
        tag: _logTag,
        data: {
          'provider': _selectedProvider.id,
          'tokenId': token.id,
          'path': _currentFolder.path,
          'itemsCount': page.items.length,
        },
      );

      setState(() {
        _items = page.items;
      });
    } catch (error) {
      logWarning(
        'Cloud folder load failed: $error',
        tag: _logTag,
        data: {
          'provider': _selectedProvider.id,
          'tokenId': token.id,
          'path': _currentFolder.path,
          'resourceId': _currentFolder.resourceId,
          'isRoot': _currentFolder.isRoot,
          'errorType': error.runtimeType.toString(),
        },
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _formatStorageError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openFolder(CloudResource resource) async {
    setState(() {
      _currentFolder = resource.ref;
    });
    await _loadCurrentFolder();
  }

  Future<void> _goUp() async {
    final parentRef = _parentRefFor(_currentFolder);
    if (parentRef == null) {
      return;
    }
    setState(() {
      _currentFolder = parentRef;
    });
    await _loadCurrentFolder();
  }

  Future<void> _createFolder() async {
    final token = _activeToken;
    if (token == null) {
      return;
    }

    final l10n = context.t.cloud_sync_storage;
    final name = await _showTextInputDialog(
      title: l10n.new_folder_title,
      label: l10n.folder_name_label,
      submitLabel: l10n.create_button,
    );
    if (name == null || name.trim().isEmpty) {
      return;
    }

    try {
      await ref
          .read(cloudStorageRepositoryProvider)
          .createFolder(token.id, parentRef: _currentFolder, name: name.trim());
      await _loadCurrentFolder();
      _showSnackBar(l10n.folder_created);
    } catch (error) {
      _showSnackBar(_formatStorageError(error));
    }
  }

  Future<void> _uploadFile() async {
    final token = _activeToken;
    if (token == null) {
      return;
    }

    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      withReadStream: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final picked = result.files.single;
    final stream =
        picked.readStream ??
        (picked.path != null ? File(picked.path!).openRead() : null);
    if (stream == null || picked.size <= 0) {
      _showSnackBar(context.t.cloud_sync_storage.read_file_failed);
      return;
    }

    try {
      await ref
          .read(cloudStorageRepositoryProvider)
          .uploadFile(
            token.id,
            parentRef: _currentFolder,
            name: picked.name,
            dataStream: stream,
            contentLength: picked.size,
          );
      await _loadCurrentFolder();
      _showSnackBar(context.t.cloud_sync_storage.file_uploaded);
    } catch (error) {
      _showSnackBar(_formatStorageError(error));
    }
  }

  Future<void> _downloadResource(CloudResource resource) async {
    final token = _activeToken;
    if (token == null || !resource.isFile) {
      return;
    }

    final l10n = context.t.cloud_sync_storage;
    final path = await FilePicker.saveFile(
      dialogTitle: l10n.save_file_dialog_title,
      fileName: resource.name,
    );
    if (path == null || path.trim().isEmpty) {
      return;
    }

    try {
      await ref
          .read(cloudStorageRepositoryProvider)
          .downloadFile(token.id, fileRef: resource.ref, savePath: path);
      _showSnackBar(l10n.file_saved);
    } catch (error) {
      _showSnackBar(_formatStorageError(error));
    }
  }

  Future<void> _handleResourceAction(
    _StorageAction action,
    CloudResource resource,
  ) async {
    switch (action) {
      case _StorageAction.open:
        await _openFolder(resource);
        break;
      case _StorageAction.download:
        await _downloadResource(resource);
        break;
      case _StorageAction.copy:
        await _copyOrMoveResource(resource, isMove: false);
        break;
      case _StorageAction.move:
        await _copyOrMoveResource(resource, isMove: true);
        break;
      case _StorageAction.delete:
        await _deleteResource(resource);
        break;
    }
  }

  Future<void> _copyOrMoveResource(
    CloudResource resource, {
    required bool isMove,
  }) async {
    final token = _activeToken;
    if (token == null) {
      return;
    }

    final l10n = context.t.cloud_sync_storage;
    final actionLabel = isMove ? l10n.move_button : l10n.copy_button;
    final targetName = await _showTextInputDialog(
      title: l10n.rename_dialog_title(Action: actionLabel),
      label: l10n.new_name_label,
      initialValue: resource.name,
      submitLabel: actionLabel,
    );
    if (targetName == null || targetName.trim().isEmpty) {
      return;
    }

    final target = CloudMoveCopyTarget(
      parentRef: _currentFolder,
      name: targetName.trim(),
    );

    try {
      if (isMove) {
        await ref
            .read(cloudStorageRepositoryProvider)
            .moveResource(token.id, sourceRef: resource.ref, target: target);
      } else {
        await ref
            .read(cloudStorageRepositoryProvider)
            .copyResource(token.id, sourceRef: resource.ref, target: target);
      }
      await _loadCurrentFolder();
      _showSnackBar(isMove ? l10n.resource_moved : l10n.resource_copied);
    } catch (error) {
      _showSnackBar(_formatStorageError(error));
    }
  }

  Future<void> _deleteResource(CloudResource resource) async {
    final token = _activeToken;
    if (token == null) {
      return;
    }

    final l10n = context.t.cloud_sync_storage;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete_dialog_title),
        content: Text(
          l10n.delete_dialog_description(ResourceName: resource.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel_button),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.action_delete),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(cloudStorageRepositoryProvider)
          .deleteResource(token.id, resource.ref);
      await _loadCurrentFolder();
      _showSnackBar(l10n.resource_deleted);
    } catch (error) {
      _showSnackBar(_formatStorageError(error));
    }
  }

  Future<String?> _showTextInputDialog({
    required String title,
    required String label,
    required String submitLabel,
    String? initialValue,
  }) async {
    final l10n = context.t.cloud_sync_storage;
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel_button),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(submitLabel),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  Future<List<AuthTokenEntry>> _loadTokensForProvider(
    CloudSyncProvider provider,
  ) async {
    final service = ref.read(authTokensServiceProvider);
    await service.initialize();
    return service.getTokensByProvider(provider);
  }

  CloudResourceRef _rootRefForProvider(CloudSyncProvider provider) {
    return switch (provider) {
      CloudSyncProvider.yandex => const CloudResourceRef.root(
        provider: CloudSyncProvider.yandex,
        path: 'disk:/',
      ),
      CloudSyncProvider.dropbox => const CloudResourceRef.root(
        provider: CloudSyncProvider.dropbox,
        path: '',
      ),
      CloudSyncProvider.google => const CloudResourceRef.root(
        provider: CloudSyncProvider.google,
        resourceId: 'root',
        path: '',
      ),
      CloudSyncProvider.onedrive => const CloudResourceRef.root(
        provider: CloudSyncProvider.onedrive,
        resourceId: 'root',
        path: '',
      ),
      _ => CloudResourceRef.root(provider: provider),
    };
  }

  bool _isStorageImplemented(CloudSyncProvider provider) {
    return provider == CloudSyncProvider.yandex ||
        provider == CloudSyncProvider.dropbox ||
        provider == CloudSyncProvider.google ||
        provider == CloudSyncProvider.onedrive;
  }

  bool _canGoUp(CloudResourceRef ref) {
    return _parentRefFor(ref) != null;
  }

  CloudResourceRef? _parentRefFor(CloudResourceRef ref) {
    if (ref.isRoot) {
      return null;
    }

    final path = ref.path?.trim();
    if (path == null) {
      return null;
    }

    if (ref.provider == CloudSyncProvider.yandex) {
      if (path.isEmpty || path == 'disk:/') {
        return null;
      }

      final normalized = path.replaceFirst(RegExp(r'/+$'), '');
      final lastSlash = normalized.lastIndexOf('/');
      if (lastSlash <= 'disk:'.length) {
        return _rootRefForProvider(ref.provider);
      }

      return CloudResourceRef(
        provider: ref.provider,
        path: normalized.substring(0, lastSlash),
      );
    }

    if (path.isEmpty || path == '/') {
      return null;
    }

    final normalized = path.replaceFirst(RegExp(r'/+$'), '');
    final lastSlash = normalized.lastIndexOf('/');
    if (lastSlash <= 0) {
      return _rootRefForProvider(ref.provider);
    }

    return CloudResourceRef(
      provider: ref.provider,
      path: normalized.substring(0, lastSlash),
    );
  }

  String _storageRouteFor(CloudSyncProvider provider) {
    return '${AppRoutesPaths.cloudSyncStorage}?provider=${provider.id}';
  }

  String _displayCurrentFolderPath(CloudResourceRef ref) {
    if (ref.isRoot) {
      return '/';
    }

    final path = ref.path;
    if (path == null || path.isEmpty) {
      return '/';
    }

    return path;
  }

  String _resourceSubtitle(CloudResource resource) {
    final details = <String>[
      resource.ref.path ?? resource.ref.resourceId ?? '',
    ];
    final size = resource.metadata.sizeBytes;
    if (size != null && size > 0) {
      details.add('$size B');
    }
    final modified = resource.metadata.modifiedAt;
    if (modified != null) {
      details.add(modified.toString());
    }
    return details.where((value) => value.trim().isNotEmpty).join(' | ');
  }

  String _formatStorageError(Object error) {
    if (error is TimeoutException) {
      return context.t.cloud_sync_storage.timeout_error;
    }
    if (error is CloudStorageException) {
      return error.message;
    }
    return error.toString();
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _StorageAction { open, download, copy, move, delete }

class _ProviderSelector extends StatelessWidget {
  const _ProviderSelector({
    required this.providers,
    required this.selectedProvider,
    required this.onSelected,
  });

  final List<CloudSyncProvider> providers;
  final CloudSyncProvider selectedProvider;
  final ValueChanged<CloudSyncProvider> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 8,
        children: providers
            .map(
              (provider) => ChoiceChip(
                label: Text(provider.metadata.displayName),
                selected: provider == selectedProvider,
                onSelected: (_) => onSelected(provider),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _TokenInfoCard extends StatelessWidget {
  const _TokenInfoCard({
    required this.provider,
    required this.token,
    required this.missingTokenLabel,
    required this.accountLabelBuilder,
    required this.signInLabel,
    this.onAuthorize,
  });

  final CloudSyncProvider provider;
  final AuthTokenEntry? token;
  final String missingTokenLabel;
  final String Function(String account) accountLabelBuilder;
  final String signInLabel;
  final VoidCallback? onAuthorize;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(provider.metadata.icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.metadata.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    token == null
                        ? missingTokenLabel
                        : accountLabelBuilder(token!.displayLabel),
                  ),
                ],
              ),
            ),
            if (token == null && onAuthorize != null)
              FilledButton(onPressed: onAuthorize, child: Text(signInLabel)),
          ],
        ),
      ),
    );
  }
}

class _StorageToolbar extends StatelessWidget {
  const _StorageToolbar({
    required this.currentFolderPath,
    required this.currentFolderLabelBuilder,
    required this.goUpLabel,
    required this.createFolderLabel,
    required this.uploadLabel,
    this.onGoUp,
    this.onCreateFolder,
    this.onUpload,
  });

  final String currentFolderPath;
  final String Function(String path) currentFolderLabelBuilder;
  final String goUpLabel;
  final String createFolderLabel;
  final String uploadLabel;
  final VoidCallback? onGoUp;
  final VoidCallback? onCreateFolder;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentFolderLabelBuilder(currentFolderPath),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onGoUp != null)
                  OutlinedButton.icon(
                    onPressed: onGoUp,
                    icon: const Icon(LucideIcons.arrowUp),
                    label: Text(goUpLabel),
                  ),
                FilledButton.icon(
                  onPressed: onCreateFolder,
                  icon: const Icon(LucideIcons.folderPlus),
                  label: Text(createFolderLabel),
                ),
                FilledButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(LucideIcons.upload),
                  label: Text(uploadLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
