import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/decrypt_modal/document_decrypt_modal.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/document_dto.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Экран просмотра документа (только чтение)
class DocumentViewScreen extends ConsumerStatefulWidget {
  const DocumentViewScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentViewScreen> createState() => _DocumentViewScreenState();
}

class _DocumentViewScreenState extends ConsumerState<DocumentViewScreen> {
  (VaultItemsData, DocumentItemsData)? _document;
  bool _isLoading = true;
  String? _categoryName;
  List<String> _tagNames = [];

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final dao = await ref.read(documentDaoProvider.future);
      final record = await dao.getById(widget.documentId);
      if (record != null && mounted) {
        setState(() {
          _document = record;
          _isLoading = false;
        });
        await _loadRelatedData(record);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedData(
    (VaultItemsData, DocumentItemsData) record,
  ) async {
    final vault = record.$1;
    if (vault.categoryId != null) {
      final catDao = await ref.read(categoryDaoProvider.future);
      final cat = await catDao.getCategoryById(vault.categoryId!);
      if (mounted && cat != null) setState(() => _categoryName = cat.name);
    }

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    final tagIds = await vaultItemDao.getTagIds(widget.documentId);
    if (tagIds.isNotEmpty) {
      final tagDao = await ref.read(tagDaoProvider.future);
      final tags = await tagDao.getTagsByIds(tagIds);
      if (mounted) setState(() => _tagNames = tags.map((t) => t.name).toList());
    }
  }

  Future<void> _copy(String v, String f) async {
    Clipboard.setData(ClipboardData(text: v));
    Toaster.success(title: 'Скопировано', description: '$f скопирован');
    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.documentId);
  }

  void _edit() => context.go(
    AppRoutesPaths.dashboardEntityEdit(EntityType.document, widget.documentId),
  );

  DocumentCardDto _createDocumentDto() {
    return DocumentCardDto(
      id: _document!.$1.id,
      title: _document!.$1.name,
      documentType: _document!.$2.documentType,
      description: _document!.$1.description,
      pageCount: _document!.$2.pageCount,
      isFavorite: _document!.$1.isFavorite,
      isPinned: _document!.$1.isPinned,
      isArchived: _document!.$1.isArchived,
      isDeleted: _document!.$1.isDeleted,
      usedCount: _document!.$1.usedCount,
      modifiedAt: _document!.$1.modifiedAt,
      category: null,
      tags: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final title = _document?.$1.name ?? 'Документ';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.lockOpen),
            onPressed: _document == null
                ? null
                : () => showDocumentDecryptModal(context, _createDocumentDto()),
          ),
          IconButton(icon: const Icon(LucideIcons.pencil), onPressed: _edit),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _document == null
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
                      Icon(LucideIcons.fileText, size: 64, color: cs.primary),
                      const SizedBox(height: 12),
                      Text(
                        '${_document!.$2.pageCount} стр.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_document!.$1.name.isNotEmpty)
                  _info(
                    theme,
                    LucideIcons.tag,
                    'Название',
                    _document!.$1.name,
                    () => _copy(_document!.$1.name, 'Название'),
                  ),
                if (_document!.$2.documentType != null)
                  _info(
                    theme,
                    LucideIcons.file,
                    'Тип',
                    _document!.$2.documentType!,
                  ),
                _info(
                  theme,
                  LucideIcons.layers,
                  'Страниц',
                  '${_document!.$2.pageCount}',
                ),
                if (_categoryName != null)
                  _info(theme, LucideIcons.folder, 'Категория', _categoryName!),
                if (_tagNames.isNotEmpty) _tags(theme),
                if (_document!.$1.description?.isNotEmpty ?? false)
                  _info(
                    theme,
                    LucideIcons.fileText,
                    'Описание',
                    _document!.$1.description!,
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
