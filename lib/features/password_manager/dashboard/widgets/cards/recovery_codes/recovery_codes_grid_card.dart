import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class RecoveryCodesGridCard extends StatelessWidget {
  const RecoveryCodesGridCard({
    super.key,
    required this.recoveryCodes,
    this.onToggleFavorite,
  });

  final RecoveryCodesCardDto recoveryCodes;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final codesCount = recoveryCodes.codesCount ?? 0;
    final usedCount = recoveryCodes.codesUsedCount ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recoveryCodes.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onToggleFavorite,
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    recoveryCodes.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$usedCount / $codesCount',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              recoveryCodes.oneTime == true ? 'one-time' : 'multi-use',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
