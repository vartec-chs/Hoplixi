import 'package:flutter/material.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/models/oauth_apps.dart';

/// Карточка OAuth приложения
class OAuthAppCard extends StatelessWidget {
  final OauthApps app;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isBuiltin;

  const OAuthAppCard({
    required this.app,
    this.onTap,
    this.onDelete,
    this.isBuiltin = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // side: BorderSide(color: theme.dividerColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Иконка типа приложения
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(context).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(),
                  color: _getTypeColor(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Информация о приложении
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            app.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (app.isBuiltin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withAlpha(60),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Встроенное',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.type.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.key,
                          size: 14,
                          color: colorScheme.onSurface.withAlpha(153),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${app.clientId.substring(0, 4)}...${app.clientId.substring(app.clientId.length - 4)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withAlpha(153),
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Кнопка удаления (только для пользовательских)
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  color: colorScheme.error,
                  tooltip: 'Удалить',
                ),
              ] else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (app.type) {
      case OauthAppsType.google:
        return Icons.g_mobiledata;
      case OauthAppsType.onedrive:
        return Icons.cloud_outlined;
      case OauthAppsType.dropbox:
        return Icons.cloud_queue;
      case OauthAppsType.yandex:
        return Icons.language;
      case OauthAppsType.other:
        return Icons.extension;
    }
  }

  Color _getTypeColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (app.type) {
      case OauthAppsType.google:
        return Colors.red;
      case OauthAppsType.onedrive:
        return Colors.blue;
      case OauthAppsType.dropbox:
        return Colors.lightBlue;
      case OauthAppsType.yandex:
        return Colors.orange;
      case OauthAppsType.other:
        return colorScheme.primary;
    }
  }
}
