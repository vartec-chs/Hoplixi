import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/token_oauth.dart';
import 'package:hoplixi/shared/ui/slider_button.dart';

/// Карточка для отображения OAuth токена
class TokenCard extends StatefulWidget {
  final TokenOAuth token;
  final VoidCallback onDelete;

  const TokenCard({required this.token, required this.onDelete, super.key});

  @override
  State<TokenCard> createState() => _TokenCardState();
}

class _TokenCardState extends State<TokenCard> {
  bool _isExpanded = false;
  bool _showAccessToken = false;
  bool _showRefreshToken = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок карточки
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
              bottom: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Иконка провайдера
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getProviderIcon(widget.token.provider),
                      color: colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Информация
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.token.userName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.token.provider.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (widget.token.timeToRefresh)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.refresh,
                                      size: 12,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Требует обновления',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            if (widget.token.timeToLogin)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.login,
                                      size: 12,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Требует входа',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Иконка раскрытия
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Развернутое содержимое
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID
                  _buildInfoRow(
                    context,
                    icon: Icons.tag,
                    label: 'ID',
                    value: widget.token.id,
                    canCopy: true,
                  ),
                  const SizedBox(height: 12),

                  // Issuer
                  _buildInfoRow(
                    context,
                    icon: Icons.dns,
                    label: 'Issuer',
                    value: widget.token.iss,
                    canCopy: true,
                  ),
                  const SizedBox(height: 12),

                  // Access Token
                  _buildTokenRow(
                    context,
                    icon: Icons.vpn_key,
                    label: 'Access Token',
                    value: widget.token.accessToken,
                    isVisible: _showAccessToken,
                    onToggle: () {
                      setState(() {
                        _showAccessToken = !_showAccessToken;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Refresh Token
                  _buildTokenRow(
                    context,
                    icon: Icons.key,
                    label: 'Refresh Token',
                    value: widget.token.refreshToken,
                    isVisible: _showRefreshToken,
                    onToggle: () {
                      setState(() {
                        _showRefreshToken = !_showRefreshToken;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Статусы
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusChip(
                          context,
                          icon: widget.token.canRefresh
                              ? Icons.check_circle
                              : Icons.cancel,
                          label: 'Можно обновить',
                          isActive: widget.token.canRefresh,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Кнопка удаления
                  SizedBox(
                    width: double.infinity,
                    child: SliderButton(
                      type: SliderButtonType.delete,

                      variant: SliderButtonVariant.warning,
                      text: 'Удалить токен',
                      onSlideCompleteAsync: () async {
                        widget.onDelete();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool canCopy = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (canCopy) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              Toaster.success(
                title: 'Скопировано',
                description: 'Значение скопировано в буфер обмена',
              );
            },
            tooltip: 'Копировать',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }

  Widget _buildTokenRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isVisible ? value : '•' * 20,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
                maxLines: isVisible ? 3 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            size: 16,
          ),
          onPressed: onToggle,
          tooltip: isVisible ? 'Скрыть' : 'Показать',
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            Toaster.success(
              title: 'Скопировано',
              description: 'Токен скопирован в буфер обмена',
            );
          },
          tooltip: 'Копировать',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer.withOpacity(0.5)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isActive
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
      case 'googledrive':
        return Icons.cloud;
      case 'dropbox':
        return Icons.cloud_download;
      case 'onedrive':
        return Icons.cloud_circle;
      case 'yandex':
        return Icons.cloud_queue;
      default:
        return Icons.vpn_key;
    }
  }
}
