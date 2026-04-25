import 'package:flutter/material.dart';
import 'package:hoplixi/main_db/core/models/dto/file_dto.dart';

/// Форматирует размер файла в байтах в читаемую строку
String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes Б';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
}

/// Элемент списка файлов в пикере
class FileListTile extends StatelessWidget {
  final FileCardDto file;
  final VoidCallback onTap;
  final Widget? trailing;

  const FileListTile({
    super.key,
    required this.file,
    required this.onTap,
    this.trailing,
  });

  /// Формирует subtitle из расширения и размера файла
  String? _buildSubtitle() {
    final parts = <String>[];
    if (file.fileExtension != null && file.fileExtension!.isNotEmpty) {
      parts.add(file.fileExtension!.toUpperCase());
    }
    if (file.fileSize != null) {
      parts.add(_formatFileSize(file.fileSize!));
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subtitle = _buildSubtitle();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(Icons.attach_file, color: colorScheme.onPrimaryContainer),
      ),
      title: Text(
        file.name,
        style: textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing:
          trailing ??
          (file.isFavorite
              ? Icon(Icons.star, color: colorScheme.primary, size: 20)
              : null),
      onTap: onTap,
    );
  }
}
