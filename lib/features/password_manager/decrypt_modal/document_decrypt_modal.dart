import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/document_dto.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/main_store/provider/decrypted_files_guard_provider.dart';
import 'package:hoplixi/main_store/provider/service_providers.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';
import 'package:hoplixi/shared/ui/slider_button.dart';
import 'package:open_file/open_file.dart';
import 'package:watcher/watcher.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

const String _logTag = 'DocumentDecryptModal';

/// Показать модальное окно расшифровки документа
void showDocumentDecryptModal(BuildContext context, DocumentCardDto document) {
  final pageIndexNotifier = ValueNotifier<int>(0);
  final selectedPagesNotifier = ValueNotifier<Set<String>>({});

  WoltModalSheet.show(
    context: context,
    useRootNavigator: true,
    pageIndexNotifier: pageIndexNotifier,
    pageListBuilder: (modalContext) {
      return [
        // Страница 1: Список страниц документа
        _DocumentDecryptModalPages.buildPagesListPage(
          modalContext,
          document,
          pageIndexNotifier,
          selectedPagesNotifier,
        ),
        // Страница 2: Расшифровка выбранных страниц
        _DocumentDecryptModalPages.buildDecryptPage(
          modalContext,
          document,
          pageIndexNotifier,
          selectedPagesNotifier,
        ),
      ];
    },
  );
}

/// Вспомогательный класс для построения страниц модального окна
class _DocumentDecryptModalPages {
  _DocumentDecryptModalPages._();

