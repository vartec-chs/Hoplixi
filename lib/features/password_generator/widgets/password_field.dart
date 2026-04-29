import 'package:flutter/material.dart';

class PasswordField extends StatelessWidget {
  const PasswordField({
    required this.password,
    required this.copied,
    required this.placeholder,
    required this.regenerateTooltip,
    required this.onCopy,
    this.onRegenerate,
    super.key,
  });

  final String password;
  final bool copied;
  final String placeholder;
  final String regenerateTooltip;
  final VoidCallback onCopy;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onRegenerate,
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: regenerateTooltip,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                password.isEmpty ? placeholder : password,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: password.isEmpty ? null : onCopy,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                copied ? Icons.check : Icons.copy,
                key: ValueKey(copied),
                size: 18,
              ),
            ),
            tooltip: copied ? 'Скопировано!' : 'Копировать',
          ),
        ],
      ),
    );
  }
}
