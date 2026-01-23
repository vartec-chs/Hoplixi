import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/models/note_picker_models.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/providers/note_picker_providers.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/widgets/note_list_tile.dart';
import 'package:hoplixi/main_store/models/dto/note_dto.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Показать модальное окно выбора заметки
Future<NotePickerResult?> showNotePickerModal(
  BuildContext context,
  WidgetRef ref, {
  String? excludeNoteId,
}) async {
  // Сбрасываем состояние перед показом
  ref.read(notePickerFilterProvider.notifier).reset();
  ref.invalidate(notePickerDataProvider);

  // Загружаем начальные данные с исключением заметки
  await ref.read(notePickerDataProvider.notifier).loadInitial(excludeNoteId);

  if (!context.mounted) return null;

  return await WoltModalSheet.show<NotePickerResult>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (context) => [_buildNotePickerPage(context, ref)],
  );
}

/// Построить страницу модального окна
WoltModalSheetPage _buildNotePickerPage(BuildContext context, WidgetRef ref) {
  return WoltModalSheetPage(
    hasSabGradient: false,
    topBarTitle: Text(
      'Выбрать заметку',
      style: Theme.of(context).textTheme.titleLarge,
    ),
    isTopBarLayerAlwaysVisible: true,
    trailingNavBarWidget: IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => Navigator.of(context).pop(),
    ),
    child: const _NotePickerContent(),
  );
}

/// Контент модального окна
class _NotePickerContent extends ConsumerStatefulWidget {
  const _NotePickerContent();

  @override
  ConsumerState<_NotePickerContent> createState() => _NotePickerContentState();
}

class _NotePickerContentState extends ConsumerState<_NotePickerContent> {
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
      ref.read(notePickerDataProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    ref.read(notePickerFilterProvider.notifier).updateQuery(value);
    final currentData = ref.read(notePickerDataProvider);
    ref
        .read(notePickerDataProvider.notifier)
        .loadInitial(currentData.excludeNoteId);
  }

  void _onNoteSelected(NoteCardDto note) {
    Navigator.of(context).pop(NotePickerResult(id: note.id, name: note.title));
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(notePickerDataProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Поле поиска
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Поиск',
              hintText: 'Введите название заметки',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        const Divider(height: 1),

        // Список заметок
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: data.notes.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Заметки не найдены'),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: data.notes.length + (data.isLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == data.notes.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final note = data.notes[index] as NoteCardDto;
                      return NoteListTile(
                        note: note,
                        onTap: () => _onNoteSelected(note),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
