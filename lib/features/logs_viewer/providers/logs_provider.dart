import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/models.dart';
import 'package:hoplixi/features/logs_viewer/models/log_parser.dart';

// ============================================================================
// Notifier classes for state management
// ============================================================================

/// Notifier для управления выбранным файлом логов
class SelectedLogFileNotifier extends Notifier<File?> {
  @override
  File? build() => null;

  void setFile(File? file) {
    state = file;
  }
}

/// Notifier для управления фильтром по уровню
class LogLevelFilterNotifier extends Notifier<LogLevel?> {
  @override
  LogLevel? build() => null;

  void setLevel(LogLevel? level) {
    state = level;
  }
}

/// Notifier для управления фильтром по тегу
class LogTagFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setTag(String? tag) {
    state = tag;
  }
}

/// Notifier для управления поисковым запросом
class LogSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

/// Notifier для управления выбранным отчетом о падении
class SelectedCrashReportNotifier extends Notifier<File?> {
  @override
  File? build() => null;

  void setFile(File? file) {
    state = file;
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Провайдер для получения списка файлов логов
final logFilesProvider = FutureProvider<List<File>>((ref) async {
  final dir = Directory(await AppPaths.appLogsPath);
  if (!await dir.exists()) {
    return [];
  }

  return dir
      .listSync()
      .where((entity) => entity is File && entity.path.endsWith('.jsonl'))
      .cast<File>()
      .toList()
    ..sort((a, b) => b.path.compareTo(a.path)); // Новые файлы первыми
});

/// Провайдер для содержимого выбранного файла логов
final selectedLogFileProvider =
    NotifierProvider<SelectedLogFileNotifier, File?>(
      SelectedLogFileNotifier.new,
    );

/// Провайдер для фильтрации логов по уровню
final logLevelFilterProvider =
    NotifierProvider<LogLevelFilterNotifier, LogLevel?>(
      LogLevelFilterNotifier.new,
    );

/// Провайдер для фильтрации логов по тегу
final logTagFilterProvider = NotifierProvider<LogTagFilterNotifier, String?>(
  LogTagFilterNotifier.new,
);

/// Провайдер для фильтрации логов по поисковому запросу
final logSearchQueryProvider = NotifierProvider<LogSearchQueryNotifier, String>(
  LogSearchQueryNotifier.new,
);

// ============================================================================
// Pagination Logic
// ============================================================================

class LogsPaginationState {
  final List<LogEntry> logs;
  final bool hasMore;
  final bool isLoadingMore;

  const LogsPaginationState({
    this.logs = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  LogsPaginationState copyWith({
    List<LogEntry>? logs,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return LogsPaginationState(
      logs: logs ?? this.logs,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class PaginatedLogsNotifier extends AsyncNotifier<LogsPaginationState> {
  StreamIterator<String>? _lineIterator;
  static const int _pageSize = 50;

  @override
  Future<LogsPaginationState> build() async {
    final file = ref.watch(selectedLogFileProvider);
    // Watch filters to trigger rebuild
    ref.watch(logLevelFilterProvider);
    ref.watch(logTagFilterProvider);
    ref.watch(logSearchQueryProvider);

    if (file == null) {
      return const LogsPaginationState(hasMore: false);
    }

    // Close previous iterator if any
    await _lineIterator?.cancel();

    // Create new iterator
    final stream = file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    _lineIterator = StreamIterator(stream);

    return _loadNextPage(isInitial: true);
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMore ||
        state.isLoading ||
        state.isRefreshing ||
        currentState.isLoadingMore) {
      return;
    }

    // Set loading state
    state = AsyncData(currentState.copyWith(isLoadingMore: true));

    try {
      final newState = await _loadNextPage(previousLogs: currentState.logs);
      state = AsyncData(newState);
    } catch (e) {
      // Revert loading state on error
      state = AsyncData(currentState.copyWith(isLoadingMore: false));
      // Ideally we would expose the error, but without copyWithPrevious it's tricky to keep data.
      // We rely on the UI to handle stream errors or we could add error field to state.
    }
  }

  Future<LogsPaginationState> _loadNextPage({
    List<LogEntry> previousLogs = const [],
    bool isInitial = false,
  }) async {
    final iterator = _lineIterator;
    if (iterator == null) return const LogsPaginationState(hasMore: false);

    final levelFilter = ref.read(logLevelFilterProvider);
    final tagFilter = ref.read(logTagFilterProvider);
    final searchQuery = ref.read(logSearchQueryProvider).trim().toLowerCase();

    final newLogs = <LogEntry>[];
    bool hasMore = true;

    // We need to find _pageSize matching logs
    while (newLogs.length < _pageSize) {
      if (!await iterator.moveNext()) {
        hasMore = false;
        break;
      }

      final line = iterator.current;
      final entry = LogParser.parseLine(line);

      if (entry is LogEntry) {
        if (_matchesFilter(entry, levelFilter, tagFilter, searchQuery)) {
          newLogs.add(entry);
        }
      }
    }

    return LogsPaginationState(
      logs: [...previousLogs, ...newLogs],
      hasMore: hasMore,
    );
  }

  bool _matchesFilter(
    LogEntry log,
    LogLevel? levelFilter,
    String? tagFilter,
    String searchQuery,
  ) {
    // Фильтр по уровню
    if (levelFilter != null && log.level != levelFilter) {
      return false;
    }

    // Фильтр по тегу
    if (tagFilter != null) {
      final logTag = log.tag;
      if (logTag == null || logTag.toLowerCase() != tagFilter.toLowerCase()) {
        return false;
      }
    }

    // Нормализованный поисковый запрос
    if (searchQuery.isEmpty) {
      return true;
    }

    // Фильтр по поисковому запросу
    final messageMatch = log.message.toLowerCase().contains(searchQuery);
    final tagMatch = (log.tag ?? '').toLowerCase().contains(searchQuery);
    final errorMatch = (log.error?.toString() ?? '').toLowerCase().contains(
      searchQuery,
    );
    final stackMatch = (log.stackTrace?.toString() ?? '')
        .toLowerCase()
        .contains(searchQuery);
    final additionalDataMatch = (log.additionalData?.toString() ?? '')
        .toLowerCase()
        .contains(searchQuery);

    if (!(messageMatch ||
        tagMatch ||
        errorMatch ||
        stackMatch ||
        additionalDataMatch)) {
      return false;
    }
    return true;
  }
}

/// Провайдер для пагинированных логов
final paginatedLogsProvider =
    AsyncNotifierProvider<PaginatedLogsNotifier, LogsPaginationState>(
      PaginatedLogsNotifier.new,
    );

/// Провайдер для получения уникальных тегов (читает весь файл)
final availableTagsProvider = FutureProvider<List<String>>((ref) async {
  final file = ref.watch(selectedLogFileProvider);
  if (file == null) return [];

  try {
    final content = await file.readAsString();
    final logs = LogParser.parseJsonl(content);
    final tags =
        logs
            .whereType<LogEntry>()
            .map((log) => log.tag)
            .where((tag) => tag != null)
            .cast<String>()
            .toSet()
            .toList()
          ..sort();

    return tags;
  } catch (e) {
    return [];
  }
});

/// Провайдер для получения файлов отчетов о падениях
final crashReportsProvider = FutureProvider<List<File>>((ref) async {
  final dir = Directory(await AppPaths.appCrashReportsPath);
  if (!await dir.exists()) {
    return [];
  }

  return dir
      .listSync()
      .where((entity) => entity is File && entity.path.endsWith('.jsonl'))
      .cast<File>()
      .toList()
    ..sort((a, b) => b.path.compareTo(a.path)); // Новые файлы первыми
});

/// Провайдер для выбранного отчета о падении
final selectedCrashReportProvider =
    NotifierProvider<SelectedCrashReportNotifier, File?>(
      SelectedCrashReportNotifier.new,
    );

/// Провайдер для содержимого отчета о падении
final crashReportContentProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final selectedFile = ref.watch(selectedCrashReportProvider);

  if (selectedFile == null) {
    return null;
  }

  try {
    final content = await selectedFile.readAsString();
    return Map<String, dynamic>.from(jsonDecode(content));
  } catch (e) {
    return null;
  }
});

/// Удаляет файл логов
Future<void> deleteLogFile(WidgetRef ref, File file) async {
  try {
    if (await file.exists()) {
      await file.delete();
      ref.invalidate(logFilesProvider);

      final selectedFile = ref.read(selectedLogFileProvider);
      if (selectedFile?.path == file.path) {
        ref.read(selectedLogFileProvider.notifier).setFile(null);
      }
    }
  } catch (e) {
    rethrow;
  }
}

/// Удаляет файл отчета о падении
Future<void> deleteCrashReport(WidgetRef ref, File file) async {
  try {
    if (await file.exists()) {
      await file.delete();
      ref.invalidate(crashReportsProvider);

      final selectedReport = ref.read(selectedCrashReportProvider);
      if (selectedReport?.path == file.path) {
        ref.read(selectedCrashReportProvider.notifier).setFile(null);
      }
    }
  } catch (e) {
    rethrow;
  }
}
