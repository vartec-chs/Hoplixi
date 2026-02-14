import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/logs_viewer/providers/logs_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Экран для просмотра отчетов о падениях
class CrashReportsScreen extends ConsumerWidget {
  const CrashReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crashReports = ref.watch(crashReportsProvider);
    final selectedReport = ref.watch(selectedCrashReportProvider);
    final reportContent = ref.watch(crashReportContentProvider);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Отчеты о падениях'),
        elevation: 0,
        leading: ref.watch(selectedCrashReportProvider) != null && !isDesktop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(selectedCrashReportProvider.notifier).setFile(null);
                },
              )
            : null,

        backgroundColor: theme.colorScheme.surface,
        actions: [
          if (selectedReport != null) ...[
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Копировать содержимое',
              onPressed: () => _copyReportContent(context, selectedReport),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: theme.colorScheme.error),
              tooltip: 'Удалить отчет',
              onPressed: () => _deleteReport(context, ref, selectedReport),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: crashReports.when(
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
                'Ошибка загрузки: $error',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Отчеты о падениях не найдены',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
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
              reports,
              selectedReport,
              reportContent,
              theme,
            );
          }

          return Row(
            children: [
              // Список отчетов
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
                        'Отчеты (${reports.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          final fileName = report.path
                              .split(Platform.pathSeparator)
                              .last;
                          final isSelected =
                              selectedReport?.path == report.path;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              title: Text(
                                fileName,
                                overflow: TextOverflow.ellipsis,
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
                                    .read(selectedCrashReportProvider.notifier)
                                    .setFile(report);
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
              // Детали отчета
              Expanded(
                child: reportContent.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Text(
                      'Ошибка загрузки отчета: $error',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                  data: (data) {
                    if (data == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.select_all,
                              size: 48,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Выберите отчет для просмотра деталей',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Время падения
                          if (data['timestamp'] != null) ...[
                            Text(
                              'Время падения',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: SelectableText(
                                data['timestamp'] ?? 'N/A',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Ошибка
                          if (data['error'] != null) ...[
                            Text(
                              'Ошибка',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: theme.colorScheme.errorContainer,
                                ),
                              ),
                              child: SelectableText(
                                data['error'],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Stack trace
                          if (data['stackTrace'] != null) ...[
                            Text(
                              'Stack Trace',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: theme.colorScheme.tertiaryContainer,
                                ),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SelectableText(
                                  data['stackTrace'],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.tertiary,
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Информация о сессии
                          if (data['session'] != null) ...[
                            Text(
                              'Информация о сессии',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            _buildSessionInfo(context, data['session']),
                          ],
                        ],
                      ),
                    );
                  },
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
    List<File> reports,
    File? selectedReport,
    AsyncValue reportContent,
    ThemeData theme,
  ) {
    return Scaffold(
      appBar: selectedReport == null
          ? null
          : AppBar(
              title: Text(
                selectedReport.path.split(Platform.pathSeparator).last,
                style: const TextStyle(fontSize: 14),
              ),
              leading: const SizedBox.shrink(),
              backgroundColor: theme.colorScheme.surface,
              centerTitle: true,
            ),
      body: selectedReport == null
          ? Container(
              decoration: BoxDecoration(color: theme.colorScheme.surface),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Отчеты о падениях (${reports.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        final fileName = report.path
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
                                  .read(selectedCrashReportProvider.notifier)
                                  .setFile(report);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          : reportContent.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Ошибка загрузки отчета: $error',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
              data: (data) {
                if (data == null) {
                  return Center(
                    child: Text(
                      'Выберите отчет',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['timestamp'] != null) ...[
                        Text(
                          'Время падения',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: SelectableText(
                            data['timestamp'],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (data['error'] != null) ...[
                        Text('Ошибка', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer.withOpacity(
                              0.3,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.error.withOpacity(0.5),
                            ),
                          ),
                          child: SelectableText(
                            data['error'],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (data['stackTrace'] != null) ...[
                        Text('Stack Trace', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: SelectableText(
                            data['stackTrace'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (data['session'] != null) ...[
                        Text(
                          'Информация о сессии',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        _buildSessionInfo(context, data['session']),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSessionInfo(BuildContext context, Map<String, dynamic> session) {
    final deviceInfo = session['deviceInfo'] ?? {};
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(context, 'Session ID:', session['id'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'Платформа:', deviceInfo['platform'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'Модель:', deviceInfo['deviceModel'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            'Версия ОС:',
            deviceInfo['platformVersion'] ?? 'N/A',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            'Версия приложения:',
            deviceInfo['appVersion'] ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SelectableText(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _copyReportContent(BuildContext context, File file) async {
    try {
      final content = await file.readAsString();
      await Clipboard.setData(ClipboardData(text: content));
      if (context.mounted) {
        Toaster.success(
          title: 'Скопировано',
          description: 'Содержимое отчета скопировано в буфер обмена',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Toaster.error(
          title: 'Ошибка',
          description: 'Не удалось скопировать отчет: $e',
        );
      }
    }
  }

  Future<void> _deleteReport(
    BuildContext context,
    WidgetRef ref,
    File file,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить отчет?'),
        content: Text(
          'Вы уверены, что хотите удалить отчет ${file.path.split(Platform.pathSeparator).last}?',
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
        await deleteCrashReport(ref, file);
        if (context.mounted) {
          Toaster.success(
            title: 'Удалено',
            description: 'Отчет успешно удален',
          );
        }
      } catch (e) {
        if (context.mounted) {
          Toaster.error(
            title: 'Ошибка',
            description: 'Не удалось удалить отчет: $e',
          );
        }
      }
    }
  }
}
