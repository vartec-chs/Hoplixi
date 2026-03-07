import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/color_parser.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/models/drawer_tag_filter_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/providers/drawer_tag_filter_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: tagStateAsync.when(
        data: (state) => Container(
          key: ValueKey('data-${state.tags.length}'),
          child: _buildData(state, theme, notifier),
        ),
        loading: () => const Center(
          key: ValueKey('loading'),
          child: CircularProgressIndicator(
           
          ),
        ),
        error: (e, _) => Center(
          key: const ValueKey('error'),
          child: Text(
            'Ошибка загрузки тегов',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildData(
    DrawerTagFilterState state,
    ThemeData theme,
    DrawerTagFilterNotifier notifier,
  ) {
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
                  if (state.selectedIds.isNotEmpty)
                    SmoothButton(
                      onPressed: notifier.clearSelection,
                      label: 'Очистить',
                      size: SmoothButtonSize.small,
                      type: SmoothButtonType.text,
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
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
        const SizedBox(height: 8.0),

        Expanded(
          child: state.tags.isEmpty && !state.isLoading
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Теги не найдены',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
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
                      value: isSelected,
                      onChanged: (_) => notifier.toggle(tag.id),
                      title: Text(tag.name),
                      subtitle: tag.itemsCount > 0
                          ? Text('${tag.itemsCount} элементов')
                          : null,
                      secondary: tag.color != null
                          ? Icon(
                              Icons.tag,
                              size: 18,
                              color: parseColor(tag.color, context),
                            )
                          : null,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
