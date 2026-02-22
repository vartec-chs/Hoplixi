import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class RecoveryCodesListCard extends StatelessWidget {
  const RecoveryCodesListCard({
    super.key,
    required this.recoveryCodes,
    this.onToggleFavorite,
    this.onOpenHistory,
  });

  final RecoveryCodesCardDto recoveryCodes;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final codesCount = recoveryCodes.codesCount ?? 0;
    final usedCount = recoveryCodes.codesUsedCount ?? 0;
    final subtitle = [
      'Использовано: $usedCount/$codesCount',
      if (recoveryCodes.oneTime == true) 'one-time',
    ].join(' • ');

    return Card(
      child: ListTile(
        title: Text(recoveryCodes.name),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: onToggleFavorite,
              icon: Icon(
                recoveryCodes.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
            ),
            IconButton(
              onPressed: onOpenHistory,
              icon: const Icon(Icons.history),
            ),
          ],
        ),
      ),
    );
  }
}
