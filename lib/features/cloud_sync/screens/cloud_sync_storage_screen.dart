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
    final isImplemented = _isStorageImplemented(_selectedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Storage'),
        leading: BackButton(
          onPressed: () => {
            if (context.canPop())
              {context.pop()}
            else
              {context.go(AppRoutesPaths.cloudSync)},
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Обновить',
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
                currentFolder: _currentFolder,
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeToken == null) {
      return _CenteredMessage(
        icon: LucideIcons.shieldAlert,
        title: 'Нужна авторизация',
        description:
            'Для провайдера ${_selectedProvider.metadata.displayName} не найден активный токен. Выполните авторизацию и экран откроется.',
        actionLabel: _selectedProvider.metadata.supportsAuth
            ? 'Авторизоваться'
            : null,
        onAction: _selectedProvider.metadata.supportsAuth
            ? () => unawaited(_openAuthForSelectedProvider(forcePrompt: true))
            : null,
      );
    }

    if (!isImplemented) {
      return const _CenteredMessage(
        icon: LucideIcons.construction,
        title: 'Провайдер пока не реализован',
        description:
            'Авторизация и переключение уже доступны, но storage UI пока реализован только для Yandex.',
      );
    }

    if (_error != null) {
      return _CenteredMessage(
        icon: LucideIcons.circleAlert,
        title: 'Ошибка облака',
        description: _error!,
        actionLabel: 'Повторить',
        onAction: () => unawaited(_loadCurrentFolder()),
      );
    }

    if (_items.isEmpty) {
      return const _CenteredMessage(
        icon: LucideIcons.folderOpen,
        title: 'Папка пуста',
        description: 'В текущей директории пока нет ресурсов.',
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
    return <PopupMenuEntry<_StorageAction>>[
      if (resource.isFolder)
        const PopupMenuItem<_StorageAction>(
          value: _StorageAction.open,
          child: Text('Открыть'),
        ),
      if (resource.isFile)
        const PopupMenuItem<_StorageAction>(
          value: _StorageAction.download,
          child: Text('Скачать'),
        ),
      const PopupMenuItem<_StorageAction>(
        value: _StorageAction.copy,
        child: Text('Копировать как...'),
      ),
      const PopupMenuItem<_StorageAction>(
        value: _StorageAction.move,
        child: Text('Переместить/переименовать'),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem<_StorageAction>(
        value: _StorageAction.delete,
        child: Text('Удалить'),
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
        ref: ref,
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

    final name = await _showTextInputDialog(
      title: 'Новая папка',
      label: 'Имя папки',
      submitLabel: 'Создать',
    );
    if (name == null || name.trim().isEmpty) {
      return;
    }

    try {
      await ref
          .read(cloudStorageRepositoryProvider)
          .createFolder(token.id, parentRef: _currentFolder, name: name.trim());
      await _loadCurrentFolder();
      _showSnackBar('Папка создана');
    } catch (error) {
      _showSnackBar(_formatStorageError(error));
    }
  }

  Future<void> _uploadFile() async {
    final token = _activeToken;
    if (token == null) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
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
      _showSnackBar('Не удалось прочитать выбранный файл');
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
      _showSnackBar('Файл загружен');
    } catch (error) {
      _showSnackBar(_formatStorageError(error));
    }
  }

  Future<void> _downloadResource(CloudResource resource) async {
    final token = _activeToken;
    if (token == null || !resource.isFile) {
      return;
    }

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить файл',
      fileName: resource.name,
    );
    if (path == null || path.trim().isEmpty) {
      return;
    }

    try {
      await ref
          .read(cloudStorageRepositoryProvider)
          .downloadFile(token.id, fileRef: resource.ref, savePath: path);
      _showSnackBar('Файл сохранён');
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

    final actionLabel = isMove ? 'Переместить' : 'Копировать';
    final targetName = await _showTextInputDialog(
      title: '$actionLabel ресурс',
      label: 'Новое имя',
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
      _showSnackBar(isMove ? 'Ресурс перемещён' : 'Ресурс скопирован');
    } catch (error) {
      _showSnackBar(_formatStorageError(error));
    }
  }

  Future<void> _deleteResource(CloudResource resource) async {
    final token = _activeToken;
    if (token == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление ресурса'),
        content: Text(
          'Удалить "${resource.name}" без возможности восстановления?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
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
      _showSnackBar('Ресурс удалён');
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
            child: const Text('Отмена'),
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
    return provider == CloudSyncProvider.yandex
        ? const CloudResourceRef.root(
            provider: CloudSyncProvider.yandex,
            path: 'disk:/',
          )
        : CloudResourceRef.root(provider: provider);
  }

  bool _isStorageImplemented(CloudSyncProvider provider) {
    return provider == CloudSyncProvider.yandex;
  }

  bool _canGoUp(CloudResourceRef ref) {
    return _parentRefFor(ref) != null;
  }

  CloudResourceRef? _parentRefFor(CloudResourceRef ref) {
    if (ref.isRoot) {
      return null;
    }

    if (ref.provider != CloudSyncProvider.yandex) {
      return null;
    }

    final path = ref.path?.trim();
    if (path == null || path.isEmpty || path == 'disk:/') {
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

  String _storageRouteFor(CloudSyncProvider provider) {
    return '${AppRoutesPaths.cloudSyncStorage}?provider=${provider.id}';
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
    return details.where((value) => value.trim().isNotEmpty).join(' • ');
  }

  String _formatStorageError(Object error) {
    if (error is TimeoutException) {
      return 'Загрузка облачной папки превысила таймаут. Проверьте токен, сеть или ответ API провайдера.';
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
    this.onAuthorize,
  });

  final CloudSyncProvider provider;
  final AuthTokenEntry? token;
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
                        ? 'Токен не найден'
                        : 'Аккаунт: ${token!.displayLabel}',
                  ),
                ],
              ),
            ),
            if (token == null && onAuthorize != null)
              FilledButton(onPressed: onAuthorize, child: const Text('Войти')),
          ],
        ),
      ),
    );
  }
}

class _StorageToolbar extends StatelessWidget {
  const _StorageToolbar({
    required this.currentFolder,
    this.onGoUp,
    this.onCreateFolder,
    this.onUpload,
  });

  final CloudResourceRef currentFolder;
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
              'Текущая папка: ${currentFolder.path ?? '/'}',
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
                    label: const Text('Вверх'),
                  ),
                FilledButton.icon(
                  onPressed: onCreateFolder,
                  icon: const Icon(LucideIcons.folderPlus),
                  label: const Text('Папка'),
                ),
                FilledButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(LucideIcons.upload),
                  label: const Text('Загрузить'),
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
