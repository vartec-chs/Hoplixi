import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/color_parser.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/models/drawer_tag_filter_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/providers/drawer_tag_filter_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

import '../colors.dart';

class TagSection extends ConsumerStatefulWidget {
  const TagSection({super.key, required this.entityType});

  final EntityType entityType;

  @override
  ConsumerState<TagSection> createState() => _TagSectionState();
}

class _TagSectionState extends ConsumerState<TagSection> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(drawerTagFilterProvider(widget.entityType).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagStateAsync = ref.watch(drawerTagFilterProvider(widget.entityType));
    final notifier = ref.read(
      drawerTagFilterProvider(widget.entityType).notifier,
    );

    final selectedIds = tagStateAsync.whenOrNull(
      data: (state) => state.selectedIds,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          context,
          theme,
          notifier,
          selectedIds: selectedIds ?? const [],
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: tagStateAsync.when(
              data: (state) => KeyedSubtree(
                key: const ValueKey('data'),
                child: _buildBody(state, theme, notifier),
              ),
              loading: () => const Center(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Center(
                key: const ValueKey('error'),
                child: Text('Ошибка загрузки тегов'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    DrawerTagFilterNotifier notifier, {
    required List<String> selectedIds,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Теги', style: theme.textTheme.titleMedium),
              Row(
                children: [
                  if (selectedIds.isNotEmpty)
                    SmoothButton(
                      onPressed: notifier.clearSelection,
                      label: 'Очистить',
                      size: SmoothButtonSize.small,
                      type: SmoothButtonType.text,
                    ),
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    iconSize: 20,
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: notifier.reload,
                    tooltip: 'Обновить теги',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),
        SizedBox(
          height: 40.0,
          child: TextField(
            decoration: primaryInputDecoration(
              context,
              hintText: 'Поиск тегов...',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: notifier.search,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    DrawerTagFilterState state,
    ThemeData theme,
    DrawerTagFilterNotifier notifier,
  ) {
    if (state.tags.isEmpty && !state.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Теги не найдены',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: state.tags.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.tags.length) {
          return state.isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox.shrink();
        }

        final tag = state.tags[index];
        final isSelected = state.selectedIds.contains(tag.id);

        return CheckboxListTile(
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          checkColor: ColorsHelper.onColorFor(
            ColorsHelper.parseColor(tag.color, theme.colorScheme.primary),
          ),
          fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? ColorsHelper.parseColor(tag.color, theme.colorScheme.primary)
                : null,
          ),
          controlAffinity: .leading,
          value: isSelected,
          onChanged: (_) => notifier.toggle(tag.id),
          title: Text(tag.name),
          subtitle: tag.itemsCount > 0
              ? Text('${tag.itemsCount} элементов')
              : null,
          secondary: tag.color != null
              ? Icon(Icons.tag, size: 18, color: parseColor(tag.color, context))
              : null,
          dense: true,
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }
}
