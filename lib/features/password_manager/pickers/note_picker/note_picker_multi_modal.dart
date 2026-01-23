import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/models/note_picker_models.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/providers/note_picker_providers.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/widgets/note_list_tile.dart';
import 'package:hoplixi/main_store/models/dto/note_dto.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Показать модальное окно выбора нескольких заметок
Future<NotePickerMultiResult?> showNotePickerMultiModal(
  BuildContext context,
  WidgetRef ref, {
  String? excludeNoteId,
  List<String>? initialSelectedIds,
}) async {
  // Сбрасываем состояние перед показом
  ref.read(notePickerFilterProvider.notifier).reset();
  ref.invalidate(notePickerDataProvider);

  // Загружаем начальные данные с исключением заметки
  await ref.read(notePickerDataProvider.notifier).loadInitial(excludeNoteId);

  if (!context.mounted) return null;

  return await WoltModalSheet.show<NotePickerMultiResult>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (context) => [
      _buildNotePickerMultiPage(
        context,
        ref,
        initialSelectedIds: initialSelectedIds,
      ),
    ],
  );
}

/// Построить страницу модального окна
WoltModalSheetPage _buildNotePickerMultiPage(
  BuildContext context,
  WidgetRef ref, {
  List<String>? initialSelectedIds,
}) {
  return WoltModalSheetPage(
    hasSabGradient: false,
    topBarTitle: Text(
      'Выбрать заметки',
      style: Theme.of(context).textTheme.titleLarge,
    ),
    isTopBarLayerAlwaysVisible: true,
    trailingNavBarWidget: IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => Navigator.of(context).pop(),
    ),
    child: _NotePickerMultiContent(initialSelectedIds: initialSelectedIds),
  );
}

/// Контент модального окна для множественного выбора
class _NotePickerMultiContent extends ConsumerStatefulWidget {
  final List<String>? initialSelectedIds;

  const _NotePickerMultiContent({this.initialSelectedIds});

  @override
  ConsumerState<_NotePickerMultiContent> createState() =>
      _NotePickerMultiContentState();
}

class _NotePickerMultiContentState
    extends ConsumerState<_NotePickerMultiContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _selectedNoteIds = {};
  final Map<String, String> _selectedNoteTitles = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialSelectedIds != null) {
      _selectedNoteIds.addAll(widget.initialSelectedIds!);
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

  void _toggleNoteSelection(NoteCardDto note) {
    setState(() {
      if (_selectedNoteIds.contains(note.id)) {
        _selectedNoteIds.remove(note.id);
        _selectedNoteTitles.remove(note.id);
      } else {
        _selectedNoteIds.add(note.id);
        _selectedNoteTitles[note.id] = note.title;
      }
    });
  }

  void _onConfirm() {
    final results = _selectedNoteIds
        .map(
          (id) => NotePickerResult(id: id, name: _selectedNoteTitles[id] ?? ''),
        )
        .toList();

    Navigator.of(context).pop(NotePickerMultiResult(notes: results));
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

        // Индикатор выбранных заметок
        if (_selectedNoteIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Выбрано: ${_selectedNoteIds.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
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
                      final isSelected = _selectedNoteIds.contains(note.id);

                      return NoteListTile(
                        note: note,
                        onTap: () => _toggleNoteSelection(note),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleNoteSelection(note),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // Кнопки действий
        Padding(
          padding: const EdgeInsets.all(12.0),
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
                  label: 'Выбрать (${_selectedNoteIds.length})',
                  onPressed: _selectedNoteIds.isEmpty ? null : _onConfirm,
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
