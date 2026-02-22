import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class CryptoWalletGridCard extends StatelessWidget {
  const CryptoWalletGridCard({
    super.key,
    required this.wallet,
    this.onToggleFavorite,
  });

  final CryptoWalletCardDto wallet;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
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
                    wallet.name,
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
                    wallet.isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              wallet.walletType,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              wallet.network ?? 'network: not set',
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
