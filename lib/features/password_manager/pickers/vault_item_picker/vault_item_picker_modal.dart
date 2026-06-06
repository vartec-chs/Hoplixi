import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/shared/ui/type_chip.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class LinkedVaultItemCardDto {
  const LinkedVaultItemCardDto({
    required this.id,
    required this.name,
    required this.vaultItemType,
    this.description,
  });

  final String id;
  final String name;
  final VaultItemType vaultItemType;
  final String? description;

  String get title => name;
}

Future<LinkedVaultItemCardDto?> showVaultItemPickerModal(
  BuildContext context,
  WidgetRef ref, {
  String? excludeItemId,
}) async {
  if (!context.mounted) return null;

  return WoltModalSheet.show<LinkedVaultItemCardDto>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (context) => [
      WoltModalSheetPage(
        hasSabGradient: false,
        isTopBarLayerAlwaysVisible: true,
        topBarTitle: Text(
          'Выбрать объект',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        trailingNavBarWidget: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        child: _VaultItemPickerContent(excludeItemId: excludeItemId),
      ),
    ],
  );
}

class _VaultItemPickerContent extends ConsumerStatefulWidget {
  const _VaultItemPickerContent({this.excludeItemId});

  final String? excludeItemId;

  @override
  ConsumerState<_VaultItemPickerContent> createState() =>
      _VaultItemPickerContentState();
}

class _VaultItemPickerContentState
    extends ConsumerState<_VaultItemPickerContent> {
  static const int _pageSize = 20;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 300);

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _searchDebounceTimer;
  List<LinkedVaultItemCardDto> _items = const [];
  List<VaultItemType> _selectedTypes = const [];
  List<String> _selectedCategoryIds = const [];
  List<String> _selectedCategoryNames = const [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Object? _error;
  int _requestSerial = 0;

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedTypes.isNotEmpty ||
      _selectedCategoryIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadItems());
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: _buildFilters(context),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.48,
              minHeight: 220,
            ),
            child: _buildItemsList(context),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Поиск',
            hintText: 'Введите название или описание объекта',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.trim().isEmpty
                ? null
                : IconButton(
                    tooltip: 'Очистить поиск',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _reloadItems();
                    },
                  ),
          ),
          onChanged: _handleSearchChanged,
        ),
        const SizedBox(height: 12),
        CategoryPickerField(
          isFilter: true,
          selectedCategoryIds: _selectedCategoryIds,
          selectedCategoryNames: _selectedCategoryNames,
          label: 'Категории',
          hintText: 'Все категории',
          onCategoriesSelected: (categoryIds, categoryNames) {
            setState(() {
              _selectedCategoryIds = categoryIds;
              _selectedCategoryNames = categoryNames;
            });
            _reloadItems();
          },
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              TypeChip(
                label: 'Все типы',
                isSelected: _selectedTypes.isEmpty,
                onTap: () {
                  setState(() => _selectedTypes = const []);
                  _reloadItems();
                },
              ),
              const SizedBox(width: 8),
              for (final type in VaultItemType.values) ...[
                TypeChip(
                  label: type.toEntityType().label,
                  isSelected: _selectedTypes.contains(type),
                  onTap: () => _toggleType(type),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        if (_hasActiveFilters) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: SmoothButton.text(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: 'Сбросить фильтры',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItemsList(BuildContext context) {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Не удалось загрузить объекты',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error.toString(),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              SmoothButton.text(
                onPressed: _reloadItems,
                icon: const Icon(Icons.refresh),
                label: 'Повторить',
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _hasActiveFilters
                ? 'Объекты по выбранным фильтрам не найдены'
                : 'Объекты не найдены',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final itemCount = _items.length + (_isLoadingMore ? 1 : 0);
    return ListView.separated(
      controller: _scrollController,
      itemCount: itemCount,
      separatorBuilder: (_, index) => index >= _items.length - 1
          ? const SizedBox.shrink()
          : const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = _items[index];
        final entityType = item.vaultItemType.toEntityType();

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              entityType.icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            item.description?.isNotEmpty == true
                ? '${entityType.label} · ${item.description}'
                : entityType.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => Navigator.of(context).pop(item),
        );
      },
    );
  }

  void _handleSearchChanged(String _) {
    setState(() {});
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDuration, _reloadItems);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || !_hasMore || _isLoadingMore) return;
    if (_scrollController.position.extentAfter < 240) {
      _loadNextPage();
    }
  }

  void _toggleType(VaultItemType type) {
    final updatedTypes = List<VaultItemType>.from(_selectedTypes);
    if (updatedTypes.contains(type)) {
      updatedTypes.remove(type);
    } else {
      updatedTypes.add(type);
    }

    setState(() => _selectedTypes = updatedTypes);
    _reloadItems();
  }

  void _clearFilters() {
    _searchDebounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _selectedTypes = const [];
      _selectedCategoryIds = const [];
      _selectedCategoryNames = const [];
    });
    _reloadItems();
  }

  Future<void> _reloadItems() async {
    final requestId = ++_requestSerial;
    setState(() {
      _items = const [];
      _hasMore = true;
      _isInitialLoading = true;
      _isLoadingMore = false;
      _error = null;
    });
    await _loadPage(reset: true, requestId: requestId);
  }

  Future<void> _loadNextPage() async {
    if (!_hasMore || _isInitialLoading || _isLoadingMore) return;

    final requestId = _requestSerial;
    setState(() {
      _isLoadingMore = true;
      _error = null;
    });
    await _loadPage(reset: false, requestId: requestId);
  }

  Future<void> _loadPage({required bool reset, required int requestId}) async {
    try {
      final offset = reset ? 0 : _items.length;
      final repos = await ref.read(vaultRepositories.future);
      final result = await repos.vaultItem.searchLinkableItems(
        query: _searchController.text,
        excludeItemId: widget.excludeItemId,
        types: _selectedTypes,
        categoryIds: _selectedCategoryIds,
        limit: _pageSize,
        offset: offset,
      );

      if (!mounted || requestId != _requestSerial) return;

      result.fold(
        (items) {
          final mappedItems = items
              .map(
                (item) => LinkedVaultItemCardDto(
                  id: item.itemId,
                  name: item.name,
                  vaultItemType: item.type,
                  description: item.description,
                ),
              )
              .toList();

          setState(() {
            _items = reset ? mappedItems : [..._items, ...mappedItems];
            _hasMore = mappedItems.length == _pageSize;
            _isInitialLoading = false;
            _isLoadingMore = false;
            _error = null;
          });
        },
        (error) {
          setState(() {
            _isInitialLoading = false;
            _isLoadingMore = false;
            _error = error;
          });
        },
      );
    } catch (error) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
        _error = error;
      });
    }
  }
}
