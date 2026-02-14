import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/logs_viewer/providers/logs_provider.dart';
import 'package:hoplixi/features/logs_viewer/widgets/log_entry_tile.dart';
import 'package:hoplixi/features/logs_viewer/widgets/logs_filter_bar.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Главный экран для просмотра логов
class LogsViewerScreen extends ConsumerWidget {
  const LogsViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logFiles = ref.watch(logFilesProvider);
    final selectedFile = ref.watch(selectedLogFileProvider);
    final paginatedLogs = ref.watch(paginatedLogsProvider);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Просмотр логов'),
        elevation: 0,
        leading: ref.watch(selectedLogFileProvider) != null && !isDesktop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(selectedLogFileProvider.notifier).setFile(null);
                },
              )
            : null,

        backgroundColor: theme.colorScheme.surface,
        actions: [
          if (selectedFile != null) ...[
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Копировать содержимое',
              onPressed: () => _copyFileContent(context, selectedFile),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: theme.colorScheme.error),
              tooltip: 'Удалить файл',
              onPressed: () => _deleteFile(context, ref, selectedFile),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: logFiles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки логов: $error',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        data: (files) {
          if (files.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Файлы логов не найдены',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!isDesktop) {
            return _buildMobileLayout(
              context,
              ref,
              files,
              selectedFile,
              paginatedLogs,
              theme,
            );
          }

          return Row(
            children: [
              // Список файлов логов (Sidebar)
              Container(
                width: 280,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  // border: Border(
                  //   right: BorderSide(color: theme.dividerColor, width: 1),
                  // ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Файлы (${files.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          final fileName = file.path
                              .split(Platform.pathSeparator)
                              .last;
                          final isSelected = selectedFile?.path == file.path;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              title: Text(
                                fileName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              selected: isSelected,
                              selectedTileColor: theme
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onTap: () {
                                ref
                                    .read(selectedLogFileProvider.notifier)
                                    .setFile(file);
                              },
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Область просмотра логов
              Expanded(
                child: Column(
                  children: [
                    // Фильтры и поиск
                    const LogsFilterBar(),
                    // Список логов
                    Expanded(
                      child: paginatedLogs.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) => Center(
                          child: Text(
                            'Ошибка: $error',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                        data: (state) {
                          final logs = state.logs;
                          if (selectedFile == null) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    size: 48,
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Выберите файл логов слева',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (logs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.filter_alt_off,
                                    size: 48,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Логи не найдены',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Измените фильтры или выберите другой файл',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (scrollInfo.metrics.pixels >=
                                      scrollInfo.metrics.maxScrollExtent -
                                          200 &&
                                  state.hasMore &&
                                  !state.isLoadingMore) {
                                ref
                                    .read(paginatedLogsProvider.notifier)
                                    .loadMore();
                              }
                              return false;
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                              ),

                              child: ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount:
                                    logs.length + (state.hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == logs.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final log = logs[index];
                                  return LogEntryTile(entry: log);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    List<File> files,
    File? selectedFile,
    AsyncValue paginatedLogs,
    ThemeData theme,
  ) {
    return Scaffold(
      appBar: selectedFile == null
          ? null
          : AppBar(
              centerTitle: true,
              title: Text(
                selectedFile.path.split(Platform.pathSeparator).last,
                style: const TextStyle(fontSize: 14),
              ),
              leading: const SizedBox.shrink(),
              backgroundColor: theme.colorScheme.surface,
            ),
      body: selectedFile == null
          ? Container(
              decoration: BoxDecoration(color: theme.colorScheme.surface),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Файлы логов (${files.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        final fileName = file.path
                            .split(Platform.pathSeparator)
                            .last;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            title: Text(
                              fileName,
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onTap: () {
                              ref
                                  .read(selectedLogFileProvider.notifier)
                                  .setFile(file);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                const LogsFilterBar(),
                Expanded(
                  child: paginatedLogs.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        'Ошибка: $error',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                    data: (state) {
                      final logs = state.logs;
                      if (logs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_alt_off,
                                size: 48,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Логи не найдены',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Измените фильтры',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          if (scrollInfo.metrics.pixels >=
                                  scrollInfo.metrics.maxScrollExtent - 200 &&
                              state.hasMore &&
                              !state.isLoadingMore) {
                            ref.read(paginatedLogsProvider.notifier).loadMore();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: logs.length + (state.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == logs.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final log = logs[index];
                            return LogEntryTile(entry: log);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _copyFileContent(BuildContext context, File file) async {
    try {
      final content = await file.readAsString();
      await Clipboard.setData(ClipboardData(text: content));
      if (context.mounted) {
        Toaster.success(
          title: 'Скопировано',
          description: 'Содержимое файла скопировано в буфер обмена',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Toaster.error(
          title: 'Ошибка',
          description: 'Не удалось скопировать файл: $e',
        );
      }
    }
  }

  Future<void> _deleteFile(
    BuildContext context,
    WidgetRef ref,
    File file,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить файл?'),
        content: Text(
          'Вы уверены, что хотите удалить файл ${file.path.split(Platform.pathSeparator).last}?',
        ),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(false),
            label: 'Отмена',
            type: SmoothButtonType.text,
          ),
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: 'Удалить',
            type: SmoothButtonType.filled,
            variant: SmoothButtonVariant.error,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await deleteLogFile(ref, file);
        if (context.mounted) {
          Toaster.success(title: 'Удалено', description: 'Файл успешно удален');
        }
      } catch (e) {
        if (context.mounted) {
          Toaster.error(
            title: 'Ошибка',
            description: 'Не удалось удалить файл: $e',
          );
        }
      }
    }
  }
}
