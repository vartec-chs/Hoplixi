import 'package:flutter/material.dart';
import 'package:hoplixi/core/logger/models.dart';
import 'package:intl/intl.dart' show DateFormat;



/// Виджет для отображения одной записи лога
class LogEntryTile extends StatefulWidget {
  final LogEntry entry;

  const LogEntryTile({super.key, required this.entry});

  @override
  State<LogEntryTile> createState() => _LogEntryTileState();
}

class _LogEntryTileState extends State<LogEntryTile> {
  bool _expanded = false;

  Color _getLogLevelColor(BuildContext context) {
    switch (widget.entry.level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Theme.of(context).colorScheme.error;
      case LogLevel.trace:
        return Colors.cyan;
      case LogLevel.fatal:
        return Colors.purple;
    }
  }

  String _getLogLevelEmoji() {
    switch (widget.entry.level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.trace:
        return '🔍';
      case LogLevel.fatal:
        return '🛑';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('HH:mm:ss.SSS').format(widget.entry.timestamp);
    final hasError =
        widget.entry.error != null || widget.entry.stackTrace != null;
    final hasData =
        widget.entry.additionalData != null &&
        widget.entry.additionalData!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: _expanded ? theme.colorScheme.surfaceContainerHighest : null,
      elevation: _expanded ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _expanded = !_expanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная информация
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLogLevelEmoji(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getLogLevelColor(context),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.entry.level.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (widget.entry.tag != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.entry.tag!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              timeStr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (hasError || hasData) const SizedBox(width: 8),
                            if (hasError)
                              Tooltip(
                                message: 'Содержит информацию об ошибке',
                                child: Icon(
                                  Icons.warning_amber,
                                  size: 16,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            if (hasData) const SizedBox(width: 4),
                            if (hasData)
                              Tooltip(
                                message: 'Содержит дополнительные данные',
                                child: Icon(
                                  Icons.data_object,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.entry.message,
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasError || hasData || _expanded)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              // Развернутая информация
              if (_expanded) ...[
                const SizedBox(height: 12),
                Divider(color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 8),
                // Ошибка
                if (widget.entry.error != null) ...[
                  Text(
                    'Ошибка:',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: theme.colorScheme.errorContainer,
                      ),
                    ),
                    child: SelectableText(
                      widget.entry.error.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Stack Trace
                if (widget.entry.stackTrace != null) ...[
                  Text(
                    'Stack Trace:',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: theme.colorScheme.tertiaryContainer,
                      ),
                    ),
                    child: SelectableText(
                      widget.entry.stackTrace.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Additional Data
                if (hasData) ...[
                  Text(
                    'Дополнительные данные:',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: theme.colorScheme.primaryContainer,
                      ),
                    ),
                    child: SelectableText(
                      widget.entry.additionalData.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
