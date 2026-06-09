import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/services/db_history_services/model/db_history_model.dart';

class RecentDatabaseInfo extends StatelessWidget {
  const RecentDatabaseInfo({super.key, required this.entry});

  final DatabaseEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (entry.description != null && entry.description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            entry.description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          entry.path,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
