import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
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
  (VaultItemsData, NoteItemsData)? _note;
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
      final dao = await ref.read(noteDaoProvider.future);
      final record = await dao.getById(widget.noteId);

      if (record != null && mounted) {
        setState(() {
          _note = record;
          _isLoading = false;
        });
        _initQuillController(record.$2);
        await _loadRelatedData(record);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initQuillController(NoteItemsData note) {
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

  Future<void> _loadRelatedData((VaultItemsData, NoteItemsData) record) async {
    final (vault, _) = record;
    if (vault.categoryId != null) {
      final catDao = await ref.read(categoryDaoProvider.future);
      final cat = await catDao.getCategoryById(vault.categoryId!);
      if (mounted && cat != null) setState(() => _categoryName = cat.name);
    }

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    final tagIds = await vaultItemDao.getTagIds(widget.noteId);
    if (tagIds.isNotEmpty) {
      final tagDao = await ref.read(tagDaoProvider.future);
      final tags = await tagDao.getTagsByIds(tagIds);
      if (mounted) setState(() => _tagNames = tags.map((t) => t.name).toList());
    }
  }

  Future<void> _copyContent() async {
    if (_quillController != null) {
      final text = _quillController!.document.toPlainText();
      Clipboard.setData(ClipboardData(text: text));
      Toaster.success(title: 'Скопировано', description: 'Текст скопирован');
      final dao = await ref.read(vaultItemDaoProvider.future);
      await dao.incrementUsage(widget.noteId);
    }
  }

  void _edit() => context.go(
    AppRoutesPaths.dashboardEntityEdit(EntityType.note, widget.noteId),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_note?.$1.name ?? 'Заметка'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.copy),
            tooltip: 'Копировать текст',
            onPressed: _copyContent,
          ),
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            tooltip: 'Редактировать',
            onPressed: _edit,
          ),
        ],
      ),
      body: _isLoading
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
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton.icon(
                    onPressed: _edit,
                    icon: const Icon(LucideIcons.pencil),
                    label: const Text('Редактировать'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
