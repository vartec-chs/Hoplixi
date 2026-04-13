import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/logger/models.dart';
import 'package:hoplixi/core/utils/toastification.dart';
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

  Future<void> _copyEntryToClipboard() async {
    final entry = widget.entry;
    final buffer = StringBuffer()
      ..writeln('Time: ${entry.timestamp.toIso8601String()}')
      ..writeln('Level: ${entry.level.name.toUpperCase()}')
      ..writeln('Tag: ${entry.tag ?? '-'}')
      ..writeln('Message: ${entry.message}');

    if (entry.error != null) {
      buffer.writeln('Error: ${entry.error}');
    }

    if (entry.stackTrace != null) {
      buffer.writeln('StackTrace: ${entry.stackTrace}');
    }

    if (entry.additionalData != null && entry.additionalData!.isNotEmpty) {
      final prettyData = const JsonEncoder.withIndent(
        '  ',
      ).convert(entry.additionalData);
      buffer.writeln('AdditionalData: $prettyData');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    if (!mounted) return;

    HapticFeedback.mediumImpact();
    Toaster.success(
      title: 'Скопировано',
      description: 'Запись лога скопирована в буфер обмена',
    );
  }

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

  IconData _getLogLevelIcon() {
    switch (widget.entry.level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber_rounded;
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.trace:
        return Icons.search;
      case LogLevel.fatal:
        return Icons.report_gmailerrorred;
    }
  }

  String _formatAdditionalData() {
    final data = widget.entry.additionalData;
    if (data == null || data.isEmpty) return '';
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final levelColor = _getLogLevelColor(context);
    final timeStr = DateFormat('HH:mm:ss.SSS').format(widget.entry.timestamp);
    final hasError =
        widget.entry.error != null || widget.entry.stackTrace != null;
    final hasData =
        widget.entry.additionalData != null &&
        widget.entry.additionalData!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: _expanded
          ? colorScheme.surfaceContainerHighest
          : colorScheme.surface,
      elevation: _expanded ? 1 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _expanded
              ? levelColor.withOpacity(0.35)
              : colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _expanded = !_expanded;
          });
        },
        onLongPress: _copyEntryToClipboard,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная строка
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: levelColor.withOpacity(0.4)),
                    ),
                    child: Icon(
                      _getLogLevelIcon(),
                      size: 18,
                      color: levelColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: levelColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                widget.entry.level.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            if (widget.entry.tag != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  widget.entry.tag!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            if (hasError)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Ошибка',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            if (hasData)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Данные',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            Text(
                              timeStr,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.entry.message,
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'Копировать запись',
                        visualDensity: VisualDensity.compact,
                        onPressed: _copyEntryToClipboard,
                        icon: Icon(
                          Icons.content_copy_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 180),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const SizedBox(height: 12),
                    if (widget.entry.stackTrace != null || hasData) ...[
                      Divider(color: colorScheme.outlineVariant),
                    ],
                    const SizedBox(height: 8),
                    if (widget.entry.error != null) ...[
                      _SectionTitle(title: 'Ошибка', color: colorScheme.error),
                      const SizedBox(height: 4),
                      _DetailBlock(
                        color: colorScheme.errorContainer.withOpacity(0.5),
                        borderColor: colorScheme.errorContainer,
                        child: SelectableText(
                          widget.entry.error.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.entry.stackTrace != null) ...[
                      _SectionTitle(
                        title: 'Stack Trace',
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(height: 4),
                      _DetailBlock(
                        color: colorScheme.tertiaryContainer.withOpacity(0.3),
                        borderColor: colorScheme.tertiaryContainer,
                        child: SelectableText(
                          widget.entry.stackTrace.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onTertiaryContainer,
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (hasData) ...[
                      _SectionTitle(
                        title: 'Дополнительные данные',
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 4),
                      _DetailBlock(
                        color: colorScheme.primaryContainer.withOpacity(0.3),
                        borderColor: colorScheme.primaryContainer,
                        child: SelectableText(
                          _formatAdditionalData(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Удерживайте карточку для быстрого копирования записи',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$title:',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;

  const _DetailBlock({
    required this.child,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
