import 'package:hoplixi/shared/ui/background_utils.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';
import 'package:hoplixi/features/password_manager/shared/utils/copy_usage_utils.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_view_section.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/vault_db/core/models/dto/note_dto.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Экран просмотра заметки (только чтение)
class NoteViewScreen extends ConsumerStatefulWidget {
  const NoteViewScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends ConsumerState<NoteViewScreen> {
  NoteViewDto? _note;
  bool _isDeleted = false;
  bool _isLoading = true;
  String? _categoryName;
  List<String> _tagNames = [];
  QuillController? _quillController;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  @override
  void dispose() {
    _quillController?.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    try {
      final repositories = await ref.read(vaultRepositories.future);
      final viewResult = await repositories.note.getViewById(widget.noteId);
      final view = viewResult.getOrNull()?.getOrNull();

      if (view != null && mounted) {
        setState(() {
          _note = view;
          _isDeleted = view.item.isDeleted;
          _isLoading = false;
        });
        _initQuillController(view.note);
        await _loadRelatedData(view, repositories);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initQuillController(NoteDataDto note) {
    if (note.deltaJson.isNotEmpty) {
      try {
        final deltaJson = jsonDecode(note.deltaJson) as List<dynamic>;
        _quillController = QuillController(
          document: Document.fromJson(deltaJson),
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        );
      } catch (_) {
        _quillController = QuillController.basic();
        _quillController!.readOnly = true;
      }
    } else {
      _quillController = QuillController.basic();
      _quillController!.readOnly = true;
    }
    setState(() {});
  }

  Future<void> _loadRelatedData(
    NoteViewDto view,
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
        (await relationsService.getTagIdsForItem(widget.noteId)).getOrNull() ??
        [];
    if (tagIds.isNotEmpty) {
      final tags =
          (await repositories.tag.getTagsByIds(tagIds)).getOrNull() ?? [];
      if (mounted) setState(() => _tagNames = tags.map((t) => t.name).toList());
    }
  }

  Future<void> _copyContent() async {
    if (_quillController != null) {
      final text = _quillController!.document.toPlainText();
      final copied = await copyCardValue(
        ref: ref,
        itemId: widget.noteId,
        text: text,
      );
      if (!copied) return;
      Toaster.success(title: 'Скопировано', description: 'Текст скопирован');
    }
  }

  void _edit() => context.go(
    AppRoutesPaths.dashboardEntityEdit(EntityType.note, widget.noteId),
  );

  Future<void> _share() async {
    final record = _note;
    if (record == null) return;

    final l10n = context.t.dashboard_forms;
    final commonFields = buildCommonShareFields(
      context,
      name: record.item.name,
      categoryName: _categoryName,
      tagNames: _tagNames,
      description: record.item.description,
    );
    final customFields = await loadCustomShareableFields(ref, widget.noteId);
    if (!mounted) return;
    final fields = [
      ...commonFields,
      ...compactShareableFields([
        shareableField(
          id: 'content',
          label: l10n.share_content_label,
          value: _quillController?.document.toPlainText(),
        ),
      ]),
      ...customFields,
    ];

    await shareEntityFields(
      context: context,
      entity: ShareableEntity(
        title: record.item.name,
        entityTypeLabel: EntityType.note.label,
        fields: fields,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: getScreenBackgroundColor(context, ref),
      appBar: AppBar(
        title: Text(_note?.item.name ?? 'Заметка'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            tooltip: context.t.dashboard_forms.share_action,
            onPressed: _isLoading || _isDeleted || _note == null
                ? null
                : _share,
          ),
          IconButton(
            icon: const Icon(LucideIcons.copy),
            tooltip: 'Копировать текст',
            onPressed: _copyContent,
          ),
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            tooltip: 'Редактировать',
            onPressed: _isDeleted ? null : _edit,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _note == null
            ? const Center(child: Text('Не найдена'))
            : Column(
                children: [
                  if (_categoryName != null || _tagNames.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        border: Border(
                          bottom: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_categoryName != null)
                            Chip(
                              avatar: Icon(
                                LucideIcons.folder,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              label: Text(_categoryName!),
                            ),
                          ..._tagNames.map((tag) => Chip(label: Text(tag))),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _quillController != null
                        ? QuillEditor(
                            controller: _quillController!,
                            scrollController: ScrollController(),
                            focusNode: FocusNode(),
                            config: QuillEditorConfig(
                              padding: const EdgeInsets.all(12),
                              expands: true,
                              customStyles: DefaultStyles(
                                link: TextStyle(
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  CustomFieldsViewSection(itemId: widget.noteId),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: FilledButton.icon(
                      onPressed: _isDeleted ? null : _edit,
                      icon: const Icon(LucideIcons.pencil),
                      label: Text(context.t.dashboard_forms.edit),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
