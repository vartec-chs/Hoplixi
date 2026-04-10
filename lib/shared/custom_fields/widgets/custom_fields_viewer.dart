import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/db_core/models/enums/entity_types.dart';
import 'package:hoplixi/shared/custom_fields/models/custom_field_entry.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Виджет просмотра кастомных полей (read-only).
/// Переиспользуется в любом экране просмотра сущности.
class CustomFieldsViewer extends StatefulWidget {
  const CustomFieldsViewer({super.key, required this.fields});

  final List<CustomFieldEntry> fields;

  @override
  State<CustomFieldsViewer> createState() => _CustomFieldsViewerState();
}

class _CustomFieldsViewerState extends State<CustomFieldsViewer> {
  /// Хранит индексы полей с `concealed`, у которых значение раскрыто.
  final Set<int> _revealed = {};

  @override
  Widget build(BuildContext context) {
    if (widget.fields.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.slidersHorizontal,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text('Кастомные поля', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.fields.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FieldCard(
              entry: e.value,
              isRevealed: _revealed.contains(e.key),
              onToggleReveal: () => setState(() {
                if (_revealed.contains(e.key)) {
                  _revealed.remove(e.key);
                } else {
                  _revealed.add(e.key);
                }
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.entry,
    required this.isRevealed,
    required this.onToggleReveal,
  });

  final CustomFieldEntry entry;
  final bool isRevealed;
  final VoidCallback onToggleReveal;

  bool get _isConcealed => entry.fieldType == CustomFieldType.concealed;
  String get _displayValue {
    final v = entry.value ?? '';
    if (_isConcealed && !isRevealed && v.isNotEmpty) {
      return '•' * v.length.clamp(8, 20);
    }
    return v.isEmpty ? '—' : v;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = entry.value?.isNotEmpty ?? false;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          _iconFor(entry.fieldType),
          color: theme.colorScheme.primary,
        ),
        title: Text(entry.label, style: theme.textTheme.bodySmall),
        subtitle: Text(
          _displayValue,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: hasValue ? null : theme.colorScheme.onSurfaceVariant,
            fontFamily: _isConcealed && !isRevealed && hasValue
                ? 'monospace'
                : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isConcealed)
              IconButton(
                icon: Icon(
                  isRevealed ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                ),
                tooltip: isRevealed ? 'Скрыть' : 'Показать',
                onPressed: onToggleReveal,
              ),
            if (hasValue)
              IconButton(
                icon: const Icon(LucideIcons.copy, size: 18),
                tooltip: 'Копировать',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: entry.value!));
                  Toaster.success(
                    title: 'Скопировано',
                    description: '${entry.label} скопирован',
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(CustomFieldType type) => switch (type) {
    CustomFieldType.text => LucideIcons.textCursor,
    CustomFieldType.concealed => LucideIcons.lock,
    CustomFieldType.url => LucideIcons.globe,
    CustomFieldType.email => LucideIcons.mail,
    CustomFieldType.phone => LucideIcons.phone,
    CustomFieldType.date => LucideIcons.calendar,
    CustomFieldType.number => LucideIcons.hash,
  };
}
