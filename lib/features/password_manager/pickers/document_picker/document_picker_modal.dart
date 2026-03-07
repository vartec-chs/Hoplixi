import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/document_picker/models/document_picker_models.dart';
import 'package:hoplixi/features/password_manager/pickers/document_picker/providers/document_picker_providers.dart';
import 'package:hoplixi/features/password_manager/pickers/document_picker/widgets/document_list_tile.dart';
import 'package:hoplixi/main_store/models/dto/document_dto.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Показать модальное окно одиночного выбора документа.
///
/// Возвращает [DocumentPickerResult] или `null`.
Future<DocumentPickerResult?> showDocumentPickerModal(
  BuildContext context,
  WidgetRef ref, {
  String? excludeDocumentId,
}) async {
  ref.read(documentPickerFilterProvider.notifier).reset();
  ref.invalidate(documentPickerDataProvider);
  await ref
      .read(documentPickerDataProvider.notifier)
      .loadInitial(excludeDocumentId);

  if (!context.mounted) return null;

  return await WoltModalSheet.show<DocumentPickerResult>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (context) => [_buildPage(context, ref)],
  );
}

WoltModalSheetPage _buildPage(BuildContext context, WidgetRef ref) {
  return WoltModalSheetPage(
    hasSabGradient: false,
    topBarTitle: Text(
      'Выбрать документ',
      style: Theme.of(context).textTheme.titleLarge,
    ),
    isTopBarLayerAlwaysVisible: true,
    trailingNavBarWidget: IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => Navigator.of(context).pop(),
    ),
    child: const _DocumentPickerContent(),
  );
}

class _DocumentPickerContent extends ConsumerStatefulWidget {
  const _DocumentPickerContent();

  @override
  ConsumerState<_DocumentPickerContent> createState() =>
      _DocumentPickerContentState();
}

class _DocumentPickerContentState
    extends ConsumerState<_DocumentPickerContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

  void _onDocumentSelected(DocumentCardDto document) {
    Navigator.of(context).pop(
      DocumentPickerResult(
        id: document.id,
        name: document.title ?? document.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(documentPickerDataProvider);

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
                      return DocumentListTile(
                        document: doc,
                        onTap: () => _onDocumentSelected(doc),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
