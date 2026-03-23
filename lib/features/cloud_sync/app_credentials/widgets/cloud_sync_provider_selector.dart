import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

/// Выбор провайдера для app credentials.
class CloudSyncProviderSelector extends StatelessWidget {
  const CloudSyncProviderSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final CloudSyncProvider value;
  final ValueChanged<CloudSyncProvider> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final provider in CloudSyncProvider.values)
          ChoiceChip(
            avatar: Icon(provider.metadata.icon, size: 18),
            label: Text(provider.metadata.displayName),
            selected: provider == value,
            onSelected: (_) => onChanged(provider),
          ),
      ],
    );
  }
}
