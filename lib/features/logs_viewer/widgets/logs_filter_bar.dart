import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/models.dart';
import 'package:hoplixi/features/logs_viewer/providers/logs_provider.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Виджет для фильтрации и поиска логов
class LogsFilterBar extends ConsumerStatefulWidget {
  const LogsFilterBar({super.key});

  @override
  ConsumerState<LogsFilterBar> createState() => _LogsFilterBarState();
}

class _LogsFilterBarState extends ConsumerState<LogsFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(logSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _levelLabel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.trace:
        return 'TRACE';
      case LogLevel.fatal:
        return 'FATAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelFilter = ref.watch(logLevelFilterProvider);
    final tagFilter = ref.watch(logTagFilterProvider);
    final searchQuery = ref.watch(logSearchQueryProvider);
    final availableTags = ref.watch(availableTagsProvider);
    final theme = Theme.of(context);

    if (_searchController.text != searchQuery) {
      _searchController.value = TextEditingValue(
        text: searchQuery,
        selection: TextSelection.collapsed(offset: searchQuery.length),
      );
    }

    final hasActiveFilters =
        levelFilter != null || tagFilter != null || searchQuery.isNotEmpty;

    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Фильтры', style: theme.textTheme.titleSmall),
              const Spacer(),
              if (hasActiveFilters)
                TextButton.icon(
                  onPressed: () {
                    ref.read(logLevelFilterProvider.notifier).setLevel(null);
                    ref.read(logTagFilterProvider.notifier).setTag(null);
                    ref.read(logSearchQueryProvider.notifier).setQuery('');
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Сбросить'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Поиск
          TextField(
            controller: _searchController,
            onChanged: (value) {
              ref.read(logSearchQueryProvider.notifier).setQuery(value);
            },
            decoration: primaryInputDecoration(
              context,
              hintText: 'Поиск: сообщение, тег, ошибка, stack trace, данные...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        ref.read(logSearchQueryProvider.notifier).setQuery('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          // Фильтр по уровню
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Все уровни'),
                selected: levelFilter == null,
                onSelected: (_) {
                  ref.read(logLevelFilterProvider.notifier).setLevel(null);
                },
              ),
              ...LogLevel.values.map(
                (level) => ChoiceChip(
                  label: Text(_levelLabel(level)),
                  selected: levelFilter == level,
                  onSelected: (_) {
                    ref.read(logLevelFilterProvider.notifier).setLevel(level);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Фильтр по тегу
          availableTags.when(
            loading: () => const SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (error, stackTrace) => const SizedBox.shrink(),
            data: (tags) {
              if (tags.isEmpty) {
                return const SizedBox.shrink();
              }

              final resolvedTagFilter =
                  tagFilter != null && tags.contains(tagFilter)
                  ? tagFilter
                  : null;

              return DropdownButtonFormField<String?>(
                value: resolvedTagFilter,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Тег',
                  prefixIcon: const Icon(Icons.sell_outlined),
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Все теги'),
                  ),
                  ...tags.map(
                    (tag) =>
                        DropdownMenuItem<String?>(value: tag, child: Text(tag)),
                  ),
                ],
                onChanged: (value) {
                  ref.read(logTagFilterProvider.notifier).setTag(value);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
