import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/services/db_history_services/model/db_history_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RecentDatabaseHeader extends StatelessWidget {
  const RecentDatabaseHeader({
    super.key,
    required this.entry,
    required this.onDelete,
  });

  final DatabaseEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.storage_rounded, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Недавнее хранилище',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(LucideIcons.trash),
          tooltip: 'Удалить из истории',
          onPressed: onDelete,
          color: colorScheme.error,
          iconSize: 20,
        ),
      ],
    );
  }
}
