import 'package:hoplixi/shared/ui/background_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/decrypt_modal/file_decrypt_modal.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';
import 'package:hoplixi/features/password_manager/shared/utils/copy_usage_utils.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_view_section.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';
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
  FileViewDto? _file;
  bool _isDeleted = false;
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
      final repositories = await ref.read(vaultRepositories.future);
      final viewResult = await repositories.file.getViewById(widget.fileId);
      final view = viewResult.getOrNull()?.getOrNull();

      if (view != null && mounted) {
        setState(() {
          _file = view;
          _isDeleted = view.item.isDeleted;
        });
        await _loadRelatedData(view, repositories);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedData(
    FileViewDto view,
    VaultRepositories repositories,
  ) async {
    if (view.item.categoryId != null) {
      final cat = (await repositories.category.getCategory(
        view.item.categoryId!,
      )).getOrNull()?.getOrNull();
      if (mounted && cat != null) setState(() => _categoryName = cat.name);
    }

    final relationsService = await ref.read(
      vaultItemRelationsServiceProvider.future,
    );
    final tagIds =
        (await relationsService.getTagIdsForItem(widget.fileId)).getOrNull() ??
        [];
    if (tagIds.isNotEmpty) {
      final tags =
          (await repositories.tag.getTagsByIds(tagIds)).getOrNull() ?? [];
      if (mounted) setState(() => _tagNames = tags.map((t) => t.name).toList());
    }
  }

  Future<void> _copy(String v, String f) async {
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.fileId,
      text: v,
    );
    if (!copied) return;
    Toaster.success(title: 'Скопировано', description: '$f скопирован');
  }

  void _edit() => context.go(
    AppRoutesPaths.dashboardEntityEdit(EntityType.file, widget.fileId),
  );

  FileCardDto _createFileDto() {
    final item = _file!.item;
    final file = _file!.file;
    final metadata = _file!.metadata;
    return FileCardDto(
      item: VaultItemCardDto(
        itemId: item.itemId,
        type: item.type,
        name: item.name,
        description: item.description,
        categoryId: item.categoryId,
        iconRefId: item.iconRefId,
        isFavorite: item.isFavorite,
        isArchived: item.isArchived,
        isPinned: item.isPinned,
        isDeleted: item.isDeleted,
        createdAt: item.createdAt,
        modifiedAt: item.modifiedAt,
        lastUsedAt: item.lastUsedAt,
        archivedAt: item.archivedAt,
        deletedAt: item.deletedAt,
        recentScore: item.recentScore,
      ),
      data: FileCardDataDto(
        metadataId: file.metadataId,
        fileName: metadata?.fileName,
        fileExtension: metadata?.fileExtension,
        mimeType: metadata?.mimeType,
        fileSize: metadata?.fileSize,
        availabilityStatus: metadata?.availabilityStatus,
        integrityStatus: metadata?.integrityStatus,
        missingDetectedAt: metadata?.missingDetectedAt,
        deletedAt: metadata?.deletedAt,
        lastIntegrityCheckAt: metadata?.lastIntegrityCheckAt,
        hasMetadata: metadata != null,
        hasSha256: metadata?.sha256 != null,
      ),
    );
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0 Б';
    const sizes = ['Б', 'КБ', 'МБ', 'ГБ'];
    final i = (bytes.bitLength - 1) ~/ 10;
    final size = bytes / (1 << (i * 10));
    return '${size.toStringAsFixed(1)} ${sizes[i]}';
  }

  Future<void> _share() async {
    final record = _file;
    if (record == null) return;

    final l10n = context.t.dashboard_forms;
    final customFields = await loadCustomShareableFields(ref, widget.fileId);
    if (!mounted) return;
    final metadata = record.metadata;
    final fields = [
      ...buildCommonShareFields(
        context,
        name: record.item.name,
        categoryName: _categoryName,
        tagNames: _tagNames,
        description: record.item.description,
      ),
      ...compactShareableFields([
        shareableField(
          id: 'file_name',
          label: l10n.share_file_name_label,
          value: metadata?.fileName,
        ),
        shareableField(
          id: 'file_size',
          label: l10n.share_file_size_label,
          value: metadata == null ? null : _formatSize(metadata.fileSize),
        ),
        shareableField(
          id: 'extension',
          label: l10n.share_file_extension_label,
          value: metadata?.fileExtension,
        ),
      ]),
      ...customFields,
    ];

    await shareEntityFields(
      context: context,
      entity: ShareableEntity(
        title: record.item.name,
        entityTypeLabel: EntityType.file.label,
        fields: fields,
      ),
    );
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

    final ext = _file?.metadata?.fileExtension;

    return Scaffold(
      backgroundColor: getScreenBackgroundColor(context, ref),
      appBar: AppBar(
        title: Text(_file?.item.name ?? 'Файл'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.lockOpen),
            onPressed: _file == null
                ? null
                : () => showFileDecryptModal(context, _createFileDto()),
          ),
          IconButton(
            icon: const Icon(LucideIcons.share2),
            tooltip: context.t.dashboard_forms.share_action,
            onPressed: _isLoading || _isDeleted || _file == null
                ? null
                : _share,
          ),
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            onPressed: _isDeleted ? null : _edit,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
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
                    _file!.item.name,
                    () => _copy(_file!.item.name, 'Название'),
                  ),
                  if (_file?.metadata?.fileName != null)
                    _info(
                      theme,
                      LucideIcons.file,
                      'Имя файла',
                      _file!.metadata!.fileName,
                    ),
                  if (_file?.metadata != null)
                    _info(
                      theme,
                      LucideIcons.hardDrive,
                      'Размер',
                      _formatSize(_file!.metadata!.fileSize),
                    ),
                  if (ext != null)
                    _info(theme, LucideIcons.fileType, 'Расширение', '.$ext'),
                  if (_categoryName != null)
                    _info(
                      theme,
                      LucideIcons.folder,
                      'Категория',
                      _categoryName!,
                    ),
                  if (_tagNames.isNotEmpty) _tags(theme),
                  if (_file!.item.description?.isNotEmpty ?? false)
                    _info(
                      theme,
                      LucideIcons.fileText,
                      'Описание',
                      _file!.item.description!,
                    ),
                  CustomFieldsViewSection(itemId: widget.fileId),
                  const SizedBox(height: 24),
                ],
              ),
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
