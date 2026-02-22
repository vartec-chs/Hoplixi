import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class LicenseKeyListCard extends StatelessWidget {
  const LicenseKeyListCard({
    super.key,
    required this.license,
    this.onToggleFavorite,
    this.onOpenHistory,
  });

  final LicenseKeyCardDto license;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      license.product,
      if (license.licenseType?.isNotEmpty == true) license.licenseType!,
      if (license.orderId?.isNotEmpty == true) license.orderId!,
    ].join(' • ');

    return Card(
      child: ListTile(
        title: Text(license.name),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: onToggleFavorite,
              icon: Icon(
                license.isFavorite ? Icons.favorite : Icons.favorite_border,
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
