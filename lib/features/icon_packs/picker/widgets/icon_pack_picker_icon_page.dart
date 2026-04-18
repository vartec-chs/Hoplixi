import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/icon_packs/models/icon_pack_entry.dart';
import 'package:hoplixi/features/icon_packs/models/icon_pack_summary.dart';
import 'package:hoplixi/features/icon_packs/picker/widgets/icon_pack_picker_empty_states.dart';
import 'package:hoplixi/features/icon_packs/picker/widgets/icon_pack_picker_icon_card.dart';
import 'package:hoplixi/features/icon_packs/providers/icon_packs_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class IconPackPickerIconPage extends ConsumerStatefulWidget {
  const IconPackPickerIconPage({
    super.key,
    required this.pack,
    required this.previewColor,
    required this.onIconSelected,
    this.initialIconKey,
  });

  final IconPackSummary pack;
  final ValueNotifier<Color?> previewColor;
  final ValueChanged<String> onIconSelected;
  final String? initialIconKey;

  @override
  ConsumerState<IconPackPickerIconPage> createState() =>
      _IconPackPickerIconPageState();
}

class _IconPackPickerIconPageState
    extends ConsumerState<IconPackPickerIconPage> {
  static const int _pageSize = 48;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<IconPackEntry> _items = const [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant IconPackPickerIconPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pack.packKey != widget.pack.packKey) {
      _searchController.clear();
      _searchDebounce?.cancel();
      _loadInitial();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _items = const [];
      _hasMore = true;
      _errorText = null;
    });

    try {
      final service = ref.read(iconPackCatalogServiceProvider);
      final entries = await service.listIcons(
        packKey: widget.pack.packKey,
        query: _searchController.text,
        offset: 0,
        limit: _pageSize,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items = entries;
        _hasMore = entries.length >= _pageSize;
        _isInitialLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = error.toString();
        _isInitialLoading = false;
        _hasMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isInitialLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
      _errorText = null;
    });

    try {
      final service = ref.read(iconPackCatalogServiceProvider);
      final entries = await service.listIcons(
        packKey: widget.pack.packKey,
        query: _searchController.text,
        offset: _items.length,
        limit: _pageSize,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items = [..._items, ...entries];
        _hasMore = entries.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = error.toString();
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<Color?>(
      valueListenable: widget.previewColor,
      builder: (context, selectedPreviewColor, _) {
        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: primaryInputDecoration(
                        context,
                        labelText: 'Поиск иконки',
                        hintText: 'Введите имя, ключ или путь',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Очистить поиск',
                                onPressed: () {
                                  _searchController.clear();
                                  _searchDebounce?.cancel();
                                  _loadInitial();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                      onChanged: (_) {
                        setState(() {});
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 250),
                          _loadInitial,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Цвет предпросмотра',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Оригинал'),
                                selected: selectedPreviewColor == null,
                                onSelected: (_) {
                                  widget.previewColor.value = null;
                                },
                              ),
                              _buildColorChip(
                                context,
                                label: 'Текст',
                                color: theme.colorScheme.onSurface,
                                selectedPreviewColor: selectedPreviewColor,
                              ),
                              _buildColorChip(
                                context,
                                label: 'Primary',
                                color: theme.colorScheme.primary,
                                selectedPreviewColor: selectedPreviewColor,
                              ),
                              _buildColorChip(
                                context,
                                label: 'Secondary',
                                color: theme.colorScheme.secondary,
                                selectedPreviewColor: selectedPreviewColor,
                              ),
                              _buildColorChip(
                                context,
                                label: 'Error',
                                color: theme.colorScheme.error,
                                selectedPreviewColor: selectedPreviewColor,
                              ),
                              SmoothButton(
                                type: .text,
                                size: .small,
                                onPressed: () => _pickPreviewColor(
                                  context,
                                  initialColor:
                                      selectedPreviewColor ??
                                      theme.colorScheme.primary,
                                ),
                                icon: _PreviewColorDot(
                                  color:
                                      selectedPreviewColor ??
                                      theme.colorScheme.outline,
                                ),
                                label: 'Другой',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            ..._buildBodySlivers(context, previewColor: selectedPreviewColor),
          ],
        );
      },
    );
  }

  List<Widget> _buildBodySlivers(BuildContext context, {Color? previewColor}) {
    if (_isInitialLoading) {
      return const [
        SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      ];
    }

    if (_items.isEmpty && _errorText != null) {
      return [
        SliverFillRemaining(
          child: IconPackPickerLoadErrorState(
            title: 'Не удалось загрузить иконки',
            errorText: _errorText!,
            onRetry: _loadInitial,
          ),
        ),
      ];
    }

    if (_items.isEmpty) {
      return const [
        SliverFillRemaining(
          child: IconPackPickerEmptyState(
            icon: Icons.image_search_outlined,
            title: 'Иконки не найдены',
            description: 'Попробуйте изменить поисковый запрос.',
          ),
        ),
      ];
    }

    return [
      SliverLayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _resolveCrossAxisCount(
            constraints.crossAxisExtent,
          );

          return SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.84,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final entry = _items[index];
                return IconPackPickerIconCard(
                  entry: entry,
                  previewColor: previewColor,
                  isSelected: entry.key == widget.initialIconKey,
                  onTap: () => widget.onIconSelected(entry.key),
                );
              }, childCount: _items.length),
            ),
          );
        },
      ),
      if (_isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      if (_errorText != null && _items.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: TextButton.icon(
              onPressed: _loadMore,
              icon: const Icon(Icons.refresh),
              label: const Text('Ошибка загрузки. Повторить'),
            ),
          ),
        ),
      if (_hasMore && !_isLoadingMore)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: TextButton.icon(
              onPressed: _loadMore,
              icon: const Icon(Icons.expand_more),
              label: const Text('Загрузить ещё'),
            ),
          ),
        ),
    ];
  }

  int _resolveCrossAxisCount(double width) {
    if (width >= 980) {
      return 6;
    }
    if (width >= 760) {
      return 5;
    }
    if (width >= 560) {
      return 4;
    }
    return 3;
  }

  Widget _buildColorChip(
    BuildContext context, {
    required String label,
    required Color color,
    required Color? selectedPreviewColor,
  }) {
    return ChoiceChip(
      label: Text(label),
      avatar: _PreviewColorDot(color: color),
      selected: selectedPreviewColor?.value == color.value,
      onSelected: (_) {
        widget.previewColor.value = color;
      },
    );
  }

  bool _isCustomPreviewColor(BuildContext context, Color? color) {
    if (color == null) {
      return false;
    }

    final theme = Theme.of(context);
    final presetValues = <int>{
      theme.colorScheme.onSurface.value,
      theme.colorScheme.primary.value,
      theme.colorScheme.secondary.value,
      theme.colorScheme.error.value,
    };
    return !presetValues.contains(color.value);
  }

  Future<void> _pickPreviewColor(
    BuildContext context, {
    required Color initialColor,
  }) async {
    Color draftColor = initialColor;

    final selectedColor = await showDialog<Color?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Цвет предпросмотра'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: draftColor,
              enableAlpha: false,
              portraitOnly: true,
              labelTypes: const [],
              onColorChanged: (color) {
                draftColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Сбросить'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(draftColor),
              child: const Text('Применить'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    widget.previewColor.value = selectedColor;
  }
}

class _PreviewColorDot extends StatelessWidget {
  const _PreviewColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }
}