  /// Построение первой страницы - список страниц документа
  static SliverWoltModalSheetPage buildPagesListPage(
    BuildContext context,
    DocumentCardDto document,
    ValueNotifier<int> pageIndexNotifier,
    ValueNotifier<Set<String>> selectedPagesNotifier,
  ) {
    return SliverWoltModalSheetPage(
      hasSabGradient: false,
      topBarTitle: Text(
        document.title ?? 'Документ',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      isTopBarLayerAlwaysVisible: true,
      trailingNavBarWidget: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      mainContentSliversBuilder: (context) => [
        SliverToBoxAdapter(
          child: _DocumentPagesListContent(
            document: document,
            pageIndexNotifier: pageIndexNotifier,
            selectedPagesNotifier: selectedPagesNotifier,
          ),
        ),
      ],
    );
  }

  /// Построение второй страницы - расшифровка
  static SliverWoltModalSheetPage buildDecryptPage(
    BuildContext context,
    DocumentCardDto document,
    ValueNotifier<int> pageIndexNotifier,
    ValueNotifier<Set<String>> selectedPagesNotifier,
  ) {
    return SliverWoltModalSheetPage(
      hasSabGradient: false,
      topBarTitle: Text(
        'Расшифровка страниц',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      isTopBarLayerAlwaysVisible: true,
      leadingNavBarWidget: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => pageIndexNotifier.value = 0,
        ),
      ),
      trailingNavBarWidget: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      mainContentSliversBuilder: (context) => [
        SliverToBoxAdapter(
          child: _DocumentDecryptContent(
            document: document,
            pageIndexNotifier: pageIndexNotifier,
            selectedPagesNotifier: selectedPagesNotifier,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Модель данных страницы документа с информацией о файле
// ─────────────────────────────────────────────────────────────────────────────

/// Информация о странице документа для отображения
class DocumentPageDisplayInfo {
  final String pageId;
  final String fileId;
  final int pageNumber;
  final bool isPrimary;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final String? extractedText;

  const DocumentPageDisplayInfo({
    required this.pageId,
    required this.fileId,
    required this.pageNumber,
    required this.isPrimary,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.extractedText,
  });

  String get displayName => fileName ?? 'Страница $pageNumber';

  String get fileSizeFormatted {
    if (fileSize == null) return 'Неизвестный размер';
    final kb = fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} КБ';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} МБ';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Контент первой страницы - список страниц документа
// ─────────────────────────────────────────────────────────────────────────────

class _DocumentPagesListContent extends ConsumerStatefulWidget {
  final DocumentCardDto document;
  final ValueNotifier<int> pageIndexNotifier;
  final ValueNotifier<Set<String>> selectedPagesNotifier;

  const _DocumentPagesListContent({
    required this.document,
    required this.pageIndexNotifier,
    required this.selectedPagesNotifier,
  });

  @override
  ConsumerState<_DocumentPagesListContent> createState() =>
      _DocumentPagesListContentState();
}

class _DocumentPagesListContentState
    extends ConsumerState<_DocumentPagesListContent> {
  final List<DocumentPageDisplayInfo> _loadedPages = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  static const int _pageSize = 10;
  int _currentOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMorePages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePages();
    }
  }

  Future<void> _loadMorePages() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final documentService = await ref.read(
        documentStorageServiceProvider.future,
      );
      final fileDao = await ref.read(fileDaoProvider.future);

      // Получаем все страницы документа
      final allPages = await documentService.getDocumentPages(
        widget.document.id,
      );

      // Пагинация в памяти
      final endIndex = (_currentOffset + _pageSize).clamp(0, allPages.length);
      final pageSlice = allPages.sublist(_currentOffset, endIndex);

      final newPages = <DocumentPageDisplayInfo>[];

      for (final page in pageSlice) {
        String? fileName;
        int? fileSize;
        String? mimeType;

        // Получаем метаданные файла
        if (page.metadataId != null) {
          final metadata = await (fileDao.attachedDatabase.select(
            fileDao.attachedDatabase.fileMetadata,
          )..where((m) => m.id.equals(page.metadataId!))).getSingleOrNull();

          if (metadata != null) {
            fileName = metadata.fileName;
            fileSize = metadata.fileSize;
            mimeType = metadata.mimeType;
          }
        }

        newPages.add(
          DocumentPageDisplayInfo(
            pageId: page.id,
            fileId: page.metadataId!,
            pageNumber: page.pageNumber,
            isPrimary: page.isPrimary,
            fileName: fileName,
            fileSize: fileSize,
            mimeType: mimeType,
            extractedText: page.extractedText,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _loadedPages.addAll(newPages);
          _currentOffset = endIndex;
          _hasMore = endIndex < allPages.length;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      logError(
        'Failed to load document pages',
        error: e,
        stackTrace: st,
        tag: _logTag,
      );
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _togglePageSelection(String pageId) {
    final current = Set<String>.from(widget.selectedPagesNotifier.value);
    if (current.contains(pageId)) {
      current.remove(pageId);
    } else {
      current.add(pageId);
    }
    widget.selectedPagesNotifier.value = current;
    setState(() {});
  }

  void _selectAll() {
    widget.selectedPagesNotifier.value = _loadedPages
        .map((p) => p.pageId)
        .toSet();
    setState(() {});
  }

  void _deselectAll() {
    widget.selectedPagesNotifier.value = {};
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedPages = widget.selectedPagesNotifier.value;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Информация о документе
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.document.title ?? 'Без названия',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.document.pageCount} ${_getPageWord(widget.document.pageCount)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Кнопки выбора
          Row(
            children: [
              Text(
                'Выбрано: ${selectedPages.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _selectAll,
                child: const Text('Выбрать все'),
              ),
              TextButton(
                onPressed: _deselectAll,
                child: const Text('Сбросить'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Ошибка
          if (_error != null) ...[
            NotificationCard(
              type: NotificationType.error,
              text: _error!,
              onDismiss: () => setState(() => _error = null),
            ),
            const SizedBox(height: 8),
          ],

          // Список страниц
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              itemCount: _loadedPages.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _loadedPages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final page = _loadedPages[index];
                final isSelected = selectedPages.contains(page.pageId);

                return _PageListItem(
                  page: page,
                  isSelected: isSelected,
                  onTap: () => _togglePageSelection(page.pageId),
                );
              },
            ),
          ),

          if (_loadedPages.isEmpty && !_isLoading) ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Нет страниц в документе',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Кнопка перехода к расшифровке
          SizedBox(
            width: double.infinity,
            child: SmoothButton(
              label: 'Расшифровать выбранные (${selectedPages.length})',
              onPressed: selectedPages.isEmpty
                  ? null
                  : () => widget.pageIndexNotifier.value = 1,
              icon: const Icon(Icons.lock_open),
              type: SmoothButtonType.filled,
              variant: SmoothButtonVariant.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _getPageWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'страница';
    } else if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'страницы';
    } else {
      return 'страниц';
    }
  }
}

/// Элемент списка страниц
class _PageListItem extends StatelessWidget {
  final DocumentPageDisplayInfo page;
  final bool isSelected;
  final VoidCallback onTap;

  const _PageListItem({
    required this.page,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Чекбокс
              Checkbox(value: isSelected, onChanged: (_) => onTap()),
              const SizedBox(width: 8),

              // Иконка типа файла
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: page.isPrimary
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForMimeType(page.mimeType),
                  size: 20,
                  color: page.isPrimary
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),

              // Информация о странице
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Страница ${page.pageNumber}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (page.isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Обложка',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${page.fileSizeFormatted}${page.mimeType != null ? ' • ${_formatMimeType(page.mimeType!)}' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (page.extractedText != null &&
                        page.extractedText!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        page.extractedText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForMimeType(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file;
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType == 'application/pdf') return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }

  String _formatMimeType(String mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
        return 'JPEG';
      case 'image/png':
        return 'PNG';
      case 'image/webp':
        return 'WebP';
      case 'application/pdf':
        return 'PDF';
      default:
        return mimeType.split('/').last.toUpperCase();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Контент второй страницы - расшифровка
// ─────────────────────────────────────────────────────────────────────────────

class _DocumentDecryptContent extends ConsumerStatefulWidget {
  final DocumentCardDto document;
  final ValueNotifier<int> pageIndexNotifier;
  final ValueNotifier<Set<String>> selectedPagesNotifier;

  const _DocumentDecryptContent({
    required this.document,
    required this.pageIndexNotifier,
    required this.selectedPagesNotifier,
  });

  @override
  ConsumerState<_DocumentDecryptContent> createState() =>
      _DocumentDecryptContentState();
}

class _DocumentDecryptContentState
    extends ConsumerState<_DocumentDecryptContent> {
  final Map<String, _DecryptedPageInfo> _decryptedPages = {};
  bool _isDecrypting = false;
  String? _error;
  int _currentDecryptingIndex = 0;
  int _totalToDecrypt = 0;

  final Map<String, StreamSubscription<WatchEvent>?> _fileWatchers = {};
  late final DecryptedFilesGuardNotifier _decryptedFilesGuardNotifier;

  @override
  void initState() {
    super.initState();
    _decryptedFilesGuardNotifier = ref.read(
      decryptedFilesGuardProvider.notifier,
    );
  }

  @override
  void dispose() {
    for (final subscription in _fileWatchers.values) {
      subscription?.cancel();
    }
    _deleteAllDecryptedFiles(fromDispose: true);
    super.dispose();
  }

  Future<void> _deleteAllDecryptedFiles({bool fromDispose = false}) async {
    for (final info in _decryptedPages.values) {
      await _deleteDecryptedFile(info.decryptedPath, fromDispose: fromDispose);
    }
  }

  Future<void> _deleteDecryptedFile(
    String path, {
    bool fromDispose = false,
  }) async {
    if (fromDispose) {
      Future<void>(() {
        _decryptedFilesGuardNotifier.unregisterFileInUse(path);
      });
    } else {
      _decryptedFilesGuardNotifier.unregisterFileInUse(path);
    }

    final file = File(path);
    if (await file.exists()) {
      try {
        await file.delete();
        logInfo('Deleted decrypted file: $path', tag: _logTag);
      } catch (e, st) {
        logError(
          'Failed to delete decrypted file: $path',
          error: e,
          stackTrace: st,
          tag: _logTag,
        );
      }
    }
  }

  Future<void> _decryptSelectedPages() async {
    final selectedIds = widget.selectedPagesNotifier.value.toList();
    if (selectedIds.isEmpty) return;

    setState(() {
      _isDecrypting = true;
      _error = null;
      _currentDecryptingIndex = 0;
      _totalToDecrypt = selectedIds.length;
    });

    try {
      final documentService = await ref.read(
        documentStorageServiceProvider.future,
      );

      for (int i = 0; i < selectedIds.length; i++) {
        final pageId = selectedIds[i];

        logInfo('Decrypting page $pageId', tag: _logTag);

        setState(() {
          _currentDecryptingIndex = i + 1;
        });

        final decryptedPath = await documentService.decryptDocumentPage(
          pageId: pageId,
        );

        if (mounted) {
          setState(() {
            _decryptedPages[pageId] = _DecryptedPageInfo(
              pageId: pageId,
              decryptedPath: decryptedPath,
              isModified: false,
            );
          });

          _decryptedFilesGuardNotifier.registerFileInUse(decryptedPath);

          _setupFileWatcher(pageId, decryptedPath);
        }
      }

      if (mounted) {
        setState(() {
          _isDecrypting = false;
        });
        Toaster.success(
          title: 'Страницы расшифрованы',
          description:
              'Расшифровано ${selectedIds.length} ${_getPageWord(selectedIds.length)}',
        );
      }
    } catch (e, st) {
      logError(
        'Failed to decrypt pages',
        error: e,
        stackTrace: st,
        tag: _logTag,
      );
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isDecrypting = false;
        });
        Toaster.error(title: 'Ошибка расшифровки', description: e.toString());
      }
    }
  }

  void _setupFileWatcher(String pageId, String path) {
    _fileWatchers[pageId]?.cancel();
    _fileWatchers[pageId] = FileWatcher(path).events.listen((event) {
      if (event.type == ChangeType.MODIFY) {
        if (mounted) {
          setState(() {
            final info = _decryptedPages[pageId];
            if (info != null) {
              _decryptedPages[pageId] = _DecryptedPageInfo(
                pageId: info.pageId,
                decryptedPath: info.decryptedPath,
                isModified: true,
              );
            }
          });
        }
      }
    });
  }

  Future<void> _updatePage(String pageId) async {
    final info = _decryptedPages[pageId];
    if (info == null) return;

    setState(() {
      _error = null;
    });

    try {
      final documentService = await ref.read(
        documentStorageServiceProvider.future,
      );
      final file = File(info.decryptedPath);

      await documentService.updateDocumentPage(
        pageId: pageId,
        newPageFile: file,
      );

      if (mounted) {
        setState(() {
          _decryptedPages[pageId] = _DecryptedPageInfo(
            pageId: info.pageId,
            decryptedPath: info.decryptedPath,
            isModified: false,
          );
        });
        Toaster.success(title: 'Страница обновлена');
      }
    } catch (e, st) {
      logError('Failed to update page', error: e, stackTrace: st, tag: _logTag);
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        Toaster.error(title: 'Ошибка обновления', description: e.toString());
      }
    }
  }

  Future<void> _openFile(String path) async {
    await OpenFile.open(path);
  }

  Future<void> _deleteAndClose() async {
    await _deleteAllDecryptedFiles();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedPages = widget.selectedPagesNotifier.value;
    final hasDecrypted = _decryptedPages.isNotEmpty;
    final hasModified = _decryptedPages.values.any((p) => p.isModified);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Предупреждение
          const NotificationCard(
            type: NotificationType.warning,
            text:
                'Не закрывайте это окно, пока не закончите работу с расшифрованными файлами. При закрытии временные файлы будут удалены.',
          ),
          const SizedBox(height: 16),

          // Информация о выбранных страницах
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.description, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Выбрано страниц: ${selectedPages.length}',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                if (!hasDecrypted)
                  TextButton(
                    onPressed: () => widget.pageIndexNotifier.value = 0,
                    child: const Text('Изменить'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ошибка
          if (_error != null) ...[
            NotificationCard(
              type: NotificationType.error,
              text: _error!,
              onDismiss: () => setState(() => _error = null),
            ),
            const SizedBox(height: 16),
          ],

          // Прогресс расшифровки
          if (_isDecrypting) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Расшифровка страницы $_currentDecryptingIndex из $_totalToDecrypt...',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _currentDecryptingIndex / _totalToDecrypt,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Список расшифрованных страниц
          if (hasDecrypted) ...[
            Text(
              'Расшифрованные страницы',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _decryptedPages.length,
                itemBuilder: (context, index) {
                  final info = _decryptedPages.values.elementAt(index);
                  return _DecryptedPageItem(
                    info: info,
                    index: index + 1,
                    onOpen: () => _openFile(info.decryptedPath),
                    onUpdate: info.isModified
                        ? () => _updatePage(info.pageId)
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Кнопки действий
          if (!hasDecrypted) ...[
            SizedBox(
              width: double.infinity,
              child: SmoothButton(
                label: _isDecrypting
                    ? 'Расшифровка...'
                    : 'Расшифровать ${selectedPages.length} ${_getPageWord(selectedPages.length)}',
                onPressed: _isDecrypting ? null : _decryptSelectedPages,
                icon: const Icon(Icons.lock_open),
                type: SmoothButtonType.filled,
                loading: _isDecrypting,
              ),
            ),
          ] else ...[
            if (hasModified) ...[
              const NotificationCard(
                type: NotificationType.info,
                text:
                    'Некоторые файлы были изменены. Сохраните изменения перед закрытием.',
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: SliderButton(
                type: SliderButtonType.delete,
                text: 'Удалить файлы и закрыть',
                onSlideCompleteAsync: _deleteAndClose,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getPageWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'страницу';
    } else if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'страницы';
    } else {
      return 'страниц';
    }
  }
}

/// Информация о расшифрованной странице
class _DecryptedPageInfo {
  final String pageId;
  final String decryptedPath;
  final bool isModified;

  const _DecryptedPageInfo({
    required this.pageId,
    required this.decryptedPath,
    required this.isModified,
  });
}

/// Элемент списка расшифрованных страниц
class _DecryptedPageItem extends StatelessWidget {
  final _DecryptedPageInfo info;
  final int index;
  final VoidCallback onOpen;
  final VoidCallback? onUpdate;

  const _DecryptedPageItem({
    required this.info,
    required this.index,
    required this.onOpen,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: info.isModified
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: info.isModified
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Страница $index',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (info.isModified)
                    Text(
                      'Изменено',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            if (onUpdate != null)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: onUpdate,
                tooltip: 'Сохранить изменения',
                color: theme.colorScheme.primary,
              ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: onOpen,
              tooltip: 'Открыть файл',
            ),
          ],
        ),
      ),
    );
  }
}
