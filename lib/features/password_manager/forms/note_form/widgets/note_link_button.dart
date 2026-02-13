import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_modal.dart';

/// Кастомная кнопка для вставки ссылки на заметку в Quill редактор
class NoteLinkButton extends ConsumerWidget {
  const NoteLinkButton({
    required this.controller,
    super.key,
    this.iconSize = 18,
    this.iconTheme,
  });

  final QuillController controller;
  final double iconSize;
  final QuillIconTheme? iconTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final iconColor =
        iconTheme?.iconButtonUnselectedData?.color ?? theme.iconTheme.color;
    // final fillColor =
    //     iconTheme?.iconButtonUnselectedData?.color ?? theme.canvasColor;

    return QuillToolbarIconButton(
      tooltip: 'Ссылка на заметку',
      icon: Icon(Icons.link, size: iconSize, color: iconColor),
      isSelected: false,
      iconTheme: iconTheme,
      onPressed: () => _handleInsertNoteLink(context, ref),
    );
  }

  Future<void> _handleInsertNoteLink(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Открываем модалку выбора заметки
    final result = await showNotePickerModal(context, ref);

    if (result == null) return;

    // Получаем текущую позицию курсора
    final selection = controller.selection;
    final index = selection.baseOffset;
    final length = selection.extentOffset - index;

    // Создаем текст ссылки
    final linkText = result.name;

    // Формируем URL ссылки (внутренний формат для заметок)
    final linkUrl = 'note://${result.id}';

    // Вставляем ссылку
    if (length > 0) {
      // Если есть выделенный текст - преобразуем его в ссылку
      controller.formatText(index, length, LinkAttribute(linkUrl));
    } else {
      // Если нет выделения - вставляем новый текст со ссылкой
      controller.document.insert(index, linkText);
      controller.formatText(index, linkText.length, LinkAttribute(linkUrl));

      // Перемещаем курсор в конец вставленного текста
      controller.updateSelection(
        TextSelection.collapsed(offset: index + linkText.length),
        ChangeSource.local,
      );
    }
  }
}
