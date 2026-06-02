import 'package:hoplixi/shared/ui/background_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/decrypt_modal/document_decrypt_modal.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';
import 'package:hoplixi/features/password_manager/shared/utils/copy_usage_utils.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_view_section.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';
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
  DocumentViewDto? _document;
  DocumentVersionViewDto? _currentVersion;
  bool _isDeleted = false;
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
      final repositories = await ref.read(vaultRepositories.future);
      final viewResult = await repositories.document.getViewById(
        widget.documentId,
      );
      final view = viewResult.getOrNull()?.getOrNull();
      if (view != null && mounted) {
        setState(() {
          _document = view;
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
    DocumentViewDto view,
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
        (await relationsService.getTagIdsForItem(
          widget.documentId,
        )).getOrNull() ??
        [];
    if (tagIds.isNotEmpty) {
      final tags =
          (await repositories.tag.getTagsByIds(tagIds)).getOrNull() ?? [];
      if (mounted) setState(() => _tagNames = tags.map((t) => t.name).toList());
    }

    final verService = await ref.read(documentVersionServiceProvider.future);
    final verRes = await verService.getCurrentVersion(
      documentId: widget.documentId,
    );
    if (mounted) {
      setState(() {
        _currentVersion = verRes.getOrNull();
      });
    }
  }

  Future<void> _copy(String v, String f) async {
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.documentId,
      text: v,
    );
    if (!copied) return;
    Toaster.success(title: 'Скопировано', description: '$f скопирован');
  }

  void _edit() => context.go(
    AppRoutesPaths.dashboardEntityEdit(EntityType.document, widget.documentId),
  );

  DocumentCardDto _createDocumentDto() {
    final item = _document!.item;
    final curVer = _currentVersion;
    return DocumentCardDto(
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
      data: DocumentCurrentVersionCardDataDto(
        currentVersionId: curVer?.id,
        currentVersionNumber: curVer?.versionNumber,
        documentType: curVer?.documentType,
        documentTypeOther: curVer?.documentTypeOther,
        pageCount: curVer?.pageCount,
        versionCreatedAt: curVer?.createdAt,
        versionModifiedAt: curVer?.modifiedAt,
        hasCurrentVersion: curVer != null,
      ),
    );
  }

  Future<void> _share() async {
    final record = _document;
    if (record == null) return;

    final l10n = context.t.dashboard_forms;
    final customFields = await loadCustomShareableFields(
      ref,
      widget.documentId,
    );
    if (!mounted) return;

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
          id: 'document_type',
          label: l10n.share_document_type_label,
          value: _currentVersion?.documentType?.name,
        ),
        shareableField(
          id: 'page_count',
          label: l10n.share_page_count_label,
          value: _currentVersion?.pageCount.toString(),
        ),
      ]),
      ...customFields,
    ];

    await shareEntityFields(
      context: context,
      entity: ShareableEntity(
        title: record.item.name,
        entityTypeLabel: EntityType.document.label,
        fields: fields,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final title = _document?.item.name ?? 'Документ';

    return Scaffold(
      backgroundColor: getScreenBackgroundColor(context, ref),
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.lockOpen),
            onPressed: _document == null
                ? null
                : () => showDocumentDecryptModal(context, _createDocumentDto()),
          ),
          IconButton(
            icon: const Icon(LucideIcons.share2),
            tooltip: context.t.dashboard_forms.share_action,
            onPressed: _isLoading || _isDeleted || _document == null
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
                          '${_currentVersion?.pageCount ?? 0} стр.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_document!.item.name.isNotEmpty)
                    _info(
                      theme,
                      LucideIcons.tag,
                      'Название',
                      _document!.item.name,
                      () => _copy(_document!.item.name, 'Название'),
                    ),
                  if (_currentVersion?.documentType != null)
                    _info(
                      theme,
                      LucideIcons.file,
                      'Тип',
                      _currentVersion!.documentType!.name,
                    ),
                  _info(
                    theme,
                    LucideIcons.layers,
                    'Страниц',
                    '${_currentVersion?.pageCount ?? 0}',
                  ),
                  if (_categoryName != null)
                    _info(
                      theme,
                      LucideIcons.folder,
                      'Категория',
                      _categoryName!,
                    ),
                  if (_tagNames.isNotEmpty) _tags(theme),
                  if (_document!.item.description?.isNotEmpty ?? false)
                    _info(
                      theme,
                      LucideIcons.fileText,
                      'Описание',
                      _document!.item.description!,
                    ),
                  CustomFieldsViewSection(itemId: widget.documentId),
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
