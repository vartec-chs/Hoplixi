import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_credential_option.dart';

class AuthCredentialListTile extends StatelessWidget {
  const AuthCredentialListTile({
    super.key,
    required this.option,
    required this.builtinLabel,
    required this.customLabel,
    this.unavailableReason,
    this.onTap,
  });

  final AuthCredentialOption option;
  final String builtinLabel;
  final String customLabel;
  final String? unavailableReason;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final entry = option.entry;
    final isEnabled = option.isSupported && onTap != null;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final reason = unavailableReason?.trim();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isEnabled ? 1 : 0.62,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surfaceContainerHighest.withOpacity(0.55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.7)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? colorScheme.secondaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      entry.isBuiltin
                          ? Icons.lock_outline
                          : Icons.tune_outlined,
                      color: isEnabled
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                entry.name,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _Badge(
                              label: entry.isBuiltin
                                  ? builtinLabel
                                  : customLabel,
                              accent: entry.isBuiltin,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.clientId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SupportChip(
                              label: option.isSupported
                                  ? 'Supported'
                                  : 'Unsupported',
                              isEnabled: option.isSupported,
                            ),
                            _SupportChip(
                              label: entry.isBuiltin ? 'Built-in' : 'Custom',
                              isEnabled: true,
                              isCompact: true,
                            ),
                          ],
                        ),
                        if (reason != null && reason.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer.withOpacity(
                                0.55,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colorScheme.error.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              reason,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.accent});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: accent
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SupportChip extends StatelessWidget {
  const _SupportChip({
    required this.label,
    required this.isEnabled,
    this.isCompact = false,
  });

  final String label;
  final bool isEnabled;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: isEnabled
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isEnabled
              ? colorScheme.secondary.withOpacity(0.25)
              : colorScheme.outlineVariant.withOpacity(0.8),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isEnabled
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
