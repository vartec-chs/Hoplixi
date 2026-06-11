import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/item_links_graph/widgets/item_link_type_label.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/item_link/item_links.dart';

class ItemLinksGraphLegend extends StatelessWidget {
  const ItemLinksGraphLegend({super.key, required this.relationTypes});

  final Set<ItemLinkType> relationTypes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          Icon(Icons.arrow_forward, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text('source -> target', style: theme.textTheme.bodySmall),
          const SizedBox(width: 16),
          for (final type in relationTypes) ...[
            Icon(Icons.link, size: 14, color: theme.colorScheme.secondary),
            const SizedBox(width: 4),
            Text(itemLinkTypeLabel(type), style: theme.textTheme.bodySmall),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}
