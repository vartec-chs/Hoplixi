import 'package:flutter/material.dart';

class OptionTile extends StatelessWidget {
  const OptionTile({
    required this.label,
    required this.characterSet,
    required this.value,
    required this.onChanged,
    required this.onEditCharacters,
    super.key,
  });

  final String label;
  final String characterSet;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEditCharacters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(!value),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.only(left: 14, right: 8),
              dense: true,
              title: Text(label, style: theme.textTheme.bodyMedium),
              subtitle: Text(
                characterSet,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Редактировать набор символов',
                    onPressed: onEditCharacters,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  Switch.adaptive(value: value, onChanged: onChanged),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
