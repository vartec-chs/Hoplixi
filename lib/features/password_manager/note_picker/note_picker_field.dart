import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/note_picker/note_picker_modal.dart';

/// Виджет для выбора заметки
class NotePickerField extends ConsumerWidget {
  const NotePickerField({
    super.key,
    required this.noteName,
    required this.onNoteSelected,
    required this.onNoteClear,
  });

  final String? noteName;
  final ValueChanged<String> onNoteSelected;
  final VoidCallback onNoteClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Заметка',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await showNotePickerModal(context, ref);
            if (result != null) {
              onNoteSelected(result.id);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    noteName ?? 'Выберите заметку',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: noteName == null
                          ? theme.colorScheme.onSurfaceVariant.withOpacity(0.5)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (noteName != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: onNoteClear,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
