import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class CryptoWalletListCard extends StatelessWidget {
  const CryptoWalletListCard({
    super.key,
    required this.wallet,
    this.onToggleFavorite,
    this.onOpenHistory,
  });

  final CryptoWalletCardDto wallet;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      wallet.walletType,
      if (wallet.network?.isNotEmpty == true) wallet.network!,
      if (wallet.hardwareDevice?.isNotEmpty == true) wallet.hardwareDevice!,
      if (wallet.watchOnly) 'watch-only',
    ].join(' • ');

    return Card(
      child: ListTile(
        title: Text(wallet.name),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: onToggleFavorite,
              icon: Icon(
                wallet.isFavorite ? Icons.favorite : Icons.favorite_border,
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
