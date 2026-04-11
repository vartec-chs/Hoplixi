import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/import/otp/otp_extractor.dart';

class OtpImportListItem extends StatelessWidget {
  const OtpImportListItem({
    super.key,
    required this.otp,
    required this.isSelected,
    required this.isExpanded,
    required this.onToggleSelection,
    required this.onToggleExpanded,
    required this.currentCode,
    required this.remainingSeconds,
  });

  final OtpData otp;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onToggleSelection;
  final VoidCallback onToggleExpanded;
  final String currentCode;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onToggleSelection,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleSelection(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otp.issuer.isNotEmpty ? otp.issuer : 'Unknown Issuer',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          otp.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: onToggleExpanded,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const Divider(),
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  'Secret',
                  otp.secretBase32,
                  monospace: true,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildChip(context, otp.algorithm, Icons.lock_outline),
                    const SizedBox(width: 8),
                    _buildChip(context, '${otp.digits} digits', Icons.pin),
                    const SizedBox(width: 8),
                    _buildChip(context, otp.type, Icons.timer_outlined),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preview Code',
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentCode,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: remainingSeconds / 30,
                            strokeWidth: 4,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                          ),
                          Text(
                            '$remainingSeconds',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool monospace = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: monospace ? 'monospace' : null,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (context.mounted) {
                  Toaster.success(
                    title: 'Copied',
                    description: '$label copied to clipboard',
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
