import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/icon_picker_state.dart';
import '../provider/icon_picker_list_provider.dart';
import 'icon_picker_card.dart';

/// Виджет сетки иконок с пагинацией
class IconPickerGrid extends ConsumerStatefulWidget {
  final Function(String iconId) onIconSelected;

  const IconPickerGrid({super.key, required this.onIconSelected});

  @override
  ConsumerState<IconPickerGrid> createState() => _IconPickerGridState();
}

class _IconPickerGridState extends ConsumerState<IconPickerGrid> {
  final ScrollController _scrollController = ScrollController();

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
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  void _loadMore() {
    final notifier = ref.read(iconPickerListProvider.notifier);
    notifier.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(iconPickerListProvider);

    return asyncState.when(
      data: (IconPickerState pickerState) {
        final items = pickerState.items;
        final isLoading = pickerState.isLoading;
        final error = pickerState.error;

        if (items.isEmpty && !isLoading && error == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Иконки не найдены'),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final icon = items[index];
                  return IconPickerCard(
                    icon: icon,
                    onTap: () => widget.onIconSelected(icon.id),
                  );
                },
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            if (error != null && items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton.icon(
                  onPressed: _loadMore,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Ошибка загрузки. Повторить'),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Ошибка загрузки иконок'),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(iconPickerListProvider.notifier).refresh();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
