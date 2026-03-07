import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/document_picker/models/document_picker_models.dart';
import 'package:hoplixi/features/password_manager/pickers/document_picker/providers/document_picker_providers.dart';
import 'package:hoplixi/features/password_manager/pickers/document_picker/widgets/document_list_tile.dart';
import 'package:hoplixi/main_store/models/dto/document_dto.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Показать модальное окно множественного выбора документов.
///
/// [excludeDocumentId] — ID документа, который не отображается в списке.
/// [initialSelectedIds] — заранее выбранные ID документов.
///
/// Возвращает [DocumentPickerMultiResult] или `null`.
Future<DocumentPickerMultiResult?> showDocumentPickerMultiModal(
  BuildContext context,
  WidgetRef ref, {
  String? excludeDocumentId,
  List<String>? initialSelectedIds,
}) async {
  ref.read(documentPickerFilterProvider.notifier).reset();
  ref.invalidate(documentPickerDataProvider);
  await ref
      .read(documentPickerDataProvider.notifier)
      .loadInitial(excludeDocumentId);

  if (!context.mounted) return null;

  return await WoltModalSheet.show<DocumentPickerMultiResult>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (context) => [
      _buildPage(context, ref, initialSelectedIds: initialSelectedIds),
    ],
  );
}

WoltModalSheetPage _buildPage(
  BuildContext context,
  WidgetRef ref, {
  List<String>? initialSelectedIds,
}) {
  return WoltModalSheetPage(
    hasSabGradient: false,
    topBarTitle: Text(
      'Выбрать документы',
      style: Theme.of(context).textTheme.titleLarge,
    ),
    isTopBarLayerAlwaysVisible: true,
    trailingNavBarWidget: IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => Navigator.of(context).pop(),
    ),
    child: _DocumentPickerMultiContent(initialSelectedIds: initialSelectedIds),
  );
}

class _DocumentPickerMultiContent extends ConsumerStatefulWidget {
  final List<String>? initialSelectedIds;

  const _DocumentPickerMultiContent({this.initialSelectedIds});

  @override
  ConsumerState<_DocumentPickerMultiContent> createState() =>
      _DocumentPickerMultiContentState();
}

class _DocumentPickerMultiContentState
    extends ConsumerState<_DocumentPickerMultiContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _selectedIds = {};
  final Map<String, String> _selectedTitles = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialSelectedIds != null) {
      _selectedIds.addAll(widget.initialSelectedIds!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(documentPickerDataProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    ref.read(documentPickerFilterProvider.notifier).updateQuery(value);
    final currentData = ref.read(documentPickerDataProvider);
    ref
        .read(documentPickerDataProvider.notifier)
        .loadInitial(currentData.excludeDocumentId);
  }

  void _toggleSelection(DocumentCardDto document) {
    setState(() {
      if (_selectedIds.contains(document.id)) {
        _selectedIds.remove(document.id);
        _selectedTitles.remove(document.id);
      } else {
        _selectedIds.add(document.id);
        _selectedTitles[document.id] = document.title ?? document.id;
      }
    });
  }

  void _onConfirm() {
    final results = _selectedIds
        .map(
          (id) => DocumentPickerResult(id: id, name: _selectedTitles[id] ?? ''),
        )
        .toList();
    Navigator.of(context).pop(DocumentPickerMultiResult(documents: results));
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(documentPickerDataProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Поиск',
              hintText: 'Введите название документа',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        if (_selectedIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Выбрано: ${_selectedIds.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: data.documents.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Документы не найдены'),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount:
                        data.documents.length + (data.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == data.documents.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final doc = data.documents[index] as DocumentCardDto;
                      final isSelected = _selectedIds.contains(doc.id);
                      return DocumentListTile(
                        document: doc,
                        onTap: () => _toggleSelection(doc),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(doc),
                        ),
                      );
                    },
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: SmoothButton(
                  label: 'Отмена',
                  onPressed: () => Navigator.of(context).pop(),
                  type: SmoothButtonType.outlined,
                  variant: SmoothButtonVariant.normal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SmoothButton(
                  label: 'Выбрать (${_selectedIds.length})',
                  onPressed: _selectedIds.isEmpty ? null : _onConfirm,
                  type: SmoothButtonType.filled,
                  variant: SmoothButtonVariant.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
