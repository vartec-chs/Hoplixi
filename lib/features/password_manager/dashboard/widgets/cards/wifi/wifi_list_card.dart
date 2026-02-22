import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class WifiListCard extends StatelessWidget {
  const WifiListCard({
    super.key,
    required this.wifi,
    this.onToggleFavorite,
    this.onOpenHistory,
  });

  final WifiCardDto wifi;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      wifi.ssid,
      if (wifi.security?.isNotEmpty == true) wifi.security!,
      if (wifi.hidden) 'hidden',
      if (wifi.priority != null) 'priority: ${wifi.priority}',
    ].join(' • ');

    return Card(
      child: ListTile(
        title: Text(wifi.name),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: onToggleFavorite,
              icon: Icon(
                wifi.isFavorite ? Icons.favorite : Icons.favorite_border,
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
