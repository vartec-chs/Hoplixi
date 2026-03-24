import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

class AuthProviderListTile extends StatelessWidget {
  const AuthProviderListTile({
    super.key,
    required this.provider,
    required this.onTap,
  });

  final CloudSyncProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metadata = provider.metadata;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subtitleText = metadata.scopes.isEmpty
        ? provider.id
        : '${metadata.scopes.length} scopes';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.7)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    metadata.icon,
                    color: colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              metadata.displayName,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _StatusBadge(
                            label: metadata.supportsAuth ? 'OAuth' : 'Custom',
                            isAccent: metadata.supportsAuth,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitleText,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SupportChip(
                            label: metadata.supportsDesktopAuth
                                ? 'Desktop'
                                : 'No desktop',
                            isEnabled: metadata.supportsDesktopAuth,
                          ),
                          _SupportChip(
                            label: metadata.supportsMobileAuth
                                ? 'Mobile'
                                : 'No mobile',
                            isEnabled: metadata.supportsMobileAuth,
                          ),
                          if (metadata.scopes.isNotEmpty)
                            _SupportChip(
                              label: metadata.scopes.first,
                              isEnabled: true,
                              isCompact: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
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
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isEnabled
              ? colorScheme.primary.withOpacity(0.25)
              : colorScheme.outlineVariant.withOpacity(0.8),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isEnabled
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.isAccent});

  final String label;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAccent
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isAccent
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
