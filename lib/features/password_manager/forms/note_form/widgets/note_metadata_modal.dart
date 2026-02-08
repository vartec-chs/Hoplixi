import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/modal_sheet_close_button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../providers/note_form_provider.dart';

/// Показать модальное окно для редактирования метаданных заметки
/// Вызывается при сохранении заметки для заполнения заголовка, категории и тегов
Future<bool?> showNoteMetadataModal(
  BuildContext context, {
  required bool isEditMode,
  required VoidCallback onSave,
}) {
  return WoltModalSheet.show<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    pageListBuilder: (modalContext) {
      return [
        WoltModalSheetPage(
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          topBarTitle: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Text(
                isEditMode ? 'Сохранить заметку' : 'Создать заметку',
                style: theme.textTheme.titleMedium,
              );
            },
          ),
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: ModalSheetCloseButton(),
          ),
          child: Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.all(12),
              child: _NoteMetadataForm(
                isEditMode: isEditMode,
                onSave: () {
                  Navigator.of(modalContext).pop(true);
                  onSave();
                },
                onCancel: () => Navigator.of(modalContext).pop(false),
              ),
            ),
          ),
        ),
      ];
    },
  );
}

/// Форма редактирования метаданных заметки
class _NoteMetadataForm extends ConsumerStatefulWidget {
  final bool isEditMode;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _NoteMetadataForm({
    required this.isEditMode,
    required this.onSave,
    required this.onCancel,
  });

  @override
  ConsumerState<_NoteMetadataForm> createState() => _NoteMetadataFormState();
}

class _NoteMetadataFormState extends ConsumerState<_NoteMetadataForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(noteFormProvider);
    _titleController = TextEditingController(text: state.title);
    _descriptionController = TextEditingController(text: state.description);

    // В режиме создания, если заголовок пустой, берем первую строку из контента
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isEditMode &&
          state.title.isEmpty &&
          state.content.isNotEmpty) {
        final firstLine = state.content.split('\n').first.trim();
        if (firstLine.isNotEmpty) {
          _titleController.text = firstLine;
          // Обновляем провайдер
          ref.read(noteFormProvider.notifier).setTitle(firstLine);
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Обновляем состояние формы
    final notifier = ref.read(noteFormProvider.notifier);
    notifier.setTitle(_titleController.text);
    notifier.setDescription(_descriptionController.text);

    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noteFormProvider);
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Заголовок *
          TextFormField(
            controller: _titleController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Заголовок *',
              hintText: 'Введите заголовок заметки',
              errorText: state.titleError,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Заголовок обязателен';
              }
              if (value.trim().length > 255) {
                return 'Заголовок не должен превышать 255 символов';
              }
              return null;
            },
            onChanged: (value) {
              ref.read(noteFormProvider.notifier).setTitle(value);
            },
          ),
          const SizedBox(height: 16),

          // Описание
          TextFormField(
            controller: _descriptionController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Описание',
              hintText: 'Краткое описание заметки',
            ),
            maxLines: 2,
            onChanged: (value) {
              ref.read(noteFormProvider.notifier).setDescription(value);
            },
          ),
          const SizedBox(height: 16),

          // Категория
          CategoryPickerField(
            selectedCategoryId: state.categoryId,
            selectedCategoryName: state.categoryName,
            label: 'Категория',
            hintText: 'Выберите категорию',
            filterByType: [CategoryType.note, CategoryType.mixed],
            onCategorySelected: (categoryId, categoryName) {
              ref
                  .read(noteFormProvider.notifier)
                  .setCategory(categoryId, categoryName);
            },
          ),
          const SizedBox(height: 16),

          // Теги
          TagPickerField(
            selectedTagIds: state.tagIds,
            selectedTagNames: state.tagNames,
            label: 'Теги',
            hintText: 'Выберите теги',
            filterByType: [TagType.note, TagType.mixed],
            onTagsSelected: (tagIds, tagNames) {
              ref.read(noteFormProvider.notifier).setTags(tagIds, tagNames);
            },
          ),
          const SizedBox(height: 8),

          // Подсказка
          Text(
            'Заголовок и содержание обязательны для сохранения',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),

          // Кнопки действий
          Row(
            children: [
              Expanded(
                child: SmoothButton(
                  label: 'Отмена',
                  onPressed: _isLoading ? null : widget.onCancel,
                  type: SmoothButtonType.outlined,
                  variant: SmoothButtonVariant.normal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SmoothButton(
                  label: widget.isEditMode ? 'Сохранить' : 'Создать',
                  onPressed: _isLoading ? null : _handleSave,
                  type: SmoothButtonType.filled,
                  variant: SmoothButtonVariant.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
