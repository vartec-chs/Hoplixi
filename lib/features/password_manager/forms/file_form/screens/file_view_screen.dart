import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/modals/file_decrypt_modal.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Экран просмотра файла (только чтение)
class FileViewScreen extends ConsumerStatefulWidget {
  const FileViewScreen({super.key, required this.fileId});

  final String fileId;

  @override
  ConsumerState<FileViewScreen> createState() => _FileViewScreenState();
}

class _FileViewScreenState extends ConsumerState<FileViewScreen> {
  FilesData? _file;
  FileMetadataData? _metadata;
  bool _isLoading = true;
  String? _categoryName;
  List<String> _tagNames = [];

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final dao = await ref.read(fileDaoProvider.future);
      final file = await dao.getFileById(widget.fileId);
      if (file != null && mounted) {
        setState(() {
          _file = file;
          _isLoading = false;
        });
        await _loadMetadata(file, dao);
        await _loadRelatedData(file);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMetadata(FilesData file, dynamic dao) async {
    if (file.metadataId != null) {
      final meta = await dao.getFileMetadataById(file.metadataId!);
      if (mounted && meta != null) setState(() => _metadata = meta);
    }
  }

  Future<void> _loadRelatedData(FilesData file) async {
    if (file.categoryId != null) {
      final catDao = await ref.read(categoryDaoProvider.future);
      final cat = await catDao.getCategoryById(file.categoryId!);
      if (mounted && cat != null) setState(() => _categoryName = cat.name);
    }

    final dao = await ref.read(fileDaoProvider.future);
    final tagIds = await dao.getFileTagIds(widget.fileId);
    if (tagIds.isNotEmpty) {
      final tagDao = await ref.read(tagDaoProvider.future);
      final tags = await tagDao.getTagsByIds(tagIds);
      if (mounted) setState(() => _tagNames = tags.map((t) => t.name).toList());
    }
  }

  void _copy(String v, String f) {
    Clipboard.setData(ClipboardData(text: v));
    Toaster.success(title: 'Скопировано', description: '$f скопирован');
  }

  void _edit() => context.go(
    AppRoutesPaths.dashboardEntityEdit(EntityType.file, widget.fileId),
  );

  FileCardDto _createFileDto() {
    return FileCardDto(
      id: _file!.id,
      name: _file!.name,
      metadataId: _file!.metadataId,
      fileName: _metadata?.fileName,
      fileExtension: _metadata?.fileExtension,
      fileSize: _metadata?.fileSize,
      isFavorite: _file!.isFavorite,
      isPinned: _file!.isPinned,
      isArchived: _file!.isArchived,
      isDeleted: _file!.isDeleted,
      usedCount: _file!.usedCount,
      modifiedAt: _file!.modifiedAt,
      category: null,
      tags: null,
    );
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0 Б';
    const sizes = ['Б', 'КБ', 'МБ', 'ГБ'];
    final i = (bytes.bitLength - 1) ~/ 10;
    final size = bytes / (1 << (i * 10));
    return '${size.toStringAsFixed(1)} ${sizes[i]}';
  }

  IconData _getFileIcon(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':
      case 'doc':
      case 'docx':
        return LucideIcons.fileText;
      case 'xls':
      case 'xlsx':
        return LucideIcons.sheet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return LucideIcons.image;
      case 'mp3':
      case 'wav':
        return LucideIcons.music;
      case 'mp4':
      case 'avi':
        return LucideIcons.video;
      case 'zip':
      case 'rar':
        return LucideIcons.archive;
      default:
        return LucideIcons.file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final ext = _metadata?.fileExtension;

    return Scaffold(
      appBar: AppBar(
        title: Text(_file?.name ?? 'Файл'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.lockOpen),
            onPressed: _file == null
                ? null
                : () => showFileDecryptModal(context, _createFileDto()),
          ),
          IconButton(icon: const Icon(LucideIcons.pencil), onPressed: _edit),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _file == null
          ? const Center(child: Text('Не найден'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_getFileIcon(ext), size: 64, color: cs.primary),
                      const SizedBox(height: 12),
                      Text(
                        ext != null ? '.$ext' : 'file',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _info(
                  theme,
                  LucideIcons.tag,
                  'Название',
                  _file!.name,
                  () => _copy(_file!.name, 'Название'),
                ),
                if (_metadata?.fileName != null)
                  _info(
                    theme,
                    LucideIcons.file,
                    'Имя файла',
                    _metadata!.fileName,
                  ),
                if (_metadata != null)
                  _info(
                    theme,
                    LucideIcons.hardDrive,
                    'Размер',
                    _formatSize(_metadata!.fileSize),
                  ),
                if (ext != null)
                  _info(theme, LucideIcons.fileType, 'Расширение', '.$ext'),
                if (_categoryName != null)
                  _info(theme, LucideIcons.folder, 'Категория', _categoryName!),
                if (_tagNames.isNotEmpty) _tags(theme),
                if (_file!.description?.isNotEmpty ?? false)
                  _info(
                    theme,
                    LucideIcons.fileText,
                    'Описание',
                    _file!.description!,
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _edit,
                  icon: const Icon(LucideIcons.pencil),
                  label: const Text('Редактировать'),
                ),
              ],
            ),
    );
  }

  Widget _info(ThemeData t, IconData i, String l, String v, [VoidCallback? c]) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(i, color: t.colorScheme.primary),
        title: Text(l, style: t.textTheme.bodySmall),
        subtitle: Text(v, style: t.textTheme.bodyLarge),
        trailing: c != null
            ? IconButton(icon: const Icon(LucideIcons.copy), onPressed: c)
            : null,
      ),
    );
  }

  Widget _tags(ThemeData t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.tags, color: t.colorScheme.primary),
                const SizedBox(width: 16),
                Text('Теги', style: t.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _tagNames.map((e) => Chip(label: Text(e))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
