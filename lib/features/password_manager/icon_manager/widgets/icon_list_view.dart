import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/icon_dto.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import '../provider/icon_list_provider.dart';
import 'icon_card.dart';

/// Виджет для отображения списка иконок с пагинацией
class IconListView extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onRefresh;
  final Function(IconsData) onIconTap;

  const IconListView({
    super.key,
    required this.scrollController,
    required this.onRefresh,
    required this.onIconTap,
  });

  @override
  ConsumerState<IconListView> createState() => _IconListViewState();
}

class _IconListViewState extends ConsumerState<IconListView> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController.position.pixels >=
        widget.scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  void _loadMore() {
    final notifier = ref.read(iconListProvider.notifier);
    notifier.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(iconListProvider);

    return asyncState.when(
      data: (paginationState) {
        final items = paginationState.items;
        final isLoading = paginationState.isLoading;
        final error = paginationState.error;

        if (items.isEmpty && !isLoading && error == null) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Иконки не найдены',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Попробуйте изменить фильтры',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildListDelegate([
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return IconCard(
                      icon: IconCardDto(
                        id: item.id,
                        name: item.name,
                        type: item.type.value,
                        createdAt: item.createdAt,
                        modifiedAt: item.modifiedAt,
                      ),
                      // iconData не передаем - IconCard загрузит асинхронно
                      onTap: () {
                        widget.onIconTap(item);
                      },
                    );
                  },
                ),
              ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (error != null && items.isNotEmpty)
              InkWell(
                onTap: _loadMore,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(
                        'Ошибка загрузки. Нажмите для повтора.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ]),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки иконок',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onRefresh,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
