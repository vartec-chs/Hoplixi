import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class BatchPasswordsSection extends StatelessWidget {
  const BatchPasswordsSection({
    required this.selectedCount,
    required this.countOptions,
    required this.passwords,
    required this.copiedIndex,
    required this.onCountChanged,
    required this.onGeneratePressed,
    required this.onCopyPressed,
    super.key,
  });

  final int selectedCount;
  final List<int> countOptions;
  final List<String> passwords;
  final int? copiedIndex;
  final ValueChanged<int> onCountChanged;
  final VoidCallback onGeneratePressed;
  final ValueChanged<int> onCopyPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Пакетная генерация',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: selectedCount,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Количество паролей',
                ),
                items: countOptions
                    .map(
                      (count) => DropdownMenuItem<int>(
                        value: count,
                        child: Text(count.toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    onCountChanged(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            SmoothButton(
              onPressed: onGeneratePressed,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: 'Сгенерировать',
              type: SmoothButtonType.outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (passwords.isEmpty)
          Text(
            'Нажмите "Сгенерировать", чтобы получить список паролей.',
            style: theme.textTheme.bodyMedium,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: passwords.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final password = passwords[index];
              final copied = copiedIndex == index;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        password,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: copied ? 'Скопировано!' : 'Копировать',
                      onPressed: () => onCopyPressed(index),
                      icon: Icon(copied ? Icons.check : Icons.copy_outlined),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
